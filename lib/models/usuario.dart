class Usuario {
  final int usuarioId;
  final String nombre;
  final String username;
  final String email;
  final String token;
  final String proveedorAuth;

  Usuario({
    required this.usuarioId,
    required this.nombre,
    required this.username,
    required this.email,
    required this.token,
    this.proveedorAuth = 'LOCAL',
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      usuarioId: json['usuarioId'],
      nombre: json['nombre'],
      username: json['username'],
      email: json['email'],
      token: json['token'],
      proveedorAuth: json['proveedorAuth'] ?? 'LOCAL',
    );
  }
}