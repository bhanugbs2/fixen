const dns = require("node:dns");
dns.setDefaultResultOrder("ipv4first");
dns.setServers(["1.1.1.1", "8.8.8.8"]);

const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./models/User');

dotenv.config();

const run = async () => {
  const args = process.argv.slice(2);
  if (args.length < 5) {
    console.log('Usage: node register_natural_customer.js <Name> <Email> <Password> <MobileNumber> <Address>');
    console.log('Example: node register_natural_customer.js "Bhanu Prasad" "bhanu.cust@gmail.com" "password123" "+919876543299" "rajiv gandhi nagar 6/7th line, Guntur"');
    process.exit(1);
  }

  const [name, email, password, mobileNumber, address] = args;

  try {
    const mongoUri = process.env.MONGODB_URI;
    if (!mongoUri) {
      console.error('Error: MONGODB_URI is not defined in server/.env');
      process.exit(1);
    }

    console.log('Connecting to MongoDB...');
    await mongoose.connect(mongoUri);
    console.log('Connected!');

    // Check if user exists
    const existing = await User.findOne({ email });
    if (existing) {
      console.error(`Error: A customer with email ${email} is already registered!`);
      await mongoose.connection.close();
      process.exit(1);
    }

    // Create the customer
    const user = await User.create({
      name,
      email,
      password,
      mobileNumber,
      address,
      role: 'user'
    });

    console.log('\n======================================================');
    console.log('🎉 REAL CUSTOMER REGISTERED SUCCESSFULLY!');
    console.log('======================================================');
    console.log(`Customer ID:  ${user._id}`);
    console.log(`Name:         ${user.name}`);
    console.log(`Email:        ${user.email}`);
    console.log(`Mobile:       ${user.mobileNumber}`);
    console.log(`Address:      ${user.address}`);
    console.log('======================================================\n');

    await mongoose.connection.close();
  } catch (err) {
    console.error('Registration failed:', err);
  }
};

run();
