const mongoose = require('mongoose');

const ReviewSchema = new mongoose.Schema({
  booking: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Booking',
    required: true
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  worker: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Worker',
    required: true
  },
  rating: {
    type: Number,
    min: 1,
    max: 5,
    required: [true, 'Please add a rating between 1 and 5']
  },
  comment: {
    type: String,
    default: ''
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Statics method to get average rating of a worker
ReviewSchema.statics.getAverageRating = async function(workerId) {
  const stats = await this.aggregate([
    {
      $match: { worker: workerId }
    },
    {
      $group: {
        _id: '$worker',
        averageRating: { $avg: '$rating' },
        reviewCount: { $sum: 1 }
      }
    }
  ]);

  try {
    const Worker = mongoose.model('Worker');
    if (stats.length > 0) {
      await Worker.findByIdAndUpdate(workerId, {
        rating: Math.round(stats[0].averageRating * 10) / 10,
        reviewCount: stats[0].reviewCount
      });
    } else {
      await Worker.findByIdAndUpdate(workerId, {
        rating: 5.0,
        reviewCount: 0
      });
    }
  } catch (err) {
    console.error('Error updating worker rating stats:', err.message);
  }
};

// Call getAverageRating after save
ReviewSchema.post('save', async function() {
  await this.constructor.getAverageRating(this.worker);
});

// Call getAverageRating before remove
ReviewSchema.post('remove', async function() {
  await this.constructor.getAverageRating(this.worker);
});

ReviewSchema.method('toJSON', function() {
  const { __v, _id, ...object } = this.toObject();
  object.id = _id.toString();
  return object;
});

module.exports = mongoose.model('Review', ReviewSchema);
