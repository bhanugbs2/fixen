import 'package:dio/dio.dart';
import '../../app/config/env/env_config.dart';
import '../../app/core/error/exceptions.dart';
import '../local/secure_storage_helper.dart';

class ApiClient {
  late final Dio _dio;
  final SecureStorageHelper _secureStorage;

  ApiClient({SecureStorageHelper? secureStorage, Dio? dio})
      : _secureStorage = secureStorage ?? SecureStorageHelper() {
    _dio = dio ?? Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Check if unauthorized and have refresh token
          if (error.response?.statusCode == 401) {
            final refreshToken = await _secureStorage.getRefreshToken();
            if (refreshToken != null && refreshToken.isNotEmpty) {
              try {
                // Perform token refresh request
                final refreshDio = Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl));
                final response = await refreshDio.post(
                  '/auth/refresh',
                  data: {'refreshToken': refreshToken},
                );

                if (response.statusCode == 200 || response.statusCode == 201) {
                  final data = response.data;
                  final newAccessToken = data['accessToken'] ?? data['data']?['accessToken'];
                  final newRefreshToken = data['refreshToken'] ?? data['data']?['refreshToken'];

                  if (newAccessToken != null && newRefreshToken != null) {
                    await _secureStorage.saveTokens(
                      accessToken: newAccessToken,
                      refreshToken: newRefreshToken,
                    );

                    // Update headers and retry request
                    error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                    final clonedRequest = await _dio.fetch(error.requestOptions);
                    return handler.resolve(clonedRequest);
                  }
                }
              } catch (e) {
                // If refresh token fails, clear storage and bubble up error
                await _secureStorage.clearTokens();
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    try {
      return await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return NetworkException(message: 'Connection timed out. Please check your internet connection.');
    }

    final response = error.response;
    if (response != null) {
      final data = response.data;
      String message = 'Something went wrong';
      if (data is Map) {
        message = data['message'] ?? data['error'] ?? message;
      }
      return ServerException(message: message, statusCode: response.statusCode);
    }

    return ServerException(message: error.message ?? 'An unknown error occurred.');
  }
}
