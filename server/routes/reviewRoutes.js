const express = require('express');
const router = express.Router();
const { createReview } = require('../controllers/reviewController');
const { protect } = require('../middleware/auth');
const { createReviewRules, validate } = require('../middleware/validation');

// Review submissions are protected customer routes
router.post('/', protect, createReviewRules, validate, createReview);

module.exports = router;
