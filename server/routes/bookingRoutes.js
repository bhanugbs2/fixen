const express = require('express');
const router = express.Router();
const {
  createBooking,
  submitQuote,
  acceptQuote,
  startJob,
  verifyOtp,
  completeJob,
  cancelBooking,
  getBooking,
  getBookings
} = require('../controllers/bookingController');
const { protect } = require('../middleware/auth');
const { createBookingRules, validate } = require('../middleware/validation');

// All booking routes require JWT authentication
router.use(protect);

router.route('/')
  .get(getBookings)
  .post(createBookingRules, validate, createBooking);

router.route('/:id')
  .get(getBooking);

router.post('/:id/quote', submitQuote);
router.post('/:id/accept', acceptQuote);
router.post('/:id/start', startJob);
router.post('/:id/verify-otp', verifyOtp);
router.post('/:id/complete', completeJob);
router.post('/:id/cancel', cancelBooking);

module.exports = router;
