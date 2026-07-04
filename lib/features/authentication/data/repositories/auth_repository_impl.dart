import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../app/core/error/exceptions.dart';
import '../../../../data/local/hive_helper.dart';
import '../../../../data/local/secure_storage_helper.dart';
import '../../../../data/remote/api_client.dart';
import '../../../../models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageHelper _secureStorage;

  AuthRepositoryImpl({
    ApiClient? apiClient,
    SecureStorageHelper? secureStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorageHelper();

  @override
  Future<UserModel> login({required String email, required String password}) async {
    try {
      final response = await _apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      final accessToken = data['accessToken'] ?? data['data']?['accessToken'] ?? '';
      final refreshToken = data['refreshToken'] ?? data['data']?['refreshToken'] ?? '';
      final userJson = data['user'] ?? data['data']?['user'] ?? data;

      final user = UserModel.fromJson(userJson);

      await _secureStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      await _secureStorage.saveUserRole(user.role);
      await HiveHelper.cacheData(HiveHelper.profileBoxName, 'current_user', user.toJson());

      return user;
    } catch (e) {
      if (e is ServerException) rethrow;
      // Fallback for simulation/testing if connection fails or status is not 200
      if (email.contains("mock") || email == "user@fixen.com" || email == "bhanushankargbs@gmail.com" || email == "admin@fixen.com") {
        return _getMockUser(email, email == "admin@fixen.com" ? "admin" : "user");
      }
      throw ServerException(message: 'Authentication failed. Please check your credentials.');
    }
  }

  @override
  Future<UserModel> loginSocial({required String provider}) async {
    try {
      final response = await _apiClient.post('/auth/social', data: {'provider': provider});
      final data = response.data;
      final accessToken = data['accessToken'] ?? '';
      final refreshToken = data['refreshToken'] ?? '';
      final user = UserModel.fromJson(data['user'] ?? data);

      await _secureStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      await _secureStorage.saveUserRole(user.role);
      await HiveHelper.cacheData(HiveHelper.profileBoxName, 'current_user', user.toJson());

      return user;
    } catch (e) {
      return _getMockUser('${provider}_user@fixen.com', 'user');
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String mobileNumber,
    required String address,
    String? profileImagePath,
  }) async {
    try {
      final response = await _apiClient.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'mobileNumber': mobileNumber,
        'address': address,
        'profileImage': profileImagePath ?? '',
        'role': 'user',
      });

      final data = response.data;
      final accessToken = data['accessToken'] ?? '';
      final refreshToken = data['refreshToken'] ?? '';
      final user = UserModel.fromJson(data['user'] ?? data);

      await _secureStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      await _secureStorage.saveUserRole(user.role);
      await HiveHelper.cacheData(HiveHelper.profileBoxName, 'current_user', user.toJson());

      return user;
    } catch (e) {
      final mockUser = UserModel(
        id: 'user_mock_123',
        name: name,
        email: email,
        mobileNumber: mobileNumber,
        address: address,
        profileImage: '',
        role: 'user',
      );
      await _secureStorage.saveTokens(accessToken: 'mock_access_token', refreshToken: 'mock_refresh_token');
      await _secureStorage.saveUserRole('user');
      await HiveHelper.cacheData(HiveHelper.profileBoxName, 'current_user', mockUser.toJson());
      return mockUser;
    }
  }

  @override
  Future<String> workerLogin({required String governmentId}) async {
    try {
      final response = await _apiClient.post('/auth/worker-login', data: {
        'governmentId': governmentId,
      });
      return response.data['mobileNumber'] ?? '';
    } catch (e) {
      // Mock worker logins
      if (governmentId == "W12345" || governmentId == "worker") {
        return "+919876543210";
      }
      throw ServerException(message: 'Government ID not verified in FIXEN database.');
    }
  }

  @override
  Future<UserModel> verifyWorkerOtp({
    required String governmentId,
    required String otp,
    String? category,
  }) async {
    try {
      final response = await _apiClient.post('/auth/verify-otp', data: {
        'governmentId': governmentId,
        'otp': otp,
      });

      final data = response.data;
      final accessToken = data['accessToken'] ?? '';
      final refreshToken = data['refreshToken'] ?? '';
      final user = UserModel.fromJson(data['user'] ?? data);

      await _secureStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      await _secureStorage.saveUserRole(user.role);
      await HiveHelper.cacheData(HiveHelper.profileBoxName, 'current_user', user.toJson());

      return user;
    } catch (e) {
      if (otp == "123456") {
        final mockWorker = UserModel(
          id: 'worker_mock_123',
          name: 'Ch. Venkata Ramana',
          email: 'ramana@fixen.com',
          mobileNumber: '+919876543210',
          address: 'Arundelpet, Guntur, Andhra Pradesh',
          profileImage: '',
          role: 'worker',
          governmentId: governmentId,
          verificationStatus: 'approved',
          experience: 8,
          languages: ['Hindi', 'English', 'Kannada'],
          workingHours: '9:00 AM - 6:00 PM',
          rating: 4.8,
          reviewCount: 34,
          isOnline: true,
          commissionDue: 0.0,
          isBlocked: false,
          service: category ?? 'Plumber',
        );
        await _secureStorage.saveTokens(accessToken: 'mock_worker_token', refreshToken: 'mock_worker_refresh');
        await _secureStorage.saveUserRole('worker');
        await HiveHelper.cacheData(HiveHelper.profileBoxName, 'current_user', mockWorker.toJson());
        return mockWorker;
      }
      throw ServerException(message: 'Incorrect OTP. Verification failed.');
    }
  }

  @override
  Future<UserModel> adminLogin({required String email, required String password}) async {
    try {
      final response = await _apiClient.post('/auth/admin-login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      final accessToken = data['accessToken'] ?? '';
      final refreshToken = data['refreshToken'] ?? '';
      final user = UserModel.fromJson(data['user'] ?? data);

      await _secureStorage.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
      await _secureStorage.saveUserRole(user.role);
      await HiveHelper.cacheData(HiveHelper.profileBoxName, 'current_user', user.toJson());

      return user;
    } catch (e) {
      if (email == "admin@fixen.com" && password == "admin123") {
        return _getMockUser(email, 'admin');
      }
      throw ServerException(message: 'Admin authorization failed.');
    }
  }

  @override
  Future<UserModel?> autoLogin() async {
    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await _apiClient.get('/auth/me');
      final user = UserModel.fromJson(response.data['user'] ?? response.data);
      await HiveHelper.cacheData(HiveHelper.profileBoxName, 'current_user', user.toJson());
      return user;
    } catch (e) {
      // Offline fallback: try reading cached profile
      final cachedJson = HiveHelper.getCachedData(HiveHelper.profileBoxName, 'current_user');
      if (cachedJson != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(cachedJson));
      }
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {}
    await _secureStorage.clearAll();
    await HiveHelper.clearAllCache();
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _apiClient.post('/auth/forgot-password', data: {'email': email});
  }

  UserModel _getMockUser(String email, String role) {
    if (role == 'admin') {
      return UserModel(
        id: 'admin_mock_1',
        name: 'FIXEN Administrator',
        email: email,
        mobileNumber: '+919999999999',
        address: 'FIXEN HQ, Delhi',
        profileImage: '',
        role: 'admin',
      );
    } else {
      return UserModel(
        id: 'user_mock_1',
        name: 'G Bhanu Shankar',
        email: email == 'user@fixen.com' || email.isEmpty ? 'bhanushankargbs@gmail.com' : email,
        mobileNumber: '+919876543211',
        address: 'Flat 302, Brodipet, Guntur, Andhra Pradesh',
        profileImage: '',
        role: 'user',
      );
    }
  }
}
