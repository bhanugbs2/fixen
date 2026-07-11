const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./models/User');

dotenv.config();

const run = async () => {
  const mongoUri = process.env.MONGODB_URI;
  if (!mongoUri) {
    console.error('Error: MONGODB_URI is not defined in server/.env');
    process.exit(1);
  }

  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(mongoUri);
    console.log('Connected!');

    // Update Bhanu Prasad or Bhanu Prakash to Bhanu Shankar
    const res = await User.updateMany(
      { name: { $in: ['Bhanu Prasad', 'Bhanu Prakash'] } },
      { name: 'Bhanu Shankar' }
    );
    console.log(`Updated ${res.modifiedCount} user records.`);

    await mongoose.connection.close();
    console.log('Database connection closed.');
  } catch (err) {
    console.error('Update failed:', err);
    process.exit(1);
  }
};

run();
