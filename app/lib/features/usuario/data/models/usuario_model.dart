import '../../../domain/entities/usuario.dart';

/// Usuario data model (JSON serialization)
class UsuarioModel {
  final String id;
  final String email;
  final String role;
  final String status;

  const UsuarioModel({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
  });

  /// Convert from JSON
  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'usuario',
      status: json['status'] as String? ?? 'activo',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'status': status,
      };

  /// Convert to domain entity
  Usuario toDomain() => Usuario(
        id: id,
        email: email,
        role: role,
        status: status,
      );

  /// Create from domain entity
  factory UsuarioModel.fromDomain(Usuario usuario) {
    return UsuarioModel(
      id: usuario.id,
      email: usuario.email,
      role: usuario.role,
      status: usuario.status,
    );
  }
}
