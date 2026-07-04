const Review = require('../models/Review');
const Booking = require('../models/Booking');

// @desc    Submit a Review
// @route   POST /api/v1/reviews
// @access  Private (User)
exports.createReview = async (req, res, next) => {
  try {
    const { bookingId, rating, comment } = req.body;

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found',
        data: null
      });
    }

    // Verify booking belongs to this user
    if (booking.user.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'You are not authorized to review this booking',
        data: null
      });
    }

    // Verify worker is assigned
    if (!booking.worker) {
      return res.status(400).json({
        success: false,
        message: 'No worker was assigned to this booking',
        data: null
      });
    }

    // Check if user already reviewed this booking
    const alreadyReviewed = await Review.findOne({
      booking: bookingId,
      user: req.user.id
    });

    if (alreadyReviewed) {
      return res.status(400).json({
        success: false,
        message: 'You have already reviewed this booking',
        data: null
      });
    }

    // Create review (Mongoose hook on Review schema recalculates worker avg rating and reviewCount)
    const review = await Review.create({
      booking: bookingId,
      user: req.user.id,
      worker: booking.worker,
      rating: parseInt(rating),
      comment: comment || ''
    });

    return res.status(201).json({
      success: true,
      message: 'Review submitted successfully',
      review,
      data: {
        review
      }
    });
  } catch (err) {
    next(err);
  }
};
