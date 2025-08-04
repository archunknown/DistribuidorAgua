import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoVenta {
  nueva,
  recarga,
  prestamo;

  String get displayName {
    switch (this) {
      case TipoVenta.nueva:
        return 'Garrafón Nuevo';
      case TipoVenta.recarga:
        return 'Recarga';
      case TipoVenta.prestamo:
        return 'Préstamo';
    }
  }

  static TipoVenta fromString(String value) {
    switch (value.toLowerCase()) {
      case 'nueva':
        return TipoVenta.nueva;
      case 'recarga':
        return TipoVenta.recarga;
      case 'prestamo':
        return TipoVenta.prestamo;
      default:
        return TipoVenta.recarga;
    }
  }
}

class VentaModel {
  final String id;
  final DateTime fechaHora;
  final String clienteId;
  final TipoVenta tipo;
  final int cantidad;
  final double precioUnitario;
  final double costoBidon;
  final double total;
  final String usuarioId;

  VentaModel({
    required this.id,
    required this.fechaHora,
    required this.clienteId,
    required this.tipo,
    required this.cantidad,
    required this.precioUnitario,
    required this.costoBidon,
    required this.total,
    required this.usuarioId,
  });

  // Constructor para crear desde Firestore
  factory VentaModel.fromFirestore(Map<String, dynamic> data, String id) {
    // Manejo seguro de referencias de DocumentReference
    String clienteId = '';
    if (data['cliRef'] != null) {
      if (data['cliRef'] is DocumentReference) {
        clienteId = (data['cliRef'] as DocumentReference).id;
      } else if (data['cliRef'] is String) {
        clienteId = data['cliRef'] as String;
      }
    }
    
    String usuarioId = '';
    if (data['usrRef'] != null) {
      if (data['usrRef'] is DocumentReference) {
        usuarioId = (data['usrRef'] as DocumentReference).id;
      } else if (data['usrRef'] is String) {
        usuarioId = data['usrRef'] as String;
      }
    }
    
    return VentaModel(
      id: id,
      fechaHora: (data['fh'] as Timestamp?)?.toDate() ?? DateTime.now(),
      clienteId: clienteId,
      tipo: TipoVenta.fromString(data['tp']?.toString() ?? 'recarga'),
      cantidad: (data['cant'] ?? 1) as int,
      precioUnitario: (data['pUnit'] ?? 0.0).toDouble(),
      costoBidon: (data['costBid'] ?? 0.0).toDouble(),
      total: (data['tot'] ?? 0.0).toDouble(),
      usuarioId: usuarioId,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'fh': Timestamp.fromDate(fechaHora),
      'cliRef': clienteId,
      'tp': tipo.name,
      'cant': cantidad,
      'pUnit': precioUnitario,
      'costBid': costoBidon,
      'tot': total,
      'usrRef': usuarioId,
    };
  }

  // Calcular ganancia
  double get ganancia {
    return total - (costoBidon * cantidad);
  }

  // Verificar si es venta del día actual
  bool get esVentaDeHoy {
    final hoy = DateTime.now();
    return fechaHora.year == hoy.year &&
           fechaHora.month == hoy.month &&
           fechaHora.day == hoy.day;
  }

  // Verificar si es venta de esta semana
  bool get esVentaDeLaSemana {
    final hoy = DateTime.now();
    final inicioSemana = hoy.subtract(Duration(days: hoy.weekday - 1));
    return fechaHora.isAfter(inicioSemana.subtract(const Duration(days: 1)));
  }

  // Verificar si es venta de este mes
  bool get esVentaDelMes {
    final hoy = DateTime.now();
    return fechaHora.year == hoy.year && fechaHora.month == hoy.month;
  }

  // Copiar con modificaciones
  VentaModel copyWith({
    String? id,
    DateTime? fechaHora,
    String? clienteId,
    TipoVenta? tipo,
    int? cantidad,
    double? precioUnitario,
    double? costoBidon,
    double? total,
    String? usuarioId,
  }) {
    return VentaModel(
      id: id ?? this.id,
      fechaHora: fechaHora ?? this.fechaHora,
      clienteId: clienteId ?? this.clienteId,
      tipo: tipo ?? this.tipo,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      costoBidon: costoBidon ?? this.costoBidon,
      total: total ?? this.total,
      usuarioId: usuarioId ?? this.usuarioId,
    );
  }

  @override
  String toString() {
    return 'VentaModel(id: $id, tipo: ${tipo.displayName}, cantidad: $cantidad, total: S/ $total)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VentaModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
