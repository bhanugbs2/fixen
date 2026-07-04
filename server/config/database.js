const mongoose = require("mongoose");

const connectDB = async () => {
  // Disable query buffering when disconnected to prevent server requests from hanging
  mongoose.set('bufferCommands', false);

  const atlasUri = process.env.MONGODB_URI;
  const localUri = 'mongodb://127.0.0.1:27017/fixen';

  try {
    console.log("Connecting to MongoDB Atlas...");
    // Try to connect to Atlas with an 8-second timeout
    const conn = await mongoose.connect(atlasUri, {
      serverSelectionTimeoutMS: 8000
    });
    console.log(`✅ MongoDB Connected to Atlas: ${conn.connection.host}`);
  } catch (atlasError) {
    console.warn(`⚠️ MongoDB Atlas Connection Failed: ${atlasError.message}`);
    console.log("Attempting fallback to local MongoDB...");
    try {
      const conn = await mongoose.connect(localUri, {
        serverSelectionTimeoutMS: 3000
      });
      console.log(`✅ MongoDB Connected to Local Fallback: ${conn.connection.host}`);
    } catch (localError) {
      console.warn(`❌ Local fallback MongoDB connection failed: ${localError.message}`);
      console.warn(`⚠️ The FIXEN server will run in database-disconnected/mock mode.`);
    }
  }
};

module.exports = connectDB;