# FIXEN Ecosystem Guide Book

Welcome to the **FIXEN** guidebook. FIXEN is a premium, real-time, on-demand hyper-local home service matching platform (supporting categories like Electricians, Plumbers, and Carpenters). The ecosystem is built with a decoupled architecture featuring a performance-driven **Flutter client** (using Riverpod & GoRouter) and a robust **Node.js/Express backend** connected to **MongoDB** (with Mongoose ODM) with real-time **Socket.IO** rooms.

This guidebook covers the app's directory structure, key functionalities, installation instructions, and detailed guides for entering, updating, and removing MongoDB database records through various interfaces.

---

## Table of Contents
1. [System Architecture & Technology Stack](#system-architecture--technology-stack)
2. [Ecosystem Directory Structure](#ecosystem-directory-structure)
3. [App Functionalities Walkthrough](#app-func-walkthrough)
4. [MongoDB Database Guide: Inserting/Adding Data](#mongodb-database-guide-insertingadding-data)
5. [MongoDB Database Guide: Removing/Deleting Data (4 Different Methods)](#mongodb-database-guide-removingdeleting-data-4-different-methods)
6. [Installation & Setup](#installation--setup)

---

<a name="system-architecture--technology-stack"></a>
## 1. System Architecture & Technology Stack

The FIXEN application consists of:
*   **Flutter Mobile & Web Frontend:** Leverages a declarative design system, Flutter Riverpod for reactive state management, Hive for offline cache/session caching, `google_maps_flutter` for geo-spatial visualization, and a `socket_io_client` listener to broadcast live location and status changes.
*   **Node.js & Express.js Backend:** An MVC-patterned API server that implements JWT authentication, geocoding/geospatial worker queries, Socket.IO rooms for real-time bid updates, Razorpay payment gateway integration, and Swagger documentation.
*   **MongoDB & Mongoose ODM Layer:** A document-based database. Geolocation search utilizes MongoDB's native `$near` geospatial operator over `2dsphere` indexes on worker coordinates.

---

<a name="ecosystem-directory-structure"></a>
## 2. Ecosystem Directory Structure

```text
fixen-app/
├── lib/                             # Flutter Clean Architecture Directory
│   ├── app/                         # App level configs and environmental setups
│   │   └── config/env/env_config.dart
│   ├── common/                      # Common resources, styling and themes
│   │   └── themes/app_theme.dart
│   ├── data/                        # Shared datasources and cache helpers
│   │   └── local/hive_helper.dart
│   ├── models/                      # General entity models
│   ├── features/                    # Core modules (Presentation, Controllers, Repositories)
│   │   ├── authentication/          # User, Worker, Admin auth modules
│   │   ├── booking/                 # Customer booking requests pages & state management
│   │   ├── maps/                    # Google Maps integration & real-time tracking
│   │   ├── reviews/                 # Customer review page & comments
│   │   ├── user/                    # User profile & dashboard views
│   │   ├── worker/                  # Worker bid dashboard & job controller view
│   │   └── routes/                  # Navigation routes
│   │       └── app_router.dart      # Router mapping GoRouter paths
│   └── main.dart                    # Flutter execution entry point
│
├── server/                          # Node.js Backend Server Directory
│   ├── config/                      # Server configuration modules (DB, Socket, Firebase)
│   │   ├── database.js
│   │   └── socket.js
│   ├── controllers/                 # MVC Controllers handling database and events logic
│   │   ├── authController.js
│   │   ├── bookingController.js
│   │   ├── paymentController.js
│   │   ├── reviewController.js
│   │   └── adminController.js
│   ├── middleware/                  # Request verification & error handling
│   │   └── auth.js
│   ├── models/                      # Mongoose Schema Definitions
│   │   ├── User.js
│   │   ├── Worker.js
│   │   ├── Booking.js
│   │   ├── Review.js
│   │   ├── Payment.js
│   │   └── Commission.js
│   ├── routes/                      # Router endpoints matching controllers
│   │   └── bookingRoutes.js
│   ├── server.js                    # Express Application root & port listener
│   ├── swagger.json                 # Interactive Swagger API Specifications
│   └── package.json                 # Server scripts and npm dependencies
```

*   **Routing Configuration:** Navigates via [app_router.dart](file:///d:/fixen-app/lib/features/routes/app_router.dart).
*   **Database Config:** Manages connections via [database.js](file:///d:/fixen-app/server/config/database.js).
*   **Express Entrypoint:** Bootstraps Express routes via [server.js](file:///d:/fixen-app/server/server.js).

---

<a name="app-func-walkthrough"></a>
## 3. App Functionalities Walkthrough

### 🔑 Authentication Flows
*   **Customer Auth:** Register via name, email, password, and mobile number. Standard passwords are encrypted using `bcrypt` salting hooks prior to database insertion.
*   **Worker Auth:** Multi-step registration. In addition to credentials, workers upload Aadhar cards, driving licenses, and government IDs (e.g., `W12345`). They must choose a specific service category (`Electrician`, `Plumber`, or `Carpenter`).
*   **Admin Auth:** Grants access to the analytics dashboard and worker verification panels.

### 📍 Geospatial Worker Discovery
When a customer loads the dashboard or initiates a booking request, the server executes a dynamic search:
1.  Checks for active workers matching the category within a `5 KM` radius.
2.  If empty, expands search to `10 KM`.
3.  If still empty, expands up to `20 KM`.
4.  Returns sorted list by computed distance, rating, and verification flags.

### 📅 Booking & Bidding State Machine
The core business workflow runs sequentially on a strict state machine:
```mermaid
stateDiagram-v2
    [*] --> pending : Customer creates booking
    pending --> quotes_submitted : Workers submit quotes (price/ETA)
    quotes_submitted --> travelling : Customer accepts a Quote (Worker marked Busy)
    travelling --> arrived : Worker travels & marks arrival
    arrived --> progress : Worker verifies Customer OTP
    progress --> completed : Job finished
    completed --> paid : Customer pays (Cash / Razorpay Online)
    paid --> [*] : Review submitted (optional)
```

1.  **Request (`pending`):** Customer creates booking in [bookingController.js](file:///d:/fixen-app/server/controllers/bookingController.js#L15-L95). A random 4-digit OTP is generated. Socket.IO broadcasts `bookingRequest` event to matching category workers nearby.
2.  **Quote Submission:** Workers bid with an estimated price and ETA. Added to `booking.quotes` array.
3.  **Acceptance (`travelling`):** Customer reviews bids and accepts one. The chosen worker is marked `isBusy = true`.
4.  **OTP Verification (`progress`):** Worker arrives at location, requests OTP from client, and submits it to [verifyOtp](file:///d:/fixen-app/server/controllers/bookingController.js#L301-L353) to verify credentials.
5.  **Completion (`completed`):** Work finishes, PDF invoice is rendered.
6.  **Payment (`paid`):** Processed via Cash or online (Razorpay). 10% commission is calculated and logged. If worker's cumulative unpaid commission due exceeds ₹2000, their account is flagged `isBlocked = true` (auto-blocks booking requests until commission is cleared).
7.  **Review:** Customer submits rating (1 to 5 stars) and feedback. Mongoose recalculates the worker's average rating in [Review.js](file:///d:/fixen-app/server/models/Review.js).

---

<a name="mongodb-database-guide-insertingadding-data"></a>
## 4. MongoDB Database Guide: Inserting/Adding Data

Adding data to MongoDB is managed through Mongoose models in [models/](file:///d:/fixen-app/server/models/). Below are the implementation mappings for how data enters the database:

### A. User & Worker Document Creation
When registering a new user/worker, the app validates inputs and saves data.
*   **Controller Reference:** [authController.js](file:///d:/fixen-app/server/controllers/authController.js#L49-L78)
*   **Mongoose Method:** `Model.create()`
```javascript
// Example implementation for user registration
const user = await User.create({
  name: req.body.name,
  email: req.body.email,
  password: req.body.password, // Automatically hashed in pre-save hook
  mobileNumber: req.body.mobileNumber,
  address: req.body.address,
  profileImage: req.body.profileImage || ''
});
```

### B. Creating a Booking Request
Requires generating a new booking document containing coordinates indexable by a GeoJSON Point object.
*   **Controller Reference:** [bookingController.js](file:///d:/fixen-app/server/controllers/bookingController.js#L21-L33)
```javascript
const booking = await Booking.create({
  user: req.user.id,
  category: req.body.category,
  description: req.body.description,
  attachedImages: req.body.attachedImages || [],
  voiceRecordings: req.body.voiceRecordings || [],
  otp: generateOTP(),
  location: {
    type: 'Point',
    coordinates: [parseFloat(longitude), parseFloat(latitude)] // [lng, lat]
  },
  status: 'pending'
});
```

### C. Adding a Quote (Inserting Nested Arrays)
Bids are nested inside the parent Booking document rather than in a separate table.
*   **Controller Reference:** [bookingController.js](file:///d:/fixen-app/server/controllers/bookingController.js#L139-L145)
*   **Mongoose Method:** `array.push()` followed by `document.save()`
```javascript
const booking = await Booking.findById(bookingId);
booking.quotes.push({
  worker: req.user.id,
  price: parseFloat(price),
  eta: parseInt(eta)
});
await booking.save(); // Atomically commits the update to MongoDB
```

### D. Submitting Reviews & Logging Commissions
*   **Review Creation:** [reviewController.js](file:///d:/fixen-app/server/controllers/reviewController.js#L53-L59) uses `Review.create(...)` which triggers post-save mongoose hooks that aggregate the worker's average stars.
*   **Commission Logging:** [paymentController.js](file:///d:/fixen-app/server/controllers/paymentController.js#L59-L64) logs 10% on payment complete:
```javascript
await Commission.create({
  worker: workerId,
  amount: commissionAmount,
  weeklyEarnings: worker.weeklyEarnings,
  status: 'unpaid'
});
```

---

<a name="mongodb-database-guide-removingdeleting-data-4-different-methods"></a>
## 5. MongoDB Database Guide: Removing/Deleting Data (4 Different Methods)

To safeguard audit trails, the application code utilizes **Soft Deletions** (marking a booking status as `cancelled` or a worker's status as `suspended` / `isBlocked = true` rather than executing hard deletions). 

However, during development, maintenance, or GDPR compliance runs, developers and database administrators can use different methods to perform removals:

### Method 1: Programmatically using Mongoose ODM (Application Layer)
You can run script endpoints, tests, or seed scripts to purge database tables programmatically.

```javascript
const User = require('./models/User');
const Booking = require('./models/Booking');

// 1. Delete one document by ID (Hard Delete)
async function deleteUserById(userId) {
  const result = await User.findByIdAndDelete(userId);
  return result; // Returns the deleted document, or null if not found
}

// 2. Delete one document matching filter
async function deleteOneBooking(bookingId) {
  const result = await Booking.deleteOne({ _id: bookingId });
  return result.deletedCount; // Returns 1 if deleted
}

// 3. Delete multiple documents (e.g. purge cancelled test bookings)
async function clearCancelledBookings() {
  const result = await Booking.deleteMany({ status: 'cancelled' });
  console.log(`Cleared ${result.deletedCount} cancelled bookings.`);
}
```

> [!WARNING]
> Mongoose `deleteMany({})` without arguments drops **all** documents inside that collection. Use it with caution on production databases.

---

### Method 2: Command Line using MongoDB Shell (`mongosh`)
Connect to your MongoDB deployment locally or via remote URI inside your console terminal.

```bash
# Connect to local database
mongosh mongodb://127.0.0.1:27017/fixen

# Or connect to Atlas cluster
mongosh "mongodb+srv://cluster0.kxj0knn.mongodb.net/fixen" --username your_username
```

Once connected, run the following queries:

1.  **Delete a single user by Email:**
    ```javascript
    db.users.deleteOne({ email: "testworker@example.com" })
    ```
2.  **Delete all unpaid commission logs older than a specific date:**
    ```javascript
    db.commissions.deleteMany({ status: "unpaid", createdAt: { $lt: new ISODate("2026-01-01") } })
    ```
3.  **Drop an entire collection (e.g. Reviews table):**
    ```javascript
    db.reviews.drop()
    ```
4.  **Confirm deletion count of a query before execution:**
    ```javascript
    db.bookings.countDocuments({ status: "cancelled" })
    ```

---

### Method 3: Graphical Interface using MongoDB Compass
MongoDB Compass is the official GUI client for MongoDB. It provides a visual interface to query and modify data.

1.  **Open Compass** and insert your Connection String:
    `mongodb+srv://fixen_app:fixen@cluster0.kxj0knn.mongodb.net/` (as retrieved from your [.env](file:///d:/fixen-app/server/.env) config).
2.  Navigate to the left panel and click on the **`fixen`** database.
3.  Click on the target collection, for example, `bookings`.
4.  Apply a query filter inside the filter bar (e.g., `{ "status": "cancelled" }`) and click **Find**.
5.  Hover over the document cards or list rows. Click the **Trash/Bin** icon on the right side of the document.
6.  A confirmation dialog will appear. Click **Delete** to execute the action.

---

### Method 4: Cloud Interface using MongoDB Atlas Dashboard
If you are hosted in the cloud on Atlas:

1.  Log in to [MongoDB Atlas Console](https://cloud.mongodb.com/).
2.  Go to the **Database** tab under deployment, and click on your cluster (e.g. `Cluster0`).
3.  Navigate to the **Browse Collections** tab.
4.  Locate the database list on the left side, expand `fixen`, and select a collection (like `workers`).
5.  You can search for documents using the search query box.
6.  Click the **Edit/Pencil** icon to modify, or click the **Delete/Trash** icon next to any document to remove it permanently from the server cluster.

---

<a name="installation--setup"></a>
## 6. Installation & Setup

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.12.2 or higher)
*   [Node.js](https://nodejs.org/) (v16.0.0 or higher)
*   [MongoDB Shell (mongosh)](https://www.mongodb.com/try/download/shell) (optional, for DB inspections)

### A. Backend Setup
1.  Navigate into server:
    ```bash
    cd server
    ```
2.  Install packages:
    ```bash
    npm install
    ```
3.  Setup environment keys in `server/.env` (see template in [server/.env.example](file:///d:/fixen-app/server/.env.example)):
    ```env
    PORT=5000
    MONGODB_URI=mongodb+srv://fixen_app:fixen7115@cluster0.kxj0knn.mongodb.net/?appName=Cluster0
    JWT_SECRET=fixen_jwt_secret_key_change_me_in_production_987654321
    ```
4.  Run Server:
    *   Development mode: `npm run dev`
    *   Production mode: `npm start`
5.  Interactive API docs: Open browser to [http://localhost:5000/api-docs](http://localhost:5000/api-docs)

### B. Flutter Client Setup
1.  From the project root directory, install dependencies:
    ```bash
    flutter pub get
    ```
2.  Build generated serializations and endpoints (Freezed/Retrofit generators):
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
3.  Ensure your environment variables are configured in the root [.env](file:///d:/fixen-app/.env):
    ```env
    API_BASE_URL=http://localhost:5000/api/v1
    SOCKET_URL=http://localhost:5000
    ```
4.  Run the application:
    ```bash
    flutter run
    ```
