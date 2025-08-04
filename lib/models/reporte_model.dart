import 'package:cloud_firestore/cloud_firestore.dart';

class ReporteVentas {
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final int totalVentas;
  final double totalIngresos;
  final double totalCostos;
  final double totalGanancias;
  final Map<String, int> ventasPorTipo;
  final Map<String, double> ingresosPorTipo;
  final List<VentaReporte> ventasDetalle;
  final List<ClienteReporte> clientesTop;

  ReporteVentas({
    required this.fechaInicio,
    required this.fechaFin,
    required this.totalVentas,
    required this.totalIngresos,
    required this.totalCostos,
    required this.totalGanancias,
    required this.ventasPorTipo,
    required this.ingresosPorTipo,
    required this.ventasDetalle,
    required this.clientesTop,
  });

  double get margenGanancia => totalIngresos > 0 ? (totalGanancias / totalIngresos) * 100 : 0;
  double get promedioVenta => totalVentas > 0 ? totalIngresos / totalVentas : 0;
  
  String get periodoTexto {
    if (fechaInicio.year == fechaFin.year && 
        fechaInicio.month == fechaFin.month && 
        fechaInicio.day == fechaFin.day) {
      return 'Día ${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year}';
    } else if (fechaInicio.year == fechaFin.year && fechaInicio.month == fechaFin.month) {
      return 'Mes ${fechaInicio.month}/${fechaInicio.year}';
    } else if (fechaInicio.year == fechaFin.year) {
      return 'Año ${fechaInicio.year}';
    } else {
      return '${fechaInicio.day}/${fechaInicio.month}/${fechaInicio.year} - ${fechaFin.day}/${fechaFin.month}/${fechaFin.year}';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'totalVentas': totalVentas,
      'totalIngresos': totalIngresos,
      'totalCostos': totalCostos,
      'totalGanancias': totalGanancias,
      'ventasPorTipo': ventasPorTipo,
      'ingresosPorTipo': ingresosPorTipo,
    };
  }
}

class VentaReporte {
  final String id;
  final DateTime fecha;
  final String clienteNombre;
  final String tipo;
  final int cantidad;
  final double precioUnitario;
  final double costoUnitario;
  final double total;
  final double ganancia;

  VentaReporte({
    required this.id,
    required this.fecha,
    required this.clienteNombre,
    required this.tipo,
    required this.cantidad,
    required this.precioUnitario,
    required this.costoUnitario,
    required this.total,
    required this.ganancia,
  });

  String get tipoDisplayName {
    switch (tipo) {
      case 'nueva':
        return 'Venta Nueva';
      case 'recarga':
        return 'Recarga';
      case 'prestamo':
        return 'Préstamo';
      default:
        return tipo;
    }
  }

  factory VentaReporte.fromFirestore(Map<String, dynamic> data, String id) {
    final total = (data['tot'] ?? 0).toDouble();
    final costoBidon = (data['costBid'] ?? 0).toDouble();
    final cantidad = (data['cant'] ?? 0) as int;
    
    return VentaReporte(
      id: id,
      fecha: data['fh'] != null ? (data['fh'] as Timestamp).toDate() : DateTime.now(),
      clienteNombre: data['clienteNombre']?.toString() ?? 'Cliente no encontrado',
      tipo: data['tp']?.toString() ?? '',
      cantidad: cantidad,
      precioUnitario: (data['pUnit'] ?? 0).toDouble(),
      costoUnitario: costoBidon,
      total: total,
      ganancia: total - (costoBidon * cantidad),
    );
  }
}

class ClienteReporte {
  final String id;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final int totalVentas;
  final double totalCompras;
  final double promedioCompra;
  final DateTime ultimaCompra;

  ClienteReporte({
    required this.id,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.totalVentas,
    required this.totalCompras,
    required this.promedioCompra,
    required this.ultimaCompra,
  });

  String get nombreCompleto => '$nombre $apellidoPaterno $apellidoMaterno';

  factory ClienteReporte.fromData(Map<String, dynamic> data) {
    return ClienteReporte(
      id: data['id'] ?? '',
      nombre: data['nombre'] ?? '',
      apellidoPaterno: data['apellidoPaterno'] ?? '',
      apellidoMaterno: data['apellidoMaterno'] ?? '',
      totalVentas: data['totalVentas'] ?? 0,
      totalCompras: (data['totalCompras'] ?? 0).toDouble(),
      promedioCompra: (data['promedioCompra'] ?? 0).toDouble(),
      ultimaCompra: data['ultimaCompra'] ?? DateTime.now(),
    );
  }
}

class EstadisticasPeriodo {
  final String periodo;
  final DateTime fecha;
  final int ventas;
  final double ingresos;
  final double ganancias;

  EstadisticasPeriodo({
    required this.periodo,
    required this.fecha,
    required this.ventas,
    required this.ingresos,
    required this.ganancias,
  });

  factory EstadisticasPeriodo.fromData(String periodo, DateTime fecha, Map<String, dynamic> data) {
    return EstadisticasPeriodo(
      periodo: periodo,
      fecha: fecha,
      ventas: data['ventas'] ?? 0,
      ingresos: (data['ingresos'] ?? 0).toDouble(),
      ganancias: (data['ganancias'] ?? 0).toDouble(),
    );
  }
}

enum TipoReporte {
  diario,
  semanal,
  mensual,
  anual,
  personalizado,
}

extension TipoReporteExtension on TipoReporte {
  String get displayName {
    switch (this) {
      case TipoReporte.diario:
        return 'Diario';
      case TipoReporte.semanal:
        return 'Semanal';
      case TipoReporte.mensual:
        return 'Mensual';
      case TipoReporte.anual:
        return 'Anual';
      case TipoReporte.personalizado:
        return 'Personalizado';
    }
  }

  String get descripcion {
    switch (this) {
      case TipoReporte.diario:
        return 'Reporte de ventas del día';
      case TipoReporte.semanal:
        return 'Reporte de ventas de la semana';
      case TipoReporte.mensual:
        return 'Reporte de ventas del mes';
      case TipoReporte.anual:
        return 'Reporte de ventas del año';
      case TipoReporte.personalizado:
        return 'Reporte de período personalizado';
    }
  }
}

class FiltroReporte {
  final TipoReporte tipoReporte;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? clienteId;
  final String? tipoVenta;
  final bool incluirCostos;
  final bool incluirGanancias;

  FiltroReporte({
    required this.tipoReporte,
    this.fechaInicio,
    this.fechaFin,
    this.clienteId,
    this.tipoVenta,
    this.incluirCostos = true,
    this.incluirGanancias = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'tipoReporte': tipoReporte.name,
      'fechaInicio': fechaInicio?.toIso8601String(),
      'fechaFin': fechaFin?.toIso8601String(),
      'clienteId': clienteId,
      'tipoVenta': tipoVenta,
      'incluirCostos': incluirCostos,
      'incluirGanancias': incluirGanancias,
    };
  }

  factory FiltroReporte.fromMap(Map<String, dynamic> map) {
    return FiltroReporte(
      tipoReporte: TipoReporte.values.firstWhere(
        (e) => e.name == map['tipoReporte'],
        orElse: () => TipoReporte.diario,
      ),
      fechaInicio: map['fechaInicio'] != null ? DateTime.parse(map['fechaInicio']) : null,
      fechaFin: map['fechaFin'] != null ? DateTime.parse(map['fechaFin']) : null,
      clienteId: map['clienteId'],
      tipoVenta: map['tipoVenta'],
      incluirCostos: map['incluirCostos'] ?? true,
      incluirGanancias: map['incluirGanancias'] ?? true,
    );
  }

  FiltroReporte copyWith({
    TipoReporte? tipoReporte,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? clienteId,
    String? tipoVenta,
    bool? incluirCostos,
    bool? incluirGanancias,
  }) {
    return FiltroReporte(
      tipoReporte: tipoReporte ?? this.tipoReporte,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      clienteId: clienteId ?? this.clienteId,
      tipoVenta: tipoVenta ?? this.tipoVenta,
      incluirCostos: incluirCostos ?? this.incluirCostos,
      incluirGanancias: incluirGanancias ?? this.incluirGanancias,
    );
  }
}
