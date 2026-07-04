const mongoose = require('mongoose');

const connectDB = async () => {
  // Disable query buffering when disconnected to prevent server requests from hanging
  mongoose.set('bufferCommands', false);

  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/fixen', {
      serverSelectionTimeoutMS: 5000 // 5 seconds timeout
    });
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.warn(`⚠️ Database connection failed: ${error.message}`);
    console.warn(`⚠️ The FIXEN server will run in database-disconnected/mock mode.`);
  }
};

module.exports = connectDB;
