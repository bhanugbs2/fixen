const dns = require("node:dns");
dns.setDefaultResultOrder("ipv4first");
dns.setServers(["1.1.1.1", "8.8.8.8"]);

const mongoose = require('mongoose');
const dotenv = require('dotenv');
const Worker = require('./models/Worker');

dotenv.config();

const run = async () => {
  const args = process.argv.slice(2);
  if (args.length !== 5 && args.length !== 6) {
    console.log('Usage:');
    console.log('  Auto-generate ID:  node register_natural_worker.js <Name> <Email> <MobileNumber> <Address> <Service>');
    console.log('  Specify custom ID: node register_natural_worker.js <WorkerID> <Name> <Email> <MobileNumber> <Address> <Service>');
    console.log('\nExample (Auto-generate):');
    console.log('  node register_natural_worker.js "John Doe" "john@example.com" "+919876543222" "123 Main St, Guntur" "Electrician"');
    console.log('\nExample (Specify custom):');
    console.log('  node register_natural_worker.js "WKR001" "John Doe" "john@example.com" "+919876543222" "123 Main St, Guntur" "Electrician"');
    process.exit(1);
  }

  let workerId, name, email, mobileNumber, address, service;

  try {
    const mongoUri = process.env.MONGODB_URI;
    if (!mongoUri) {
      console.error('Error: MONGODB_URI is not defined in server/.env');
      process.exit(1);
    }

    console.log('Connecting to MongoDB...');
    await mongoose.connect(mongoUri);
    console.log('Connected!');

    if (args.length === 5) {
      [name, email, mobileNumber, address, service] = args;
      // Auto-generate workerId
      const latestWorker = await Worker.findOne({ workerId: /^WKR\d{3}$/ }).sort({ workerId: -1 });
      let nextNum = 1;
      if (latestWorker) {
        const match = latestWorker.workerId.match(/^WKR(\d{3})$/);
        if (match) {
          nextNum = parseInt(match[1]) + 1;
        }
      }
      workerId = `WKR${nextNum.toString().padStart(3, '0')}`;
    } else {
      // Support either [workerId, name...] or [name... workerId] if they put workerId last.
      if (args[0].startsWith('WKR') && args[0].length === 6) {
        [workerId, name, email, mobileNumber, address, service] = args;
      } else if (args[5].startsWith('WKR') && args[5].length === 6) {
        [name, email, mobileNumber, address, service, workerId] = args;
      } else {
        [workerId, name, email, mobileNumber, address, service] = args;
      }

      if (!/^WKR\d{3}$/.test(workerId)) {
        console.error('Error: Worker ID must be in the format WKR### (e.g., WKR001)');
        await mongoose.connection.close();
        process.exit(1);
      }
    }

    if (!['Electrician', 'Plumber', 'Carpenter'].includes(service)) {
      console.error('Error: Service category must be one of: Electrician, Plumber, Carpenter');
      await mongoose.connection.close();
      process.exit(1);
    }

    // Check if workerId exists
    const existingId = await Worker.findOne({ workerId });
    if (existingId) {
      console.error(`Error: A worker with Worker ID ${workerId} is already registered!`);
      await mongoose.connection.close();
      process.exit(1);
    }

    // Check if email exists
    const existingEmail = await Worker.findOne({ email });
    if (existingEmail) {
      console.error(`Error: A worker with email ${email} is already registered!`);
      await mongoose.connection.close();
      process.exit(1);
    }

    // Create the worker
    const worker = await Worker.create({
      workerId,
      name,
      email,
      password: 'worker123_default_password',
      mobileNumber,
      address,
      service,
      verificationStatus: 'approved', // Pre-approve so they can log in
      isOnline: true,
      rating: 5.0,
      reviewCount: 0
    });

    console.log('\n======================================================');
    console.log('🎉 REAL WORKER REGISTERED SUCCESSFULLY!');
    console.log('======================================================');
    console.log(`Worker ID (Use this to Login): ${worker.workerId}`);
    console.log(`Name:                          ${worker.name}`);
    console.log(`Email:                         ${worker.email}`);
    console.log(`Mobile:                        ${worker.mobileNumber}`);
    console.log(`Service:                       ${worker.service}`);
    console.log(`Status:                        ${worker.verificationStatus}`);
    console.log('======================================================\n');

    await mongoose.connection.close();
  } catch (err) {
    console.error('Registration failed:', err);
  }
};

run();
