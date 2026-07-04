# FIXEN Backend - Express.js & MongoDB Server

This is the backend server implementation for the FIXEN service application, designed to integrate with the FIXEN Flutter application. Built using MVC architecture, this server hosts REST APIs and real-time Socket.IO protocols to handle authentication, booking flows, geo-spatial locations, notifications, reviews, payments, and admin statistics.

---

## Technology Stack

- **Runtime Environment:** Node.js
- **Web Framework:** Express.js
- **Database Layer:** MongoDB with Mongoose ODM
- **Real-Time Layer:** Socket.IO
- **Security:** Helmet, CORS, BCrypt (Password Hashing), JSON Web Tokens (JWT)
- **Validation:** Express Validator
- **Document Uploader:** Multer
- **API Specs:** Swagger UI

---

## Directory Structure

```text
server/
├── package.json
├── server.js
├── .env.example
├── .env
├── swagger.json
├── postman_collection.json
├── README.md
│
├── config/
│   ├── database.js
│   ├── socket.js
│   └── firebase.js
│
├── middleware/
│   ├── auth.js
│   ├── upload.js
│   ├── validation.js
│   └── errorHandler.js
│
├── models/
│   ├── User.js
│   ├── Worker.js
│   ├── Booking.js
│   ├── Review.js
│   ├── Notification.js
│   ├── Payment.js
│   ├── Commission.js
│   └── Admin.js
│
├── controllers/
│   ├── authController.js
│   ├── workerController.js
│   ├── bookingController.js
│   ├── mapController.js
│   ├── reviewController.js
│   ├── paymentController.js
│   ├── notificationController.js
│   └── adminController.js
│
├── routes/
│   ├── authRoutes.js
│   ├── workerRoutes.js
│   ├── bookingRoutes.js
│   ├── reviewRoutes.js
│   ├── mapRoutes.js
│   ├── paymentRoutes.js
│   ├── notificationRoutes.js
│   └── adminRoutes.js
│
└── uploads/
```

---

## Installation & Setup

### 1. Prerequisites
- [Node.js](https://nodejs.org/) (v16.0.0 or higher recommended)
- [MongoDB](https://www.mongodb.com/) (running locally on port `27017` or a MongoDB Atlas URI)

### 2. Install dependencies
Navigate to the server directory and run:
```bash
npm install
```

### 3. Setup configurations
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Ensure your MongoDB URI is set correctly. By default, it is configured to use:
`MONGODB_URI=mongodb://127.0.0.1:27017/fixen`

### 4. Running the server
- **For Development (with Nodemon):**
  ```bash
  npm run dev
  ```
- **For Production:**
  ```bash
  npm start
  ```

---

## Features Implemented

1. **Dual Response Model (Strict Flutter Client Compatibility):**
   Our APIs return credentials and profiles both at the root level and inside a nested `data` object to remain fully compatible with all Dart client serializers:
   ```json
   {
     "success": true,
     "message": "Login successful",
     "accessToken": "...",
     "user": { ... },
     "data": {
       "accessToken": "...",
       "user": { ... }
     }
   }
   ```
2. **Dynamic Geo-Spatial Workers Query:**
   `GET /api/v1/maps/nearby-workers` searches dynamically for workers within the specified radius:
   - Evaluates `5 KM` radius.
   - If empty, expands to `10 KM`.
   - If empty, expands to `20 KM`.
   - Returns workers sorted by computed distance, rating, and verification status.
3. **Interactive Booking State Machine:**
   Booking workflow: `Request -> Quote Submission (Worker) -> Accept (Customer) -> Travel & Arrival (Worker) -> OTP Verify -> In Progress -> Complete -> Pay (Cash/Online)`.
4. **Real-time Live Location Broadcaster:**
   Utilizing Socket.IO rooms, when a worker updates their location via `updateLocation` socket event, the server automatically projects coordinates to the corresponding active customer using the `locationUpdate` event.
5. **Admin Operations:**
   Admin portal handles verifying worker registrations, blocking/unblocking accounts, collecting commission logs, and exporting analytics metrics.

---

## API Documentation

The server exposes interactive Swagger UI docs. Run the server and navigate in your browser to:
[http://localhost:5000/api-docs](http://localhost:5000/api-docs)

---

## Postman Collection

Import `postman_collection.json` located in the root of the server folder directly into your Postman Workspace to start triggering REST requests!
