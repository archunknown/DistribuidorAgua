import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/reporte_model.dart';
import '../models/venta_model.dart';
import '../models/cliente_model.dart';

class ReporteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Singleton pattern
  static final ReporteService _instance = ReporteService._internal();
  factory ReporteService() => _instance;
  ReporteService._internal();

  // Generar reporte de ventas por período
  Future<ReporteVentas> generarReporteVentas(FiltroReporte filtro) async {
    try {
      final fechas = _calcularFechasPeriodo(filtro);
      final fechaInicio = fechas['inicio']!;
      final fechaFin = fechas['fin']!;

      // Obtener ventas del período
      Query query = _firestore
          .collection('ventas')
          .where('fh', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio))
          .where('fh', isLessThanOrEqualTo: Timestamp.fromDate(fechaFin))
          .orderBy('fh', descending: true);

      // Aplicar filtros adicionales
      if (filtro.tipoVenta != null && filtro.tipoVenta!.isNotEmpty) {
        query = query.where('tp', isEqualTo: filtro.tipoVenta);
      }

      final ventasSnapshot = await query.get();
      
      // Procesar ventas
      final ventasDetalle = <VentaReporte>[];
      final ventasPorTipo = <String, int>{};
      final ingresosPorTipo = <String, double>{};
      
      double totalIngresos = 0;
      double totalCostos = 0;
      
      for (final doc in ventasSnapshot.docs) {
        final ventaData = doc.data() as Map<String, dynamic>;
        
        // Obtener información del cliente
        String clienteNombre = 'Cliente no encontrado';
        if (ventaData['cliRef'] != null) {
          try {
            final clienteDoc = await (ventaData['cliRef'] as DocumentReference).get();
            if (clienteDoc.exists) {
              final clienteData = clienteDoc.data() as Map<String, dynamic>;
              final nombre = clienteData['nom']?.toString() ?? '';
              final apePat = clienteData['apePat']?.toString() ?? '';
              final apeMat = clienteData['apeMat']?.toString() ?? '';
              clienteNombre = '$nombre $apePat $apeMat'.trim();
              if (clienteNombre.isEmpty) {
                clienteNombre = 'Cliente sin nombre';
              }
            }
          } catch (e) {
            debugPrint('Error obteniendo cliente: $e');
            clienteNombre = 'Error al cargar cliente';
          }
        }
        
        // Crear reporte de venta
        final ventaReporte = VentaReporte(
          id: doc.id,
          fecha: (ventaData['fh'] as Timestamp).toDate(),
          clienteNombre: clienteNombre,
          tipo: ventaData['tp'] ?? '',
          cantidad: ventaData['cant'] ?? 0,
          precioUnitario: (ventaData['pUnit'] ?? 0).toDouble(),
          costoUnitario: (ventaData['costBid'] ?? 0).toDouble(),
          total: (ventaData['tot'] ?? 0).toDouble(),
          ganancia: (ventaData['tot'] ?? 0).toDouble() - 
                   ((ventaData['costBid'] ?? 0).toDouble() * (ventaData['cant'] ?? 0)),
        );
        
        ventasDetalle.add(ventaReporte);
        
        // Acumular estadísticas
        final tipo = ventaReporte.tipo;
        ventasPorTipo[tipo] = (ventasPorTipo[tipo] ?? 0) + ventaReporte.cantidad;
        ingresosPorTipo[tipo] = (ingresosPorTipo[tipo] ?? 0) + ventaReporte.total;
        
        totalIngresos += ventaReporte.total;
        totalCostos += ventaReporte.costoUnitario * ventaReporte.cantidad;
      }

      // Filtrar por cliente si se especifica
      if (filtro.clienteId != null && filtro.clienteId!.isNotEmpty) {
        ventasDetalle.removeWhere((venta) => !venta.clienteNombre.toLowerCase().contains(filtro.clienteId!.toLowerCase()));
      }

      // Obtener clientes top
      final clientesTop = await _obtenerClientesTop(fechaInicio, fechaFin);

      return ReporteVentas(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        totalVentas: ventasDetalle.length,
        totalIngresos: totalIngresos,
        totalCostos: totalCostos,
        totalGanancias: totalIngresos - totalCostos,
        ventasPorTipo: ventasPorTipo,
        ingresosPorTipo: ingresosPorTipo,
        ventasDetalle: ventasDetalle,
        clientesTop: clientesTop,
      );
    } catch (e) {
      debugPrint('Error generando reporte de ventas: $e');
      throw Exception('Error generando reporte: $e');
    }
  }

  // Obtener estadísticas por período para gráficos
  Future<List<EstadisticasPeriodo>> obtenerEstadisticasPeriodo(
    TipoReporte tipoReporte,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      final estadisticas = <EstadisticasPeriodo>[];
      
      switch (tipoReporte) {
        case TipoReporte.diario:
          estadisticas.addAll(await _obtenerEstadisticasDiarias(fechaInicio, fechaFin));
          break;
        case TipoReporte.semanal:
          estadisticas.addAll(await _obtenerEstadisticasSemanales(fechaInicio, fechaFin));
          break;
        case TipoReporte.mensual:
          estadisticas.addAll(await _obtenerEstadisticasMensuales(fechaInicio, fechaFin));
          break;
        case TipoReporte.anual:
          estadisticas.addAll(await _obtenerEstadisticasAnuales(fechaInicio, fechaFin));
          break;
        default:
          estadisticas.addAll(await _obtenerEstadisticasDiarias(fechaInicio, fechaFin));
      }
      
      return estadisticas;
    } catch (e) {
      debugPrint('Error obteniendo estadísticas por período: $e');
      return [];
    }
  }

  // Obtener resumen rápido para dashboard
  Future<Map<String, dynamic>> obtenerResumenRapido() async {
    try {
      final hoy = DateTime.now();
      final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
      final finHoy = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);
      
      final inicioSemana = inicioHoy.subtract(Duration(days: hoy.weekday - 1));
      final inicioMes = DateTime(hoy.year, hoy.month, 1);
      
      // Ventas de hoy
      final ventasHoy = await _obtenerVentasPeriodo(inicioHoy, finHoy);
      
      // Ventas de la semana
      final ventasSemana = await _obtenerVentasPeriodo(inicioSemana, finHoy);
      
      // Ventas del mes
      final ventasMes = await _obtenerVentasPeriodo(inicioMes, finHoy);
      
      return {
        'hoy': {
          'cantidad': ventasHoy['cantidad'],
          'total': ventasHoy['total'],
          'ganancias': ventasHoy['ganancias'],
        },
        'semana': {
          'cantidad': ventasSemana['cantidad'],
          'total': ventasSemana['total'],
          'ganancias': ventasSemana['ganancias'],
        },
        'mes': {
          'cantidad': ventasMes['cantidad'],
          'total': ventasMes['total'],
          'ganancias': ventasMes['ganancias'],
        },
      };
    } catch (e) {
      debugPrint('Error obteniendo resumen rápido: $e');
      return {
        'hoy': {'cantidad': 0, 'total': 0.0, 'ganancias': 0.0},
        'semana': {'cantidad': 0, 'total': 0.0, 'ganancias': 0.0},
        'mes': {'cantidad': 0, 'total': 0.0, 'ganancias': 0.0},
      };
    }
  }

  // Métodos privados auxiliares
  Map<String, DateTime> _calcularFechasPeriodo(FiltroReporte filtro) {
    final ahora = DateTime.now();
    DateTime fechaInicio;
    DateTime fechaFin;

    switch (filtro.tipoReporte) {
      case TipoReporte.diario:
        fechaInicio = DateTime(ahora.year, ahora.month, ahora.day);
        fechaFin = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
        break;
      case TipoReporte.semanal:
        final inicioSemana = ahora.subtract(Duration(days: ahora.weekday - 1));
        fechaInicio = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
        fechaFin = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
        break;
      case TipoReporte.mensual:
        fechaInicio = DateTime(ahora.year, ahora.month, 1);
        fechaFin = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);
        break;
      case TipoReporte.anual:
        fechaInicio = DateTime(ahora.year, 1, 1);
        fechaFin = DateTime(ahora.year, 12, 31, 23, 59, 59);
        break;
      case TipoReporte.personalizado:
        fechaInicio = filtro.fechaInicio ?? DateTime(ahora.year, ahora.month, ahora.day);
        fechaFin = filtro.fechaFin ?? DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
        break;
    }

    return {'inicio': fechaInicio, 'fin': fechaFin};
  }

  Future<List<ClienteReporte>> _obtenerClientesTop(DateTime fechaInicio, DateTime fechaFin) async {
    try {
      final ventasSnapshot = await _firestore
          .collection('ventas')
          .where('fh', isGreaterThanOrEqualTo: Timestamp.fromDate(fechaInicio))
          .where('fh', isLessThanOrEqualTo: Timestamp.fromDate(fechaFin))
          .get();

      final clientesData = <String, Map<String, dynamic>>{};

      for (final doc in ventasSnapshot.docs) {
        final ventaData = doc.data();
        final clienteRef = ventaData['cliRef'] as DocumentReference?;
        
        if (clienteRef != null) {
          final clienteId = clienteRef.id;
          final total = (ventaData['tot'] ?? 0).toDouble();
          
          if (clientesData.containsKey(clienteId)) {
            clientesData[clienteId]!['totalVentas'] += 1;
            clientesData[clienteId]!['totalCompras'] += total;
          } else {
            // Obtener datos del cliente
            try {
              final clienteDoc = await clienteRef.get();
              if (clienteDoc.exists) {
                final clienteData = clienteDoc.data() as Map<String, dynamic>;
                clientesData[clienteId] = {
                  'id': clienteId,
                  'nombre': clienteData['nom'] ?? '',
                  'apellidoPaterno': clienteData['apePat'] ?? '',
                  'apellidoMaterno': clienteData['apeMat'] ?? '',
                  'totalVentas': 1,
                  'totalCompras': total,
                  'ultimaCompra': (ventaData['fh'] as Timestamp).toDate(),
                };
              }
            } catch (e) {
              debugPrint('Error obteniendo datos del cliente: $e');
            }
          }
        }
      }

      // Convertir a lista y calcular promedios
      final clientesTop = clientesData.values.map((data) {
        data['promedioCompra'] = data['totalCompras'] / data['totalVentas'];
        return ClienteReporte.fromData(data);
      }).toList();

      // Ordenar por total de compras
      clientesTop.sort((a, b) => b.totalCompras.compareTo(a.totalCompras));

      return clientesTop.take(10).toList();
    } catch (e) {
      debugPrint('Error obteniendo clientes top: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _obtenerVentasPeriodo(DateTime inicio, DateTime fin) async {
    try {
      final snapshot = await _firestore
          .collection('ventas')
          .where('fh', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
          .where('fh', isLessThanOrEqualTo: Timestamp.fromDate(fin))
          .get();

      int cantidad = 0;
      double total = 0;
      double costos = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        cantidad += (data['cant'] ?? 0) as int;
        total += (data['tot'] ?? 0).toDouble();
        costos += ((data['costBid'] ?? 0).toDouble() * (data['cant'] ?? 0));
      }

      return {
        'cantidad': cantidad,
        'total': total,
        'ganancias': total - costos,
      };
    } catch (e) {
      debugPrint('Error obteniendo ventas del período: $e');
      return {'cantidad': 0, 'total': 0.0, 'ganancias': 0.0};
    }
  }

  Future<List<EstadisticasPeriodo>> _obtenerEstadisticasDiarias(DateTime inicio, DateTime fin) async {
    final estadisticas = <EstadisticasPeriodo>[];
    var fechaActual = DateTime(inicio.year, inicio.month, inicio.day);
    final fechaFinal = DateTime(fin.year, fin.month, fin.day);

    while (fechaActual.isBefore(fechaFinal) || fechaActual.isAtSameMomentAs(fechaFinal)) {
      final inicioDay = fechaActual;
      final finDay = DateTime(fechaActual.year, fechaActual.month, fechaActual.day, 23, 59, 59);
      
      final datos = await _obtenerVentasPeriodo(inicioDay, finDay);
      
      estadisticas.add(EstadisticasPeriodo(
        periodo: '${fechaActual.day}/${fechaActual.month}',
        fecha: fechaActual,
        ventas: datos['cantidad'],
        ingresos: datos['total'],
        ganancias: datos['ganancias'],
      ));
      
      fechaActual = fechaActual.add(const Duration(days: 1));
    }

    return estadisticas;
  }

  Future<List<EstadisticasPeriodo>> _obtenerEstadisticasSemanales(DateTime inicio, DateTime fin) async {
    final estadisticas = <EstadisticasPeriodo>[];
    var fechaActual = inicio;
    var semana = 1;

    while (fechaActual.isBefore(fin)) {
      final finSemana = fechaActual.add(const Duration(days: 6));
      final fechaFinalSemana = finSemana.isAfter(fin) ? fin : finSemana;
      
      final datos = await _obtenerVentasPeriodo(fechaActual, fechaFinalSemana);
      
      estadisticas.add(EstadisticasPeriodo(
        periodo: 'Semana $semana',
        fecha: fechaActual,
        ventas: datos['cantidad'],
        ingresos: datos['total'],
        ganancias: datos['ganancias'],
      ));
      
      fechaActual = finSemana.add(const Duration(days: 1));
      semana++;
    }

    return estadisticas;
  }

  Future<List<EstadisticasPeriodo>> _obtenerEstadisticasMensuales(DateTime inicio, DateTime fin) async {
    final estadisticas = <EstadisticasPeriodo>[];
    var fechaActual = DateTime(inicio.year, inicio.month, 1);

    while (fechaActual.isBefore(fin) || fechaActual.month == fin.month) {
      final finMes = DateTime(fechaActual.year, fechaActual.month + 1, 0, 23, 59, 59);
      final fechaFinalMes = finMes.isAfter(fin) ? fin : finMes;
      
      final datos = await _obtenerVentasPeriodo(fechaActual, fechaFinalMes);
      
      final nombreMes = _obtenerNombreMes(fechaActual.month);
      
      estadisticas.add(EstadisticasPeriodo(
        periodo: '$nombreMes ${fechaActual.year}',
        fecha: fechaActual,
        ventas: datos['cantidad'],
        ingresos: datos['total'],
        ganancias: datos['ganancias'],
      ));
      
      fechaActual = DateTime(fechaActual.year, fechaActual.month + 1, 1);
    }

    return estadisticas;
  }

  Future<List<EstadisticasPeriodo>> _obtenerEstadisticasAnuales(DateTime inicio, DateTime fin) async {
    final estadisticas = <EstadisticasPeriodo>[];
    var anio = inicio.year;

    while (anio <= fin.year) {
      final inicioAnio = DateTime(anio, 1, 1);
      final finAnio = DateTime(anio, 12, 31, 23, 59, 59);
      
      final fechaInicioReal = anio == inicio.year ? inicio : inicioAnio;
      final fechaFinReal = anio == fin.year ? fin : finAnio;
      
      final datos = await _obtenerVentasPeriodo(fechaInicioReal, fechaFinReal);
      
      estadisticas.add(EstadisticasPeriodo(
        periodo: anio.toString(),
        fecha: inicioAnio,
        ventas: datos['cantidad'],
        ingresos: datos['total'],
        ganancias: datos['ganancias'],
      ));
      
      anio++;
    }

    return estadisticas;
  }

  String _obtenerNombreMes(int mes) {
    const meses = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[mes];
  }
}
