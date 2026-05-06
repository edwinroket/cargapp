import '../../domain/entities/usuario.dart';
import '../../domain/repositories/usuario_repository.dart';
import '../datasources/usuario_remote_datasource.dart';

/// Concrete implementation of UsuarioRepository
class UsuarioRepositoryImpl implements UsuarioRepository {
  final UsuarioRemoteDataSource remoteDataSource;

  UsuarioRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Usuario>> getUsuarios({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final models = await remoteDataSource.getUsuarios(
        skip: skip,
        limit: limit,
      );
      return models.map((m) => m.toDomain()).toList();
    } catch (e) {
      rethrow; // Handle in presentation layer
    }
  }

  @override
  Future<Usuario?> getUsuario(String id) async {
    try {
      final model = await remoteDataSource.getUsuario(id);
      return model.toDomain();
    } catch (e) {
      return null; // Or handle error appropriately
    }
  }

  @override
  Future<Usuario> createUsuario({
    required String email,
    required String password,
    required String role,
  }) async {
    final model = await remoteDataSource.createUsuario(
      email: email,
      password: password,
      role: role,
    );
    return model.toDomain();
  }

  @override
  Future<Usuario?> updateUsuario({
    required String id,
    String? role,
    String? status,
  }) async {
    try {
      final model = await remoteDataSource.updateUsuario(
        id: id,
        role: role,
        status: status,
      );
      return model.toDomain();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> deleteUsuario(String id) async {
    try {
      return await remoteDataSource.deleteUsuario(id);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> usuarioExists(String id) async {
    try {
      await remoteDataSource.getUsuario(id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
