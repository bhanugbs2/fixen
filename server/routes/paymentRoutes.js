const express = require('express');
const router = express.Router();
const { initiatePayment, verifyPayment } = require('../controllers/paymentController');
const { protect } = require('../middleware/auth');

// Payment routes are protected user actions
router.post('/pay', protect, initiatePayment);
router.post('/verify', protect, verifyPayment);

module.exports = router;
