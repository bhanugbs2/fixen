const express = require('express');
const router = express.Router();
const { getNearbyWorkers, updateLocation } = require('../controllers/mapController');
const { protect, authorize } = require('../middleware/auth');

// Public access to fetch nearby workers
router.get('/nearby-workers', getNearbyWorkers);

// Protected Worker Action to update live GPS coordinates
router.post('/update-location', protect, authorize('worker'), updateLocation);

module.exports = router;
