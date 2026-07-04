const Worker = require('../models/Worker');
const Review = require('../models/Review');
const Commission = require('../models/Commission');

// @desc    Toggle Worker Active/Offline Status
// @route   PUT /api/v1/workers/status
// @access  Private (Worker)
exports.toggleStatus = async (req, res, next) => {
  try {
    const { isOnline } = req.body;
    
    if (isOnline === undefined) {
      return res.status(400).json({
        success: false,
        message: 'isOnline status value is required',
        data: null
      });
    }

    const worker = await Worker.findByIdAndUpdate(
      req.user.id,
      { isOnline: !!isOnline },
      { new: true, runValidators: true }
    );

    if (!worker) {
      return res.status(404).json({
        success: false,
        message: 'Worker not found',
        data: null
      });
    }

    return res.status(200).json({
      success: true,
      message: `Worker status changed to ${worker.isOnline ? 'Online' : 'Offline'}`,
      user: worker,
      data: {
        user: worker
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Toggle Worker Busy Status
// @route   PUT /api/v1/workers/busy
// @access  Private (Worker)
exports.toggleBusy = async (req, res, next) => {
  try {
    const { isBusy } = req.body;

    if (isBusy === undefined) {
      return res.status(400).json({
        success: false,
        message: 'isBusy status value is required',
        data: null
      });
    }

    const worker = await Worker.findByIdAndUpdate(
      req.user.id,
      { isBusy: !!isBusy },
      { new: true, runValidators: true }
    );

    if (!worker) {
      return res.status(404).json({
        success: false,
        message: 'Worker not found',
        data: null
      });
    }

    return res.status(200).json({
      success: true,
      message: `Worker busy status changed to ${worker.isBusy ? 'Busy' : 'Available'}`,
      user: worker,
      data: {
        user: worker
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get Worker Commission & Weekly Earnings
// @route   GET /api/v1/workers/commission
// @access  Private (Worker)
exports.getCommissionStatus = async (req, res, next) => {
  try {
    const worker = await Worker.findById(req.user.id);
    if (!worker) {
      return res.status(404).json({
        success: false,
        message: 'Worker not found',
        data: null
      });
    }

    const logs = await Commission.find({ worker: req.user.id }).sort('-createdAt');

    const commissionData = {
      id: worker.id,
      name: worker.name,
      weeklyEarnings: worker.weeklyEarnings || 0,
      commissionDue: worker.commissionDue || 0,
      isBlocked: worker.isBlocked || false,
      history: logs
    };

    return res.status(200).json({
      success: true,
      message: 'Weekly commission status retrieved',
      ...commissionData,
      data: commissionData
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get Reviews & Ratings for a Worker
// @route   GET /api/v1/workers/:id/reviews
// @access  Public
exports.getWorkerReviews = async (req, res, next) => {
  try {
    const workerId = req.params.id;

    const worker = await Worker.findById(workerId);
    if (!worker) {
      return res.status(404).json({
        success: false,
        message: 'Worker not found',
        data: null
      });
    }

    const reviews = await Review.find({ worker: workerId })
      .populate({ path: 'user', select: 'name profileImage' })
      .sort('-createdAt');

    const reviewStats = {
      rating: worker.rating,
      reviewCount: worker.reviewCount,
      reviews
    };

    return res.status(200).json({
      success: true,
      message: 'Worker reviews and rating statistics retrieved',
      ...reviewStats,
      data: reviewStats
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Update Worker Profile Details (e.g. service category)
// @route   PUT /api/v1/workers/profile
// @access  Private (Worker)
exports.updateProfile = async (req, res, next) => {
  try {
    const { service } = req.body;

    if (!service) {
      return res.status(400).json({
        success: false,
        message: 'Service category is required',
        data: null
      });
    }

    if (!['Electrician', 'Plumber', 'Carpenter'].includes(service)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid service category. Must be one of Electrician, Plumber, Carpenter',
        data: null
      });
    }

    const worker = await Worker.findByIdAndUpdate(
      req.user.id,
      { service },
      { new: true, runValidators: true }
    );

    if (!worker) {
      return res.status(404).json({
        success: false,
        message: 'Worker not found',
        data: null
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Worker profile updated successfully',
      user: worker,
      data: {
        user: worker
      }
    });
  } catch (err) {
    next(err);
  }
};
