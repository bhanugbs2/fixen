const express = require('express');
const router = express.Router();
const {
  register,
  login,
  workerRegister,
  workerLogin,
  verifyWorkerOtp,
  adminLogin,
  getMe,
  logout,
  forgotPassword,
  refreshToken
} = require('../controllers/authController');
const { protect } = require('../middleware/auth');
const { workerUpload } = require('../middleware/upload');
const {
  validate,
  registerRules,
  loginRules,
  workerRegisterRules,
  workerLoginRules,
  verifyOtpRules
} = require('../middleware/validation');

// Customer Auth
router.post('/register', registerRules, validate, register);
router.post('/login', loginRules, validate, login);

// Worker Auth
router.post('/worker-register', workerUpload, workerRegisterRules, validate, workerRegister);
router.post('/worker-login', workerLoginRules, validate, workerLogin);
router.post('/verify-otp', verifyOtpRules, validate, verifyWorkerOtp);

// Admin Auth
router.post('/admin-login', loginRules, validate, adminLogin);

// Token Handlers
router.post('/refresh', refreshToken);
router.post('/forgot-password', forgotPassword);

// Profile (Protected)
router.get('/me', protect, getMe);
router.post('/logout', protect, logout);

module.exports = router;
