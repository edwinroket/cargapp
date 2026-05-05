import '../entities/usuario.dart';

/// Usuario repository interface (domain layer)
abstract class UsuarioRepository {
  /// Get all usuarios with pagination
  Future<List<Usuario>> getUsuarios({
    int skip = 0,
    int limit = 100,
  });

  /// Get usuario by ID
  Future<Usuario?> getUsuario(String id);

  /// Create new usuario
  Future<Usuario> createUsuario({
    required String email,
    required String password,
    required String role,
  });

  /// Update usuario
  Future<Usuario?> updateUsuario({
    required String id,
    String? role,
    String? status,
  });

  /// Delete usuario
  Future<bool> deleteUsuario(String id);

  /// Check if usuario exists
  Future<bool> usuarioExists(String id);
}
