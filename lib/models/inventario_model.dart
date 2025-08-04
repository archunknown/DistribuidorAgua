import 'package:cloud_firestore/cloud_firestore.dart';

class InventarioModel {
  final String id;
  final int stockTotal;
  final int stockDisponible;
  final DateTime fechaActualizacion;
  final int? bidonesVendidos; // Bidones vendidos (garrafón nuevo)
  final int? bidonesPrestados; // Bidones prestados (préstamo + agua)

  InventarioModel({
    required this.id,
    required this.stockTotal,
    required this.stockDisponible,
    required this.fechaActualizacion,
    this.bidonesVendidos,
    this.bidonesPrestados,
  });

  // Constructor para crear desde Firestore
  factory InventarioModel.fromFirestore(Map<String, dynamic> data, String id) {
    return InventarioModel(
      id: id,
      stockTotal: (data['tot'] ?? 0).toInt(),
      stockDisponible: (data['disp'] ?? 0).toInt(),
      fechaActualizacion: (data['fhAct'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'tot': stockTotal,
      'disp': stockDisponible,
      'fhAct': Timestamp.fromDate(fechaActualizacion),
    };
  }

  // Calcular stock en uso (prestado)
  int get stockEnUso {
    return stockTotal - stockDisponible;
  }

  // Calcular porcentaje de stock disponible
  double get porcentajeDisponible {
    if (stockTotal == 0) return 0.0;
    return (stockDisponible / stockTotal) * 100;
  }

  // Verificar si hay stock bajo (menos del 20%)
  bool get stockBajo {
    return porcentajeDisponible < 20.0;
  }

  // Verificar si hay stock crítico (menos del 10%)
  bool get stockCritico {
    return porcentajeDisponible < 10.0;
  }

  // Verificar si no hay stock disponible
  bool get sinStock {
    return stockDisponible <= 0;
  }

  // Obtener estado del stock
  String get estadoStock {
    if (sinStock) return 'Sin Stock';
    if (stockCritico) return 'Stock Crítico';
    if (stockBajo) return 'Stock Bajo';
    return 'Stock Normal';
  }

  // Agregar stock (cuando se compran más bidones)
  InventarioModel agregarStock(int cantidad) {
    return copyWith(
      stockTotal: stockTotal + cantidad,
      stockDisponible: stockDisponible + cantidad,
      fechaActualizacion: DateTime.now(),
    );
  }

  // Reducir stock disponible (cuando se hace una venta nueva)
  InventarioModel reducirStock(int cantidad) {
    final nuevoDisponible = (stockDisponible - cantidad).clamp(0, stockTotal);
    return copyWith(
      stockDisponible: nuevoDisponible,
      fechaActualizacion: DateTime.now(),
    );
  }

  // Aumentar stock disponible (cuando devuelven bidones)
  InventarioModel aumentarStock(int cantidad) {
    final nuevoDisponible = (stockDisponible + cantidad).clamp(0, stockTotal);
    return copyWith(
      stockDisponible: nuevoDisponible,
      fechaActualizacion: DateTime.now(),
    );
  }

  // Copiar con modificaciones
  InventarioModel copyWith({
    String? id,
    int? stockTotal,
    int? stockDisponible,
    DateTime? fechaActualizacion,
  }) {
    return InventarioModel(
      id: id ?? this.id,
      stockTotal: stockTotal ?? this.stockTotal,
      stockDisponible: stockDisponible ?? this.stockDisponible,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  @override
  String toString() {
    return 'InventarioModel(stockTotal: $stockTotal, stockDisponible: $stockDisponible, estado: $estadoStock)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventarioModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
