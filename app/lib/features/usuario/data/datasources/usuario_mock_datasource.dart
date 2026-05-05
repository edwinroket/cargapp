import '../models/usuario_model.dart';
import 'usuario_remote_datasource.dart';

/// Mock implementation for testing/development
class UsuarioMockDataSource implements UsuarioRemoteDataSource {
  final usuarios = <String, UsuarioModel>{
    '1': const UsuarioModel(
      id: '1',
      email: 'admin@example.com',
      role: 'admin',
      status: 'activo',
    ),
    '2': const UsuarioModel(
      id: '2',
      email: 'user@example.com',
      role: 'usuario',
      status: 'activo',
    ),
  };

  @override
  Future<List<UsuarioModel>> getUsuarios({
    int skip = 0,
    int limit = 100,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate delay
    return usuarios.values.skip(skip).take(limit).toList();
  }

  @override
  Future<UsuarioModel> getUsuario(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final usuario = usuarios[id];
    if (usuario == null) {
      throw 'Usuario not found';
    }
    return usuario;
  }

  @override
  Future<UsuarioModel> createUsuario({
    required String email,
    required String password,
    required String role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newId = (usuarios.length + 1).toString();
    final newUsuario = UsuarioModel(
      id: newId,
      email: email,
      role: role,
      status: 'activo',
    );
    usuarios[newId] = newUsuario;
    return newUsuario;
  }

  @override
  Future<UsuarioModel> updateUsuario({
    required String id,
    String? role,
    String? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final usuario = usuarios[id];
    if (usuario == null) {
      throw 'Usuario not found';
    }
    final updated = UsuarioModel(
      id: usuario.id,
      email: usuario.email,
      role: role ?? usuario.role,
      status: status ?? usuario.status,
    );
    usuarios[id] = updated;
    return updated;
  }

  @override
  Future<bool> deleteUsuario(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!usuarios.containsKey(id)) {
      throw 'Usuario not found';
    }
    usuarios.remove(id);
    return true;
  }
}
