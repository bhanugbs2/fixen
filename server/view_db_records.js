const dns = require("node:dns");
dns.setDefaultResultOrder("ipv4first");
dns.setServers(["1.1.1.1", "8.8.8.8"]);

const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./models/User');
const Worker = require('./models/Worker');

dotenv.config();

const viewRecords = async () => {
  const mongoUri = process.env.MONGODB_URI;
  if (!mongoUri) {
    console.error('Error: MONGODB_URI is not defined in server/.env');
    process.exit(1);
  }

  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(mongoUri);
    console.log('Connected successfully!\n');

    console.log('======================================================================');
    console.log('👥 REGISTERED USERS');
    console.log('======================================================================');
    const users = await User.find({}).lean();
    if (users.length === 0) {
      console.log('No users found in database.');
    } else {
      console.table(users.map(u => ({
        ID: u._id.toString(),
        Name: u.name,
        Email: u.email,
        Mobile: u.mobileNumber,
        Address: u.address
      })));
    }
    console.log('======================================================================\n');

    console.log('======================================================================');
    console.log('🛠️ REGISTERED WORKERS');
    console.log('======================================================================');
    const workers = await Worker.find({}).lean();
    if (workers.length === 0) {
      console.log('No workers found in database.');
    } else {
      console.table(workers.map(w => ({
        'Worker ID': w.workerId,
        Name: w.name,
        Email: w.email,
        Mobile: w.mobileNumber,
        Service: w.service,
        Status: w.verificationStatus,
        Online: w.isOnline
      })));
    }
    console.log('======================================================================\n');

    await mongoose.connection.close();
  } catch (err) {
    console.error('Failed to retrieve database records:', err);
  }
};

viewRecords();
