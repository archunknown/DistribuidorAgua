import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String usuario;
  final String pass;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String rol;
  final DateTime fechaCreacion;

  UserModel({
    required this.id,
    required this.usuario,
    required this.pass,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.rol,
    required this.fechaCreacion,
  });

  // Constructor para crear desde Firestore
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      usuario: data['usuario'] ?? '',
      pass: data['pass'] ?? '',
      nombre: data['nom'] ?? '',
      apellidoPaterno: data['apePat'] ?? '',
      apellidoMaterno: data['apeMat'] ?? '',
      rol: data['rol'] ?? '',
      fechaCreacion: data['fhCre']?.toDate() ?? DateTime.now(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'usuario': usuario,
      'pass': pass,
      'nom': nombre,
      'apePat': apellidoPaterno,
      'apeMat': apellidoMaterno,
      'rol': rol,
      'fhCre': fechaCreacion,
    };
  }

  // Getter para nombre completo
  String get nombreCompleto {
    return '$nombre $apellidoPaterno $apellidoMaterno'.trim();
  }

  // Getter para iniciales
  String get iniciales {
    String inicialNombre = nombre.isNotEmpty ? nombre[0].toUpperCase() : '';
    String inicialApellido = apellidoPaterno.isNotEmpty ? apellidoPaterno[0].toUpperCase() : '';
    return '$inicialNombre$inicialApellido';
  }

  // Verificar si es admin
  bool get isAdmin => rol.toLowerCase() == 'admin' || rol.toLowerCase() == 'administrador';

  // Verificar si es ayudante
  bool get isAyudante => rol.toLowerCase() == 'ayudante';

  // Copiar con modificaciones
  UserModel copyWith({
    String? id,
    String? usuario,
    String? pass,
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? rol,
    DateTime? fechaCreacion,
  }) {
    return UserModel(
      id: id ?? this.id,
      usuario: usuario ?? this.usuario,
      pass: pass ?? this.pass,
      nombre: nombre ?? this.nombre,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      rol: rol ?? this.rol,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, usuario: $usuario, nombreCompleto: $nombreCompleto, rol: $rol)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
