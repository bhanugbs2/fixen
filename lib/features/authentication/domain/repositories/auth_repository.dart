import '../../../../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> loginSocial({required String provider});
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String mobileNumber,
    required String address,
    String? profileImagePath,
  });
  Future<String> workerLogin({required String governmentId}); // Returns registered mobile number
  Future<UserModel> verifyWorkerOtp({required String governmentId, required String otp});
  Future<UserModel> adminLogin({required String email, required String password});
  Future<UserModel?> autoLogin();
  Future<void> logout();
  Future<void> forgotPassword(String email);
}
