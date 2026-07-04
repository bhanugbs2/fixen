import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../authentication/presentation/pages/admin_login_page.dart';
import '../authentication/presentation/pages/forgot_password_page.dart';
import '../authentication/presentation/pages/login_page.dart';
import '../authentication/presentation/pages/register_page.dart';
import '../authentication/presentation/pages/role_selection_page.dart';
import '../authentication/presentation/pages/splash_page.dart';
import '../authentication/presentation/pages/worker_login_page.dart';
import '../authentication/presentation/pages/worker_otp_page.dart';
import '../authentication/presentation/pages/worker_work_selection_page.dart';
import '../user/presentation/pages/user_dashboard_page.dart';
import '../worker/presentation/pages/worker_dashboard_page.dart';
import '../admin/presentation/pages/admin_dashboard_page.dart';
import '../booking/presentation/pages/request_service_page.dart';
import '../maps/presentation/pages/live_tracking_page.dart';
import '../reviews/presentation/pages/review_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/worker-login',
      builder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? 'Electrician';
        return WorkerLoginPage(category: category);
      },
    ),
    GoRoute(
      path: '/worker-otp',
      builder: (context, state) => const WorkerOtpPage(),
    ),
    GoRoute(
      path: '/admin-login',
      builder: (context, state) => const AdminLoginPage(),
    ),
    GoRoute(
      path: '/user-dashboard',
      builder: (context, state) => const UserDashboardPage(),
    ),
    GoRoute(
      path: '/worker-dashboard',
      builder: (context, state) => const WorkerDashboardPage(),
    ),
    GoRoute(
      path: '/worker-work-selection',
      builder: (context, state) => const WorkerWorkSelectionPage(),
    ),
    GoRoute(
      path: '/admin-dashboard',
      builder: (context, state) => const AdminDashboardPage(),
    ),
    GoRoute(
      path: '/request-service',
      builder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? 'Electrician';
        return RequestServicePage(category: category);
      },
    ),
    GoRoute(
      path: '/live-tracking/:bookingId',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId'] ?? 'mock_booking';
        return LiveTrackingPage(bookingId: bookingId);
      },
    ),
    GoRoute(
      path: '/reviews/:bookingId',
      builder: (context, state) {
        final bookingId = state.pathParameters['bookingId'] ?? 'mock_booking';
        return ReviewPage(bookingId: bookingId);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Routing error: ${state.error}'),
    ),
  ),
);
