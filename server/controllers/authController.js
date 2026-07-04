const User = require('../models/User');
const Worker = require('../models/Worker');
const Admin = require('../models/Admin');
const jwt = require('jsonwebtoken');

// Token generation helper
const generateTokens = (user) => {
  const payload = { id: user.id || user._id, role: user.role, email: user.email };
  
  const accessToken = jwt.sign(
    payload,
    process.env.JWT_SECRET || 'fixen_jwt_secret_key_change_me_in_production_987654321',
    { expiresIn: process.env.JWT_EXPIRY || '1d' }
  );

  const refreshToken = jwt.sign(
    payload,
    process.env.JWT_REFRESH_SECRET || 'fixen_jwt_refresh_key_change_me_in_production_123456789',
    { expiresIn: process.env.JWT_REFRESH_EXPIRY || '7d' }
  );

  return { accessToken, refreshToken };
};

// Response helper for dual-compatibility with Flutter client
const sendAuthResponse = (res, statusCode, success, message, user, tokens = {}) => {
  const responseData = {
    user,
    accessToken: tokens.accessToken || '',
    refreshToken: tokens.refreshToken || ''
  };

  // Add mobileNumber at root level if applicable
  if (user && user.mobileNumber) {
    responseData.mobileNumber = user.mobileNumber;
  }

  return res.status(statusCode).json({
    success,
    message,
    ...responseData,
    data: responseData
  });
};

// @desc    Register user
// @route   POST /api/v1/auth/register
// @access  Public
exports.register = async (req, res, next) => {
  try {
    const { name, email, password, mobileNumber, address } = req.body;

    // Check if user exists
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({
        success: false,
        message: 'Email already registered',
        data: null
      });
    }

    // Create user
    user = await User.create({
      name,
      email,
      password,
      mobileNumber,
      address,
      profileImage: req.body.profileImage || ''
    });

    const tokens = generateTokens(user);
    return sendAuthResponse(res, 201, true, 'User registered successfully', user, tokens);
  } catch (err) {
    next(err);
  }
};

// @desc    Login user
// @route   POST /api/v1/auth/login
// @access  Public
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Check for user
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
        data: null
      });
    }

    // Check if password matches
    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
        data: null
      });
    }

    const tokens = generateTokens(user);
    // Remove password field from JSON representation
    const userJson = user.toJSON();
    return sendAuthResponse(res, 200, true, 'Login successful', userJson, tokens);
  } catch (err) {
    next(err);
  }
};

// @desc    Register Worker
// @route   POST /api/v1/auth/worker-register
// @access  Public
exports.workerRegister = async (req, res, next) => {
  try {
    const { name, email, password, mobileNumber, address, governmentId, service, experience, workingHours } = req.body;

    // Check if worker exists
    let worker = await Worker.findOne({ email });
    if (worker) {
      return res.status(400).json({ success: false, message: 'Email already registered', data: null });
    }

    let checkGov = await Worker.findOne({ governmentId });
    if (checkGov) {
      return res.status(400).json({ success: false, message: 'Government ID already registered', data: null });
    }

    // Extract uploaded files
    const profileImage = req.files?.profileImage ? `/uploads/${req.files.profileImage[0].filename}` : '';
    const aadhaarCard = req.files?.aadhaarCard ? `/uploads/${req.files.aadhaarCard[0].filename}` : '';
    const drivingLicense = req.files?.drivingLicense ? `/uploads/${req.files.drivingLicense[0].filename}` : '';

    let parsedLanguages = ['English', 'Hindi'];
    if (req.body.languages) {
      try {
        parsedLanguages = typeof req.body.languages === 'string' ? JSON.parse(req.body.languages) : req.body.languages;
      } catch (e) {}
    }

    worker = await Worker.create({
      name,
      email,
      password: password || 'worker123', // default fallback password if not provided
      mobileNumber,
      address,
      profileImage,
      governmentId,
      aadhaarCard,
      drivingLicense,
      service,
      experience: experience ? parseInt(experience) : 0,
      workingHours: workingHours || '9:00 AM - 6:00 PM',
      languages: parsedLanguages,
      verificationStatus: 'pending' // waits for admin approval
    });

    const tokens = generateTokens(worker);
    return sendAuthResponse(res, 201, true, 'Worker registered successfully. Pending verification.', worker, tokens);
  } catch (err) {
    next(err);
  }
};

// @desc    Worker login request (check governmentId, return mobileNumber)
// @route   POST /api/v1/auth/worker-login
// @access  Public
exports.workerLogin = async (req, res, next) => {
  try {
    const { governmentId } = req.body;

    const worker = await Worker.findOne({ governmentId });
    if (!worker) {
      return res.status(404).json({
        success: false,
        message: 'Government ID not verified in FIXEN database.',
        data: null
      });
    }

    if (worker.isBlocked) {
      return res.status(403).json({
        success: false,
        message: 'Your account is temporarily blocked. Please contact support.',
        data: null
      });
    }

    // Response structure where mobileNumber is at root level for the api client
    return res.status(200).json({
      success: true,
      message: 'OTP sent successfully to registered mobile number',
      mobileNumber: worker.mobileNumber,
      data: {
        mobileNumber: worker.mobileNumber
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Worker Verify OTP
// @route   POST /api/v1/auth/verify-otp
// @access  Public
exports.verifyWorkerOtp = async (req, res, next) => {
  try {
    const { governmentId, otp } = req.body;

    // Simulate OTP validation: accept 123456
    if (otp !== '123456') {
      return res.status(400).json({
        success: false,
        message: 'Incorrect OTP. Verification failed.',
        data: null
      });
    }

    const worker = await Worker.findOne({ governmentId });
    if (!worker) {
      return res.status(404).json({
        success: false,
        message: 'Worker record not found',
        data: null
      });
    }

    const tokens = generateTokens(worker);
    return sendAuthResponse(res, 200, true, 'OTP verified successfully', worker, tokens);
  } catch (err) {
    next(err);
  }
};

// @desc    Admin login
// @route   POST /api/v1/auth/admin-login
// @access  Public
exports.adminLogin = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    let admin = await Admin.findOne({ email }).select('+password');
    if (!admin) {
      // Create seed admin for demo if not exists and using default admin credentials
      if (email === 'admin@fixen.com' && password === 'admin123') {
        admin = await Admin.create({
          name: 'FIXEN Administrator',
          email: 'admin@fixen.com',
          password: 'admin123',
          mobileNumber: '+919999999999',
          address: 'FIXEN HQ, Delhi'
        });
      } else {
        return res.status(401).json({
          success: false,
          message: 'Admin authorization failed.',
          data: null
        });
      }
    } else {
      const isMatch = await admin.matchPassword(password);
      if (!isMatch) {
        return res.status(401).json({
          success: false,
          message: 'Admin authorization failed.',
          data: null
        });
      }
    }

    const tokens = generateTokens(admin);
    const adminJson = admin.toJSON();
    return sendAuthResponse(res, 200, true, 'Admin login successful', adminJson, tokens);
  } catch (err) {
    next(err);
  }
};

// @desc    Get Current User
// @route   GET /api/v1/auth/me
// @access  Private
exports.getMe = async (req, res, next) => {
  try {
    let profile = null;

    if (req.user.role === 'user') {
      profile = await User.findById(req.user.id);
    } else if (req.user.role === 'worker') {
      profile = await Worker.findById(req.user.id);
    } else if (req.user.role === 'admin') {
      profile = await Admin.findById(req.user.id);
    }

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: 'Profile not found',
        data: null
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Current user profile retrieved',
      user: profile,
      data: {
        user: profile
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Logout user
// @route   POST /api/v1/auth/logout
// @access  Private
exports.logout = async (req, res, next) => {
  try {
    return res.status(200).json({
      success: true,
      message: 'Logged out successfully',
      data: {}
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Forgot Password
// @route   POST /api/v1/auth/forgot-password
// @access  Public
exports.forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;
    return res.status(200).json({
      success: true,
      message: 'Password reset link sent to registered email address',
      data: {
        email
      }
    });
  } catch (err) {
    next(err);
  }
};

// @desc    Refresh Token
// @route   POST /api/v1/auth/refresh
// @access  Public
exports.refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token is required',
        data: null
      });
    }

    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET || 'fixen_jwt_refresh_key_change_me_in_production_123456789');
    
    let profile = null;
    if (decoded.role === 'user') {
      profile = await User.findById(decoded.id);
    } else if (decoded.role === 'worker') {
      profile = await Worker.findById(decoded.id);
    } else if (decoded.role === 'admin') {
      profile = await Admin.findById(decoded.id);
    }

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: 'Account not found',
        data: null
      });
    }

    const tokens = generateTokens(profile);
    return res.status(200).json({
      success: true,
      message: 'Token refreshed',
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      data: {
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken
      }
    });
  } catch (err) {
    return res.status(401).json({
      success: false,
      message: 'Invalid refresh token',
      data: null
    });
  }
};
