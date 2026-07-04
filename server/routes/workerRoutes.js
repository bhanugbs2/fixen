const express = require('express');
const router = express.Router();
const {
  toggleStatus,
  toggleBusy,
  getCommissionStatus,
  getWorkerReviews
} = require('../controllers/workerController');
const { protect, authorize } = require('../middleware/auth');

// Protected Worker Actions
router.put('/status', protect, authorize('worker'), toggleStatus);
router.put('/busy', protect, authorize('worker'), toggleBusy);
router.get('/commission', protect, authorize('worker'), getCommissionStatus);

// Public / User access to worker reviews
router.get('/:id/reviews', getWorkerReviews);

module.exports = router;
