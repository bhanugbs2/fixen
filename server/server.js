const express = require('express');
const http = require('http');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const dotenv = require('dotenv');
const swaggerUi = require('swagger-ui-express');

// Load env vars
dotenv.config();

const connectDB = require('./config/database');
const { initSocket } = require('./config/socket');
const errorHandler = require('./middleware/errorHandler');

// Initialize database
connectDB();

const app = express();
const server = http.createServer(app);

// Initialize Socket.IO
initSocket(server);

// Body parser
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Dev logging middleware
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
} else {
  app.use(morgan('combined'));
}

// Enable CORS
app.use(cors());

// Set security headers
app.use(
  helmet({
    crossOriginResourcePolicy: false, // Allows loading uploaded images in Flutter directly
    contentSecurityPolicy: false // Allows WebAssembly compilation in the browser
  })
);

// Compress responses
app.use(compression());

// Set static folder for file uploads (profile pics, aadhaar, driving license)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Serve compiled Flutter web application client at root path
app.use(express.static(path.join(__dirname, '../build/web')));

// Swagger API Documentation Endpoint
try {
  const swaggerDocument = require('./swagger.json');
  app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
  console.log('Swagger API Documentation mounted at /api-docs');
} catch (err) {
  console.warn('Swagger documentation swagger.json not loaded yet. Route /api-docs will be active once file is created.');
}

// Import Route Files
const authRoutes = require('./routes/authRoutes');
const workerRoutes = require('./routes/workerRoutes');
const mapRoutes = require('./routes/mapRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const adminRoutes = require('./routes/adminRoutes');

// Mount Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/workers', workerRoutes);
app.use('/api/v1/maps', mapRoutes);
app.use('/api/v1/bookings', bookingRoutes);
app.use('/api/v1/reviews', reviewRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/admin', adminRoutes);

// Fallback Route for Flutter client-side history routing and API 404s
app.use('*', (req, res) => {
  if (req.originalUrl.startsWith('/api/v1')) {
    return res.status(404).json({
      success: false,
      message: `Cannot ${req.method} ${req.originalUrl}. Endpoint not found.`,
      data: null
    });
  }
  // Redirect other browser paths back to Flutter index.html for client-side routing
  res.sendFile(path.join(__dirname, '../build/web/index.html'));
});

// Global Custom Error Handler
app.use(errorHandler);

const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
  console.log(`FIXEN Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
});
