const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const WorkerSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please add a name']
  },
  email: {
    type: String,
    required: [true, 'Please add an email'],
    unique: true,
    match: [
      /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
      'Please add a valid email'
    ]
  },
  password: {
    type: String,
    required: [true, 'Please add a password'],
    minlength: 6,
    select: false
  },
  mobileNumber: {
    type: String,
    required: [true, 'Please add a mobile number']
  },
  address: {
    type: String,
    required: [true, 'Please add an address']
  },
  profileImage: {
    type: String,
    default: ''
  },
  role: {
    type: String,
    enum: ['worker'],
    default: 'worker'
  },
  governmentId: {
    type: String,
    required: [true, 'Please add government ID (e.g. W12345)'],
    unique: true
  },
  aadhaarCard: {
    type: String,
    default: ''
  },
  drivingLicense: {
    type: String,
    default: ''
  },
  verificationStatus: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'suspended'],
    default: 'pending'
  },
  experience: {
    type: Number,
    default: 0
  },
  languages: {
    type: [String],
    default: ['English', 'Hindi']
  },
  workingHours: {
    type: String,
    default: '9:00 AM - 6:00 PM'
  },
  rating: {
    type: Number,
    default: 5.0
  },
  reviewCount: {
    type: Number,
    default: 0
  },
  isOnline: {
    type: Boolean,
    default: false
  },
  isBusy: {
    type: Boolean,
    default: false
  },
  commissionDue: {
    type: Number,
    default: 0.0
  },
  isBlocked: {
    type: Boolean,
    default: false
  },
  service: {
    type: String,
    enum: ['Electrician', 'Plumber', 'Carpenter'],
    required: [true, 'Please select a service category']
  },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      default: [80.4365, 16.3067] // default coordinates
    }
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Index for geo-spatial queries
WorkerSchema.index({ location: '2dsphere' });

// Encrypt password using bcrypt
WorkerSchema.pre('save', async function (next) {
  if (!this.isModified('password')) {
    next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Match entered password
WorkerSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

// Transform output to match Flutter model exactly
WorkerSchema.method('toJSON', function() {
  const { __v, _id, password, ...object } = this.toObject();
  object.id = _id.toString();
  return object;
});

module.exports = mongoose.model('Worker', WorkerSchema);
