import '../models/usuario_model.dart';

/// Abstraction layer for data sources
abstract class UsuarioRemoteDataSource {
  /// Get all usuarios from API
  Future<List<UsuarioModel>> getUsuarios({
    int skip = 0,
    int limit = 100,
  });

  /// Get usuario from API
  Future<UsuarioModel> getUsuario(String id);

  /// Create usuario on API
  Future<UsuarioModel> createUsuario({
    required String email,
    required String password,
    required String role,
  });

  /// Update usuario on API
  Future<UsuarioModel> updateUsuario({
    required String id,
    String? role,
    String? status,
  });

  /// Delete usuario from API
  Future<bool> deleteUsuario(String id);
}
