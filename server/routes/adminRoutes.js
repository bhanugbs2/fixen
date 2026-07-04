const express = require('express');
const router = express.Router();
const {
  verifyWorker,
  blockWorker,
  getAllCommissions,
  collectCommission,
  getDashboardStats
} = require('../controllers/adminController');
const { protect, authorize } = require('../middleware/auth');

// All admin routes are protected and require admin privileges
router.use(protect);
router.use(authorize('admin'));

router.put('/workers/:id/verify', verifyWorker);
router.put('/workers/:id/block', blockWorker);
router.get('/commissions', getAllCommissions);
router.post('/commissions/:id/collect', collectCommission);
router.get('/stats', getDashboardStats);

module.exports = router;
