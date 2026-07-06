const Payment = require('../models/Payment');
const Booking = require('../models/Booking');
const Worker = require('../models/Worker');
const Commission = require('../models/Commission');
const Razorpay = require('razorpay');
const crypto = require('crypto');
const { emitToUser } = require('../config/socket');

// Initialize Razorpay
let razorpay = null;
try {
  if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_ID !== 'rzp_test_mockkeyid12345') {
    razorpay = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID,
      key_secret: process.env.RAZORPAY_KEY_SECRET
    });
  }
} catch (e) {
  console.warn('Failed to initialize Razorpay. Running in mock payment mode.');
}

// Helper to record successful payment & calculate commission
const processSuccessfulPayment = async (booking, amount, paymentMethod, paymentDetails = {}) => {
  // Update booking status
  booking.paymentStatus = 'paid';
  booking.status = 'paid';
  await booking.save();

  // Create payment log
  await Payment.create({
    booking: booking._id,
    user: booking.user,
    worker: booking.worker,
    amount: amount,
    paymentMethod: paymentMethod,
    status: 'completed',
    razorpayOrderId: paymentDetails.razorpayOrderId || '',
    razorpayPaymentId: paymentDetails.razorpayPaymentId || ''
  });

  // Calculate 10% commission
  const commissionAmount = amount * 0.10;

  // Update Worker's earnings & commission
  const worker = await Worker.findById(booking.worker);
  if (worker) {
    worker.monthlyEarnings = (worker.monthlyEarnings || 0) + amount;
    worker.commissionDue = (worker.commissionDue || 0) + commissionAmount;
    worker.isBusy = false; // Worker is now free for new bookings
    
    // Automatically temporarily block worker if commission due exceeds ₹2000
    if (worker.commissionDue >= 2000) {
      worker.isBlocked = true;
    }
    
    await worker.save();

    // Create Commission log
    await Commission.create({
      worker: worker._id,
      amount: commissionAmount,
      monthlyEarnings: worker.monthlyEarnings,
      status: 'unpaid'
    });
  }

  // Notify user and worker about status change via socket
  const updatePayload = { bookingId: booking._id, status: 'paid' };
  emitToUser(booking.user, 'bookingStatusUpdate', updatePayload);
  if (booking.worker) {
    emitToUser(booking.worker, 'bookingStatusUpdate', updatePayload);
  }
};

// @desc    Initiate payment (Cash or Online Razorpay)
// @route   POST /api/v1/payments/pay
// @access  Private (User)
exports.initiatePayment = async (req, res, next) => {
  try {
    const { bookingId, paymentMethod } = req.body;

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found', data: null });
    }

    if (booking.user.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized to pay for this booking', data: null });
    }

    if (booking.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Payment can only be made on completed bookings',
        data: null
      });
    }

    const amount = booking.quotePrice;

    if (paymentMethod === 'Cash') {
      // Process Cash payment immediately
      booking.paymentMethod = 'Cash';
      await processSuccessfulPayment(booking, amount, 'Cash');

      return res.status(200).json({
        success: true,
        message: 'Payment processed successfully via Cash',
        booking,
        data: {
          booking
        }
      });
    } else if (paymentMethod === 'Online') {
      // Process Online payment via Razorpay
      booking.paymentMethod = 'Online';
      await booking.save();

      const amountInPaise = Math.round(amount * 100);

      let order = null;
      if (razorpay) {
        try {
          order = await razorpay.orders.create({
            amount: amountInPaise,
            currency: 'INR',
            receipt: booking._id.toString()
          });
        } catch (err) {
          console.warn('Razorpay order creation failed, falling back to mock order:', err.message);
        }
      }

      // Generate mock order if Razorpay is not configured or fails
      if (!order) {
        order = {
          id: 'order_mock_' + crypto.randomBytes(8).toString('hex'),
          amount: amountInPaise,
          currency: 'INR',
          receipt: booking._id.toString(),
          status: 'created'
        };
      }

      // Create a pending payment log
      await Payment.create({
        booking: booking._id,
        user: booking.user,
        worker: booking.worker,
        amount: amount,
        paymentMethod: 'Online',
        status: 'pending',
        razorpayOrderId: order.id
      });

      return res.status(200).json({
        success: true,
        message: 'Online payment order created',
        order,
        booking,
        data: {
          order,
          booking
        }
      });
    } else {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment method. Use Cash or Online',
        data: null
      });
    }
  } catch (err) {
    next(err);
  }
};

// @desc    Verify Razorpay online payment signature
// @route   POST /api/v1/payments/verify
// @access  Private (User)
exports.verifyPayment = async (req, res, next) => {
  try {
    const { bookingId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found', data: null });
    }

    // Mock validation fallback
    let signatureValid = false;
    if (razorpayOrderId.startsWith('order_mock_') || razorpaySignature === 'mock_signature') {
      signatureValid = true;
    } else if (razorpay) {
      const text = razorpayOrderId + '|' + razorpayPaymentId;
      const generated_signature = crypto
        .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || 'mockkeysecret67890')
        .update(text)
        .digest('hex');

      if (generated_signature === razorpaySignature) {
        signatureValid = true;
      }
    }

    if (!signatureValid) {
      // Record failed transaction log
      await Payment.findOneAndUpdate(
        { booking: bookingId, razorpayOrderId: razorpayOrderId },
        { status: 'failed' }
      );
      
      return res.status(400).json({
        success: false,
        message: 'Payment verification failed. Invalid signature.',
        data: null
      });
    }

    // Process success
    await processSuccessfulPayment(booking, booking.quotePrice, 'Online', {
      razorpayOrderId,
      razorpayPaymentId
    });

    return res.status(200).json({
      success: true,
      message: 'Online payment verified and logged successfully',
      booking,
      data: {
        booking
      }
    });
  } catch (err) {
    next(err);
  }
};
