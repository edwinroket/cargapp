import 'package:dio/dio.dart';

import '../models/usuario_model.dart';
import 'usuario_remote_datasource.dart';

/// Real API implementation
class UsuarioRemoteDataSourceImpl implements UsuarioRemoteDataSource {
  final Dio dio;
  final String baseUrl;

  UsuarioRemoteDataSourceImpl({
    required this.dio,
    required this.baseUrl,
  });

  @override
  Future<List<UsuarioModel>> getUsuarios({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await dio.get(
        '$baseUrl/usuarios',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      final data = response.data as List;
      return data
          .map((u) => UsuarioModel.fromJson(u as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UsuarioModel> getUsuario(String id) async {
    try {
      final response = await dio.get('$baseUrl/usuarios/$id');
      return UsuarioModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UsuarioModel> createUsuario({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await dio.post(
        '$baseUrl/usuarios',
        data: {
          'email': email,
          'password': password,
          'role': role,
        },
      );
      return UsuarioModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<UsuarioModel> updateUsuario({
    required String id,
    String? role,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (role != null) data['role'] = role;
      if (status != null) data['status'] = status;

      final response = await dio.put(
        '$baseUrl/usuarios/$id',
        data: data,
      );
      return UsuarioModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<bool> deleteUsuario(String id) async {
    try {
      await dio.delete('$baseUrl/usuarios/$id');
      return true;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle DIO errors
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout';
      case DioExceptionType.badResponse:
        return e.response?.data['detail'] ?? 'Server error';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        return 'Network error';
    }
  }
}
