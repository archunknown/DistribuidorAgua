import 'package:cloud_firestore/cloud_firestore.dart';

class ClienteModel {
  final String id;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String distrito;
  final String referencia;
  final String? telefono;
  final String creadoPorId;
  final DateTime fechaCreacion;

  ClienteModel({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.distrito,
    required this.referencia,
    this.telefono,
    required this.creadoPorId,
    required this.fechaCreacion,
  });

  // Constructor para crear desde Firestore
  factory ClienteModel.fromFirestore(Map<String, dynamic> data, String id) {
    // Manejo seguro de la referencia crePor
    String creadoPorId = '';
    if (data['crePor'] != null) {
      if (data['crePor'] is DocumentReference) {
        creadoPorId = (data['crePor'] as DocumentReference).id;
      } else if (data['crePor'] is String) {
        creadoPorId = data['crePor'] as String;
      }
    }
    
    return ClienteModel(
      id: id,
      nombre: data['nom']?.toString() ?? '',
      apellidoPaterno: data['apePat']?.toString() ?? '',
      apellidoMaterno: data['apeMat']?.toString() ?? '',
      distrito: data['distrito']?.toString() ?? '',
      referencia: data['referencia']?.toString() ?? '',
      telefono: data['tel']?.toString(),
      creadoPorId: creadoPorId,
      fechaCreacion: (data['fhCre'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nombre,
      'apePat': apellidoPaterno,
      'apeMat': apellidoMaterno,
      'distrito': distrito,
      'referencia': referencia,
      'tel': telefono,
      'crePor': creadoPorId,
      'fhCre': Timestamp.fromDate(fechaCreacion),
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

  // Getter para dirección completa
  String get direccionCompleta {
    return '$distrito - $referencia'.trim();
  }

  // Copiar con modificaciones
  ClienteModel copyWith({
    String? id,
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? distrito,
    String? referencia,
    String? telefono,
    String? creadoPorId,
    DateTime? fechaCreacion,
  }) {
    return ClienteModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      distrito: distrito ?? this.distrito,
      referencia: referencia ?? this.referencia,
      telefono: telefono ?? this.telefono,
      creadoPorId: creadoPorId ?? this.creadoPorId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  @override
  String toString() {
    return 'ClienteModel(id: $id, nombreCompleto: $nombreCompleto, distrito: $distrito)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClienteModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
