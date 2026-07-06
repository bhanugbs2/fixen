const { body, validationResult } = require('express-validator');

// Common helper to handle validation results and return formatted errors
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    // Return first error message
    return res.status(400).json({
      success: false,
      message: errors.array()[0].msg,
      data: {
        errors: errors.array()
      }
    });
  }
  next();
};

// User Registration rules
const registerRules = [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').trim().isEmail().withMessage('Please enter a valid email address'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters long'),
  body('mobileNumber').trim().notEmpty().withMessage('Mobile number is required'),
  body('address').trim().notEmpty().withMessage('Address is required')
];

// Login rules
const loginRules = [
  body('email').trim().isEmail().withMessage('Please enter a valid email address'),
  body('password').notEmpty().withMessage('Password is required')
];

// Worker Registration rules
const workerRegisterRules = [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').trim().isEmail().withMessage('Please enter a valid email address'),
  body('mobileNumber').trim().notEmpty().withMessage('Mobile number is required'),
  body('address').trim().notEmpty().withMessage('Address is required'),
  body('service')
    .isIn(['Electrician', 'Plumber', 'Carpenter'])
    .withMessage('Service category must be Electrician, Plumber, or Carpenter'),
  body('experience')
    .optional()
    .isInt({ min: 0 })
    .withMessage('Experience must be a positive integer'),
  body('languages')
    .optional()
    .custom((val) => {
      if (typeof val === 'string') {
        try {
          JSON.parse(val);
        } catch (e) {
          throw new Error('Languages must be a valid JSON array');
        }
      }
      return true;
    })
];

// Worker Login rules
const workerLoginRules = [
  body('mobileNumber').trim().notEmpty().withMessage('Mobile number is required')
];

// Worker OTP Verification rules
const verifyOtpRules = [
  body('mobileNumber').trim().notEmpty().withMessage('Mobile number is required'),
  body('otp').trim().isLength({ min: 6, max: 6 }).withMessage('OTP must be exactly 6 digits')
];

// Booking Creation rules
const createBookingRules = [
  body('category')
    .isIn(['Electrician', 'Plumber', 'Carpenter'])
    .withMessage('Service category must be Electrician, Plumber, or Carpenter'),
  body('description').trim().notEmpty().withMessage('Job description is required'),
  body('latitude').isFloat().withMessage('Valid latitude is required'),
  body('longitude').isFloat().withMessage('Valid longitude is required')
];

// Review Creation rules
const createReviewRules = [
  body('bookingId').trim().notEmpty().withMessage('Booking ID is required'),
  body('rating')
    .isInt({ min: 1, max: 5 })
    .withMessage('Rating must be an integer between 1 and 5'),
  body('comment').optional().trim()
];

module.exports = {
  validate,
  registerRules,
  loginRules,
  workerRegisterRules,
  workerLoginRules,
  verifyOtpRules,
  createBookingRules,
  createReviewRules
};
