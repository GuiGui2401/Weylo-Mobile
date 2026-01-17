import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/exceptions.dart';
import 'storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;
  final StorageService _storage = StorageService();

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            print('REQUEST[${options.method}] => PATH: ${options.path}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('======= API ERROR =======');
            print('STATUS: ${error.response?.statusCode}');
            print('PATH: ${error.requestOptions.path}');
            print('METHOD: ${error.requestOptions.method}');
            print('ERROR TYPE: ${error.type}');
            print('ERROR MESSAGE: ${error.message}');
            if (error.response?.data != null) {
              print('RESPONSE DATA: ${error.response?.data}');
            }
            print('========================');
          }
          return handler.next(error);
        },
      ),
    );
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<T>> uploadFile<T>(
    String path, {
    required FormData data,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        onSendProgress: onSendProgress,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  AppException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(message: 'Délai de connexion dépassé');
      case DioExceptionType.connectionError:
        return NetworkException(message: 'Impossible de se connecter au serveur');
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
      case DioExceptionType.cancel:
        return AppException(message: 'Requête annulée');
      default:
        return AppException(message: 'Une erreur est survenue');
    }
  }

  AppException _handleResponseError(Response? response) {
    if (response == null) {
      return ServerException(message: 'Réponse du serveur invalide');
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;
    String message = 'Une erreur est survenue';

    if (data is Map<String, dynamic>) {
      message = data['message'] ?? message;
    }

    // Ignore 403 errors from Pusher/Reverb WebSocket authentication
    // These are expected during WebSocket connections and shouldn't be shown to users
    if (statusCode == 403 &&
        (response.requestOptions.path.contains('broadcasting/auth') ||
         response.requestOptions.path.contains('pusher') ||
         response.requestOptions.path.contains('reverb'))) {
      if (kDebugMode) print('WebSocket 403 error suppressed (expected during auth)');
      // Return a silent exception that won't show to users
      return AppException(message: '', statusCode: 403);
    }

    switch (statusCode) {
      case 400:
        return AppException(message: message, statusCode: 400);
      case 401:
        return AuthException(message: message);
      case 403:
        return ForbiddenException(message: message);
      case 404:
        return NotFoundException(message: message);
      case 422:
        Map<String, dynamic>? errors;
        if (data is Map<String, dynamic> && data['errors'] != null) {
          errors = data['errors'];
        }
        return ValidationException(message: message, errors: errors);
      case 429:
        return RateLimitException(message: message);
      case 503:
        return MaintenanceException(message: message);
      default:
        return ServerException(message: message, statusCode: statusCode);
    }
  }
}
