const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const Worker = require('../models/Worker');

let io = null;

const initSocket = (server) => {
  io = new Server(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST']
    },
    transports: ['websocket', 'polling']
  });

  // Authentication Middleware for socket connections
  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      if (!token) {
        return next(new Error('Authentication error: Token missing'));
      }

      // Check if token has Bearer prefix or not
      const rawToken = token.startsWith('Bearer ') ? token.slice(7) : token;
      
      const decoded = jwt.verify(rawToken, process.env.JWT_SECRET || 'fixen_jwt_secret_key_change_me_in_production_987654321');
      socket.user = decoded;
      next();
    } catch (err) {
      return next(new Error('Authentication error: Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const { id, role } = socket.user;
    console.log(`Socket connected: ${id} as ${role}`);

    // Join room based on user/worker ID
    socket.join(id);
    console.log(`Socket ${socket.id} joined room: ${id}`);

    // Handle worker location updates
    socket.on('updateLocation', async (data) => {
      try {
        const { latitude, longitude } = data;
        if (latitude === undefined || longitude === undefined) return;

        // If user is a worker, update location in database
        if (role === 'worker') {
          await Worker.findByIdAndUpdate(id, {
            isOnline: true,
            location: {
              type: 'Point',
              coordinates: [parseFloat(longitude), parseFloat(latitude)]
            }
          });

          console.log(`Worker ${id} location updated: ${latitude}, ${longitude}`);

          // Broadcast to active booking customer if relevant
          // This will be triggered on a specific room or by query from active bookings
          const Booking = require('../models/Booking');
          const activeBooking = await Booking.findOne({
            worker: id,
            status: { $in: ['travelling', 'arrived', 'progress'] }
          });

          if (activeBooking) {
            io.to(activeBooking.user.toString()).emit('locationUpdate', {
              bookingId: activeBooking._id,
              latitude: parseFloat(latitude),
              longitude: parseFloat(longitude),
              distance: data.distance || 0,
              eta: data.eta || 0
            });
            console.log(`Broadcasted location to client ${activeBooking.user}`);
          }
        }
      } catch (err) {
        console.error('Socket updateLocation error:', err.message);
      }
    });

    socket.on('disconnect', () => {
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });

  return io;
};

const getIO = () => {
  if (!io) {
    throw new Error('Socket.io has not been initialized');
  }
  return io;
};

// Helper methods to emit to specific rooms/users
const emitToUser = (userId, event, data) => {
  if (io) {
    io.to(userId.toString()).emit(event, data);
  }
};

const emitToRoom = (roomName, event, data) => {
  if (io) {
    io.to(roomName).emit(event, data);
  }
};

module.exports = {
  initSocket,
  getIO,
  emitToUser,
  emitToRoom
};
