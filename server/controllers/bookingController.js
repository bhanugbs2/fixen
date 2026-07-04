const Booking = require('../models/Booking');
const Worker = require('../models/Worker');
const User = require('../models/User');
const { emitToUser } = require('../config/socket');
const { sendPushNotification } = require('../config/firebase');

// Helper to generate 4-digit OTP
const generateOTP = () => {
  return Math.floor(1000 + Math.random() * 9000).toString();
};

// @desc    Create a new booking request (Customer)
// @route   POST /api/v1/bookings
// @access  Private (User)
exports.createBooking = async (req, res, next) => {
  try {
    const { category, description, attachedImages, voiceRecordings, latitude, longitude } = req.body;

    const otp = generateOTP();

    const booking = await Booking.create({
      user: req.user.id,
      category,
      description,
      attachedImages: attachedImages || [],
      voiceRecordings: voiceRecordings || [],
      otp,
      location: {
        type: 'Point',
        coordinates: [parseFloat(longitude), parseFloat(latitude)]
      },
      status: 'pending'
    });

    // Populate user details for broadcast
    const user = await User.findById(req.user.id).select('name mobileNumber profileImage');

    // Notify nearby workers matching the category within 20 KM
    const nearbyWorkers = await Worker.find({
      service: category,
      isOnline: true,
      isBusy: false,
      isBlocked: false,
      verificationStatus: 'approved',
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(longitude), parseFloat(latitude)]
          },
          $maxDistance: 20000 // 20 KM limit
        }
      }
    });

    console.log(`Notifying ${nearbyWorkers.length} workers of category ${category}`);

    // Broadcast Socket event to all matching online workers
    nearbyWorkers.forEach(worker => {
      emitToUser(worker._id, 'bookingRequest', {
        bookingId: booking._id,
        category,
        description,
        otpCode: otp,
        user: {
          name: user.name,
          mobileNumber: user.mobileNumber,
          profileImage: user.profileImage
        },
        location: {
          latitude,
          longitude
        }
      });
      
      // Send mock FCM push notification
      sendPushNotification(
        'mock_fcm_token_worker_' + worker._id,
        'New Request Alert',
        `A client requested a ${category} service near you.`
      );
    });

    return res.status(201).json({
      success: true,
      message: 'Booking request created successfully. Searching for workers...',
      booking,
      data: {
        booking
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Submit Quotation / Bid (Worker)
// @route   POST /api/v1/bookings/:id/quote
// @access  Private (Worker)
exports.submitQuote = async (req, res, next) => {
  try {
    const { price, eta } = req.body;
    const bookingId = req.params.id;

    if (!price || !eta) {
      return res.status(400).json({
        success: false,
        message: 'Please provide both quote price and ETA estimates',
        data: null
      });
    }

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found', data: null });
    }

    if (booking.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Booking is no longer accepting quotations',
        data: null
      });
    }

    // Check if worker already quoted
    const alreadyQuoted = booking.quotes.some(q => q.worker.toString() === req.user.id);
    if (alreadyQuoted) {
      return res.status(400).json({
        success: false,
        message: 'You have already submitted a quote for this booking',
        data: null
      });
    }

    const worker = await Worker.findById(req.user.id).select('name rating reviewCount profileImage service');

    // Add quote
    booking.quotes.push({
      worker: req.user.id,
      price: parseFloat(price),
      eta: parseInt(eta)
    });

    await booking.save();

    // Notify Customer about new quote
    emitToUser(booking.user, 'quoteReceived', {
      bookingId: booking._id,
      price: parseFloat(price),
      eta: parseInt(eta),
      worker: {
        id: worker.id,
        name: worker.name,
        rating: worker.rating,
        reviewCount: worker.reviewCount,
        profileImage: worker.profileImage,
        service: worker.service
      }
    });

    return res.status(200).json({
      success: true,
      message: 'Quotation submitted successfully',
      booking,
      data: {
        booking
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Accept Worker Quote (Customer)
// @route   POST /api/v1/bookings/:id/accept
// @access  Private (User)
exports.acceptQuote = async (req, res, next) => {
  try {
    const { workerId } = req.body;
    const bookingId = req.params.id;

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found', data: null });
    }

    // Find quote details
    const quote = booking.quotes.find(q => q.worker.toString() === workerId);
    if (!quote) {
      return res.status(400).json({
        success: false,
        message: 'No quotation found from this worker',
        data: null
      });
    }

    // Set worker and accepted price/ETA
    booking.worker = workerId;
    booking.quotePrice = quote.price;
    booking.quoteEta = quote.eta;
    booking.status = 'travelling';

    await booking.save();

    // Mark worker as busy
    await Worker.findByIdAndUpdate(workerId, { isBusy: true });

    // Populate worker and user details
    const worker = await Worker.findById(workerId).select('name rating reviewCount mobileNumber profileImage');
    const user = await User.findById(booking.user).select('name mobileNumber profileImage');

    // Notify Worker
    emitToUser(workerId, 'quoteAccepted', {
      bookingId: booking._id,
      status: 'travelling',
      user: {
        name: user.name,
        mobileNumber: user.mobileNumber,
        profileImage: user.profileImage
      }
    });

    // Notify Customer (Status Update)
    emitToUser(booking.user, 'bookingStatusUpdate', {
      bookingId: booking._id,
      status: 'travelling',
      worker: {
        id: worker.id,
        name: worker.name,
        rating: worker.rating,
        reviewCount: worker.reviewCount,
        mobileNumber: worker.mobileNumber,
        profileImage: worker.profileImage
      }
    });

    return res.status(200).json({
      success: true,
      message: 'Quotation accepted successfully',
      booking,
      data: {
        booking
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Worker Travel & Status transitions (travelling -> arrived)
// @route   POST /api/v1/bookings/:id/start
// @access  Private (Worker)
exports.startJob = async (req, res, next) => {
  try {
    const bookingId = req.params.id;
    const { status } = req.body; // expect 'travelling' or 'arrived'

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found', data: null });
    }

    if (booking.worker.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized for this booking', data: null });
    }

    if (!['travelling', 'arrived'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status update', data: null });
    }

    booking.status = status;
    await booking.save();

    // Broadcast status update
    emitToUser(booking.user, 'bookingStatusUpdate', {
      bookingId: booking._id,
      status
    });
    emitToUser(booking.worker, 'bookingStatusUpdate', {
      bookingId: booking._id,
      status
    });

    return res.status(200).json({
      success: true,
      message: `Booking status updated to ${status}`,
      booking,
      data: {
        booking
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Verify customer OTP to start session (Worker)
// @route   POST /api/v1/bookings/:id/verify-otp
// @access  Private (Worker)
exports.verifyOtp = async (req, res, next) => {
  try {
    const { otp } = req.body;
    const bookingId = req.params.id;

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found', data: null });
    }

    if (booking.worker.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized for this booking', data: null });
    }

    if (booking.status !== 'arrived') {
      return res.status(400).json({
        success: false,
        message: 'OTP can only be verified when worker has arrived',
        data: null
      });
    }

    if (booking.otp !== otp) {
      return res.status(400).json({
        success: false,
        message: 'Incorrect OTP! Verification failed.',
        data: null
      });
    }

    booking.status = 'progress';
    await booking.save();

    // Broadcast status update
    const updatePayload = {
      bookingId: booking._id,
      status: 'progress'
    };
    emitToUser(booking.user, 'bookingStatusUpdate', updatePayload);
    emitToUser(booking.worker, 'bookingStatusUpdate', updatePayload);

    return res.status(200).json({
      success: true,
      message: 'OTP verified successfully. Job session started.',
      booking,
      data: {
        booking
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Complete job (Worker)
// @route   POST /api/v1/bookings/:id/complete
// @access  Private (Worker)
exports.completeJob = async (req, res, next) => {
  try {
    const bookingId = req.params.id;

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found', data: null });
    }

    if (booking.worker.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Not authorized for this booking', data: null });
    }

    if (booking.status !== 'progress') {
      return res.status(400).json({
        success: false,
        message: 'Only in-progress jobs can be completed',
        data: null
      });
    }

    booking.status = 'completed';
    await booking.save();

    // Broadcast status update
    const updatePayload = {
      bookingId: booking._id,
      status: 'completed'
    };
    emitToUser(booking.user, 'bookingStatusUpdate', updatePayload);
    emitToUser(booking.worker, 'bookingStatusUpdate', updatePayload);

    return res.status(200).json({
      success: true,
      message: 'Job completed successfully. Invoice generated.',
      booking,
      data: {
        booking
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Cancel booking
// @route   POST /api/v1/bookings/:id/cancel
// @access  Private
exports.cancelBooking = async (req, res, next) => {
  try {
    const bookingId = req.params.id;

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found', data: null });
    }

    // Check authorization: must be the creator customer or assigned worker
    const userId = req.user.id;
    if (booking.user.toString() !== userId && booking.worker?.toString() !== userId) {
      return res.status(403).json({ success: false, message: 'Not authorized to cancel this booking', data: null });
    }

    booking.status = 'cancelled';
    await booking.save();

    // Re-activate worker if one was assigned
    if (booking.worker) {
      await Worker.findByIdAndUpdate(booking.worker, { isBusy: false });
      emitToUser(booking.worker, 'bookingStatusUpdate', { bookingId: booking._id, status: 'cancelled' });
    }

    emitToUser(booking.user, 'bookingStatusUpdate', { bookingId: booking._id, status: 'cancelled' });

    return res.status(200).json({
      success: true,
      message: 'Booking cancelled successfully',
      booking,
      data: {
        booking
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get Booking by ID
// @route   GET /api/v1/bookings/:id
// @access  Private
exports.getBooking = async (req, res, next) => {
  try {
    const booking = await Booking.findById(req.params.id)
      .populate('user', 'name email mobileNumber profileImage')
      .populate('worker', 'name email mobileNumber profileImage service rating experience');

    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
        data: null
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Booking details retrieved',
      booking,
      data: {
        booking
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get All Bookings
// @route   GET /api/v1/bookings
// @access  Private
exports.getBookings = async (req, res, next) => {
  try {
    let bookings;

    if (req.user.role === 'user') {
      bookings = await Booking.find({ user: req.user.id })
        .populate('worker', 'name service profileImage rating')
        .sort('-createdAt');
    } else if (req.user.role === 'worker') {
      // Find worker's own bookings or active pending bookings matching their service type
      bookings = await Booking.find({
        $or: [
          { worker: req.user.id },
          { status: 'pending', category: req.user.service }
        ]
      })
        .populate('user', 'name address profileImage mobileNumber')
        .sort('-createdAt');
    } else {
      // Admin gets everything
      bookings = await Booking.find()
        .populate('user', 'name')
        .populate('worker', 'name service')
        .sort('-createdAt');
    }

    return res.status(200).json({
      success: true,
      message: 'Bookings list retrieved',
      bookings,
      data: {
        bookings
      }
    });
  } catch (err) {
    next(err);
  }
};
