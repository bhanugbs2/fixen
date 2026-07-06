const User = require('../models/User');
const Worker = require('../models/Worker');
const Booking = require('../models/Booking');
const Commission = require('../models/Commission');

// @desc    Approve or Reject Worker government verification
// @route   PUT /api/v1/admin/workers/:id/verify
// @access  Private (Admin)
exports.verifyWorker = async (req, res, next) => {
  try {
    const { status } = req.body; // 'approved' or 'rejected'
    const workerId = req.params.id;

    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid verification status. Use approved or rejected',
        data: null
      });
    }

    const worker = await Worker.findByIdAndUpdate(
      workerId,
      { verificationStatus: status },
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
      message: `Worker verification status updated to ${status}`,
      user: worker,
      data: {
        user: worker
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Temporarily block/unblock a worker
// @route   PUT /api/v1/admin/workers/:id/block
// @access  Private (Admin)
exports.blockWorker = async (req, res, next) => {
  try {
    const { isBlocked } = req.body;
    const workerId = req.params.id;

    if (isBlocked === undefined) {
      return res.status(400).json({
        success: false,
        message: 'isBlocked value is required',
        data: null
      });
    }

    const worker = await Worker.findByIdAndUpdate(
      workerId,
      { isBlocked: !!isBlocked },
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
      message: `Worker status changed to ${worker.isBlocked ? 'Blocked' : 'Active'}`,
      user: worker,
      data: {
        user: worker
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get all monthly commission logs for tracking
// @route   GET /api/v1/admin/commissions
// @access  Private (Admin)
exports.getAllCommissions = async (req, res, next) => {
  try {
    const commissions = await Commission.find()
      .populate('worker', 'name service mobileNumber governmentId')
      .sort('-createdAt');

    return res.status(200).json({
      success: true,
      message: 'Monthly commission logs retrieved successfully',
      commissions,
      data: {
        commissions
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Collect worker's monthly commission and clear balance
// @route   POST /api/v1/admin/commissions/:id/collect
// @access  Private (Admin)
exports.collectCommission = async (req, res, next) => {
  try {
    const commissionId = req.params.id;

    const commission = await Commission.findById(commissionId);
    if (!commission) {
      return res.status(404).json({
        success: false,
        message: 'Commission log record not found',
        data: null
      });
    }

    if (commission.status === 'paid') {
      return res.status(400).json({
        success: false,
        message: 'This commission log is already paid',
        data: null
      });
    }

    // Update log status
    commission.status = 'paid';
    commission.paidAt = Date.now();
    await commission.save();

    // Deduct from worker's total due balance
    const worker = await Worker.findById(commission.worker);
    if (worker) {
      worker.commissionDue = Math.max(0, (worker.commissionDue || 0) - commission.amount);
      
      // Auto unblock worker if commission due falls below safety threshold of ₹2000
      if (worker.commissionDue < 2000 && worker.isBlocked) {
        worker.isBlocked = false;
      }
      
      await worker.save();
    }

    return res.status(200).json({
      success: true,
      message: 'Commission collected successfully and worker ledger updated',
      commission,
      data: {
        commission
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Get dashboard metrics & statistics
// @route   GET /api/v1/admin/stats
// @access  Private (Admin)
exports.getDashboardStats = async (req, res, next) => {
  try {
    const userCount = await User.countDocuments();
    const workerCount = await Worker.countDocuments();
    
    // Worker verification segments
    const pendingWorkers = await Worker.countDocuments({ verificationStatus: 'pending' });
    const approvedWorkers = await Worker.countDocuments({ verificationStatus: 'approved' });
    const blockedWorkers = await Worker.countDocuments({ isBlocked: true });

    // Booking counts
    const totalBookings = await Booking.countDocuments();
    const completedBookings = await Booking.countDocuments({ status: 'completed' });
    const paidBookings = await Booking.countDocuments({ status: 'paid' });
    const activeBookings = await Booking.countDocuments({ status: { $in: ['travelling', 'arrived', 'progress'] } });

    // Financial sums
    const financialStats = await Booking.aggregate([
      { $match: { status: 'paid' } },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: '$quotePrice' }
        }
      }
    ]);

    const totalRevenue = financialStats.length > 0 ? financialStats[0].totalRevenue : 0;
    
    // Commission summary
    const totalCommissionDueList = await Worker.aggregate([
      {
        $group: {
          _id: null,
          totalDue: { $sum: '$commissionDue' }
        }
      }
    ]);
    const totalCommissionDue = totalCommissionDueList.length > 0 ? totalCommissionDueList[0].totalDue : 0;

    const commissionCollectedList = await Commission.aggregate([
      { $match: { status: 'paid' } },
      {
        $group: {
          _id: null,
          totalCollected: { $sum: '$amount' }
        }
      }
    ]);
    const totalCommissionCollected = commissionCollectedList.length > 0 ? commissionCollectedList[0].totalCollected : 0;

    const stats = {
      users: userCount,
      workers: {
        total: workerCount,
        pending: pendingWorkers,
        approved: approvedWorkers,
        blocked: blockedWorkers
      },
      bookings: {
        total: totalBookings,
        completed: completedBookings,
        paid: paidBookings,
        active: activeBookings
      },
      revenue: {
        totalEarnings: totalRevenue,
        commissionDue: totalCommissionDue,
        commissionCollected: totalCommissionCollected
      }
    };

    return res.status(200).json({
      success: true,
      message: 'Dashboard statistics generated successfully',
      stats,
      data: {
        stats
      }
    });
  } catch (err) {
    next(err);
  }
};
