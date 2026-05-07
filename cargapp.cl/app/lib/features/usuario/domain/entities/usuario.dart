/// Usuario domain entity
class Usuario {
  final String id;
  final String email;
  final String role;
  final String status;

  const Usuario({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
  });

  /// Create a copy with modifications
  Usuario copyWith({
    String? id,
    String? email,
    String? role,
    String? status,
  }) {
    return Usuario(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }

  @override
  String toString() =>
      'Usuario(id: $id, email: $email, role: $role, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Usuario &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          role == other.role &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^ email.hashCode ^ role.hashCode ^ status.hashCode;
}
