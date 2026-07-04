const mongoose = require('mongoose');

const QuoteSchema = new mongoose.Schema({
  worker: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Worker',
    required: true
  },
  price: {
    type: Number,
    required: true
  },
  eta: {
    type: Number, // In minutes
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

const BookingSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'A booking must belong to a user']
  },
  worker: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Worker'
  },
  category: {
    type: String,
    enum: ['Electrician', 'Plumber', 'Carpenter'],
    required: [true, 'Please select a service category']
  },
  description: {
    type: String,
    required: [true, 'Please describe the issue']
  },
  attachedImages: {
    type: [String],
    default: []
  },
  voiceRecordings: {
    type: [String],
    default: []
  },
  status: {
    type: String,
    enum: ['pending', 'travelling', 'arrived', 'progress', 'completed', 'paid', 'cancelled'],
    default: 'pending'
  },
  otp: {
    type: String,
    default: ''
  },
  quotePrice: {
    type: Number,
    default: 0
  },
  quoteEta: {
    type: Number,
    default: 0
  },
  paymentMethod: {
    type: String,
    enum: ['Cash', 'Online'],
    default: 'Cash'
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid'],
    default: 'pending'
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true
    }
  },
  quotes: {
    type: [QuoteSchema],
    default: []
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

BookingSchema.index({ location: '2dsphere' });

BookingSchema.method('toJSON', function() {
  const { __v, _id, ...object } = this.toObject();
  object.id = _id.toString();
  return object;
});

module.exports = mongoose.model('Booking', BookingSchema);
