import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/usuario_mock_datasource.dart';
import '../../data/repositories/usuario_repository_impl.dart';
import '../../domain/entities/usuario.dart';
import '../../domain/repositories/usuario_repository.dart';

// ============================================================================
// DATASOURCE PROVIDERS
// ============================================================================

/// Provide mock datasource (for testing)
final usuarioMockDataSourceProvider = Provider((ref) {
  return UsuarioMockDataSource();
});

/// Provide real API datasource (needs dio and baseUrl)
final usuarioRemoteDataSourceProvider = Provider((ref) {
  // TODO: Inject Dio from parent provider
  throw UnimplementedError('Configure Dio provider first');
});

// ============================================================================
// REPOSITORY PROVIDER
// ============================================================================

/// Provide usuario repository (uses mock by default)
final usuarioRepositoryProvider = Provider<UsuarioRepository>((ref) {
  final mockDataSource = ref.watch(usuarioMockDataSourceProvider);
  return UsuarioRepositoryImpl(remoteDataSource: mockDataSource);
});

// ============================================================================
// STATE NOTIFIERS
// ============================================================================

/// Usuario list state
class UsuariosListState {
  final List<Usuario> usuarios;
  final bool isLoading;
  final String? error;

  UsuariosListState({
    this.usuarios = const [],
    this.isLoading = false,
    this.error,
  });

  UsuariosListState copyWith({
    List<Usuario>? usuarios,
    bool? isLoading,
    String? error,
  }) {
    return UsuariosListState(
      usuarios: usuarios ?? this.usuarios,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing usuarios list
class UsuariosListNotifier extends StateNotifier<UsuariosListState> {
  final UsuarioRepository repository;

  UsuariosListNotifier(this.repository)
      : super(UsuariosListState());

  /// Load all usuarios
  Future<void> loadUsuarios({int skip = 0, int limit = 100}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final usuarios = await repository.getUsuarios(
        skip: skip,
        limit: limit,
      );
      state = state.copyWith(
        usuarios: usuarios,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create new usuario
  Future<Usuario?> createUsuario({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final newUsuario = await repository.createUsuario(
        email: email,
        password: password,
        role: role,
      );
      
      // Add to list
      state = state.copyWith(
        usuarios: [...state.usuarios, newUsuario],
      );
      
      return newUsuario;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Update usuario
  Future<Usuario?> updateUsuario({
    required String id,
    String? role,
    String? status,
  }) async {
    try {
      final updated = await repository.updateUsuario(
        id: id,
        role: role,
        status: status,
      );

      if (updated != null) {
        final newList = state.usuarios.map((u) {
          return u.id == id ? updated : u;
        }).toList();
        state = state.copyWith(usuarios: newList);
      }

      return updated;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Delete usuario
  Future<bool> deleteUsuario(String id) async {
    try {
      final success = await repository.deleteUsuario(id);
      if (success) {
        final newList = state.usuarios
            .where((u) => u.id != id)
            .toList();
        state = state.copyWith(usuarios: newList);
      }
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider for usuarios list state and operations
final usuariosListProvider =
    StateNotifierProvider<UsuariosListNotifier, UsuariosListState>((ref) {
  final repository = ref.watch(usuarioRepositoryProvider);
  return UsuariosListNotifier(repository);
});

/// Provider for single usuario
final usuarioProvider = FutureProvider.family<Usuario?, String>((ref, id) async {
  final repository = ref.watch(usuarioRepositoryProvider);
  return repository.getUsuario(id);
});

/// Provider for checking if usuario exists
final usuarioExistsProvider =
    FutureProvider.family<bool, String>((ref, id) async {
  final repository = ref.watch(usuarioRepositoryProvider);
  return repository.usuarioExists(id);
});
