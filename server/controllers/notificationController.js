const Notification = require('../models/Notification');

// @desc    Get Notifications for Current User
// @route   GET /api/v1/notifications
// @access  Private
exports.getNotifications = async (req, res, next) => {
  try {
    const notifications = await Notification.find({
      recipient: req.user.id
    }).sort('-createdAt');

    return res.status(200).json({
      success: true,
      message: 'Notifications list retrieved',
      notifications,
      data: {
        notifications
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Mark Notification as Read
// @route   PUT /api/v1/notifications/:id/read
// @access  Private
exports.markAsRead = async (req, res, next) => {
  try {
    const notification = await Notification.findById(req.params.id);

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found',
        data: null
      });
    }

    // Verify recipient
    if (notification.recipient.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to read this notification',
        data: null
      });
    }

    notification.read = true;
    await notification.save();

    return res.status(200).json({
      success: true,
      message: 'Notification marked as read',
      notification,
      data: {
        notification
      }
    });
  } catch (err) {
    next(err);
  }
};
