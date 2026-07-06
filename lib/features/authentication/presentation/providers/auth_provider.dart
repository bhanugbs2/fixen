import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error, otpRequired }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? verificationMobileNumber;
  final String? pendingWorkerId;
  final String? selectedWorkerCategory;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.verificationMobileNumber,
    this.pendingWorkerId,
    this.selectedWorkerCategory,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    String? verificationMobileNumber,
    String? pendingWorkerId,
    String? selectedWorkerCategory,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      verificationMobileNumber: verificationMobileNumber ?? this.verificationMobileNumber,
      pendingWorkerId: pendingWorkerId ?? this.pendingWorkerId,
      selectedWorkerCategory: selectedWorkerCategory ?? this.selectedWorkerCategory,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.read(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState.initial());

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.autoLogin();
      if (user != null) {
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.login(email: email, password: password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> loginSocial(String provider) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.loginSocial(provider: provider);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String mobileNumber,
    required String address,
    String? profileImagePath,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.register(
        name: name,
        email: email,
        password: password,
        mobileNumber: mobileNumber,
        address: address,
        profileImagePath: profileImagePath,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  void selectWorkerCategory(String category) {
    state = state.copyWith(selectedWorkerCategory: category);
  }

  Future<void> requestWorkerLogin(String mobileNumber) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final mobile = await _repository.workerLogin(mobileNumber: mobileNumber);
      state = state.copyWith(
        status: AuthStatus.otpRequired,
        verificationMobileNumber: mobile,
        pendingWorkerId: mobileNumber,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<bool> verifyWorkerOtp(String otp) async {
    if (state.pendingWorkerId == null) return false;
    final mobileNumber = state.pendingWorkerId!;
    final category = state.selectedWorkerCategory;
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.verifyWorkerOtp(
        mobileNumber: mobileNumber,
        otp: otp,
        category: category,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.otpRequired,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> loginAdmin(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.adminLogin(email: email, password: password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    await _repository.logout();
    state = AuthState.initial().copyWith(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<bool> updateWorkerCategory(String category) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final user = await _repository.updateWorkerCategory(category: category);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        selectedWorkerCategory: category,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}
