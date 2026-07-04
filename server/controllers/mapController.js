const Worker = require('../models/Worker');

// Deg to Rad helper
const deg2rad = (deg) => deg * (Math.PI / 180);

// Haversine formula to compute distance in KM
const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // Earth radius in km
  const dLat = deg2rad(lat2 - lat1);
  const dLon = deg2rad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(deg2rad(lat1)) * Math.cos(deg2rad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c; // Distance in km
};

// Helper query to find online, available, approved workers in a given radius
const findWorkersInRadius = async (lat, lng, radiusInMeters, service) => {
  const query = {
    isOnline: true,
    isBusy: false,
    isBlocked: false,
    verificationStatus: 'approved',
    location: {
      $near: {
        $geometry: {
          type: 'Point',
          coordinates: [parseFloat(lng), parseFloat(lat)]
        },
        $maxDistance: radiusInMeters
      }
    }
  };

  if (service) {
    query.service = service;
  }

  return await Worker.find(query);
};

// @desc    Get nearby workers
// @route   GET /api/v1/maps/nearby-workers
// @access  Public
exports.getNearbyWorkers = async (req, res, next) => {
  try {
    const { latitude, longitude, service } = req.query;

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Please provide both latitude and longitude coordinates',
        data: null
      });
    }

    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);

    // Incremental search radius checks: 5 KM -> 10 KM -> 20 KM
    let radiusInKm = 5;
    let workers = await findWorkersInRadius(lat, lng, 5000, service);

    if (workers.length === 0) {
      radiusInKm = 10;
      workers = await findWorkersInRadius(lat, lng, 10000, service);
    }

    if (workers.length === 0) {
      radiusInKm = 20;
      workers = await findWorkersInRadius(lat, lng, 20000, service);
    }

    // Map through workers, calculate explicit distance, and format matching the frontend model
    let formattedWorkers = workers.map(worker => {
      const workerObj = worker.toJSON();
      const [workerLng, workerLat] = worker.location.coordinates;
      
      // Calculate distance in KM
      const distance = calculateDistance(lat, lng, workerLat, workerLng);
      workerObj.distance = Math.round(distance * 100) / 100; // rounded to 2 decimal points
      
      return workerObj;
    });

    // Sort: Distance (ascending), Rating (descending), Verification approved (highest priority)
    formattedWorkers.sort((a, b) => {
      if (a.distance !== b.distance) {
        return a.distance - b.distance;
      }
      if (b.rating !== a.rating) {
        return b.rating - a.rating;
      }
      const aVer = a.verificationStatus === 'approved' ? 1 : 0;
      const bVer = b.verificationStatus === 'approved' ? 1 : 0;
      return bVer - aVer;
    });

    return res.status(200).json({
      success: true,
      message: `Found ${formattedWorkers.length} nearby workers within ${radiusInKm} KM radius.`,
      workers: formattedWorkers,
      radiusUsed: radiusInKm,
      data: {
        workers: formattedWorkers,
        radiusUsed: radiusInKm
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Update Worker GPS Location via REST
// @route   POST /api/v1/maps/update-location
// @access  Private (Worker)
exports.updateLocation = async (req, res, next) => {
  try {
    const { latitude, longitude } = req.body;

    if (latitude === undefined || longitude === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Please provide both latitude and longitude coordinates',
        data: null
      });
    }

    const worker = await Worker.findByIdAndUpdate(
      req.user.id,
      {
        isOnline: true,
        location: {
          type: 'Point',
          coordinates: [parseFloat(longitude), parseFloat(latitude)]
        }
      },
      { new: true, runValidators: true }
    );

    if (!worker) {
      return res.status(404).json({
        success: false,
        message: 'Worker not found',
        data: null
      });
    }

    // Broadcast updated coordinates via Socket to active customers
    const { getIO } = require('../config/socket');
    try {
      const io = getIO();
      const Booking = require('../models/Booking');
      const activeBooking = await Booking.findOne({
        worker: worker._id,
        status: { $in: ['travelling', 'arrived', 'progress'] }
      });

      if (activeBooking) {
        io.to(activeBooking.user.toString()).emit('locationUpdate', {
          bookingId: activeBooking._id,
          latitude: parseFloat(latitude),
          longitude: parseFloat(longitude)
        });
      }
    } catch (e) {
      // socket.io not initialized yet or running tests
    }

    return res.status(200).json({
      success: true,
      message: 'Location updated successfully',
      user: worker,
      data: {
        user: worker
      }
    });
  } catch (err) {
    next(err);
  }
};
