import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/venta_model.dart';
import '../models/user_model.dart';
import '../models/cliente_model.dart';
import 'inventario_service.dart';

class VentaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InventarioService _inventarioService = InventarioService();
  static const String _ventasCollection = 'ventas';
  
  // Singleton pattern
  static final VentaService _instance = VentaService._internal();
  factory VentaService() => _instance;
  VentaService._internal();

  // Crear nueva venta
  Future<String?> crearVenta({
    required String clienteId,
    required TipoVenta tipo,
    required int cantidad,
    required double precioUnitario,
    required double costoBidon,
    required UserModel usuarioActual,
  }) async {
    try {
      final total = precioUnitario * cantidad;
      
      // Si es venta nueva, verificar y reducir stock
      if (tipo == TipoVenta.nueva || tipo == TipoVenta.prestamo) {
        final stockReducido = await _inventarioService.reducirStock(cantidad);
        if (!stockReducido) {
          debugPrint('No hay suficiente stock disponible');
          return null;
        }
      }

      final ventaData = {
        'fh': FieldValue.serverTimestamp(),
        'cliRef': clienteId,
        'tp': tipo.name,
        'cant': cantidad,
        'pUnit': precioUnitario,
        'costBid': costoBidon,
        'tot': total,
        'usrRef': usuarioActual.id,
      };

      final docRef = await _firestore
          .collection(_ventasCollection)
          .add(ventaData);

      debugPrint('Venta creada exitosamente: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creando venta: $e');
      return null;
    }
  }

  // Obtener venta por ID
  Future<VentaModel?> obtenerVentaPorId(String ventaId) async {
    try {
      final doc = await _firestore
          .collection(_ventasCollection)
          .doc(ventaId)
          .get();

      if (doc.exists && doc.data() != null) {
        return VentaModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo venta: $e');
      return null;
    }
  }

  // Obtener ventas del día actual
  Future<List<VentaModel>> obtenerVentasDelDia([DateTime? fecha]) async {
    try {
      final fechaConsulta = fecha ?? DateTime.now();
      final inicioDia = DateTime(fechaConsulta.year, fechaConsulta.month, fechaConsulta.day);
      final finDia = inicioDia.add(const Duration(days: 1));

      final querySnapshot = await _firestore
          .collection(_ventasCollection)
          .where('fh', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
          .where('fh', isLessThan: Timestamp.fromDate(finDia))
          .orderBy('fh', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VentaModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo ventas del día: $e');
      return [];
    }
  }

  // Obtener ventas de la semana actual
  Future<List<VentaModel>> obtenerVentasDeLaSemana([DateTime? fecha]) async {
    try {
      final fechaConsulta = fecha ?? DateTime.now();
      final inicioSemana = fechaConsulta.subtract(Duration(days: fechaConsulta.weekday - 1));
      final inicioSemanaDate = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
      final finSemana = inicioSemanaDate.add(const Duration(days: 7));

      final querySnapshot = await _firestore
          .collection(_ventasCollection)
          .where('fh', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioSemanaDate))
          .where('fh', isLessThan: Timestamp.fromDate(finSemana))
          .orderBy('fh', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VentaModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo ventas de la semana: $e');
      return [];
    }
  }

  // Obtener ventas del mes actual
  Future<List<VentaModel>> obtenerVentasDelMes([DateTime? fecha]) async {
    try {
      final fechaConsulta = fecha ?? DateTime.now();
      final inicioMes = DateTime(fechaConsulta.year, fechaConsulta.month, 1);
      final finMes = DateTime(fechaConsulta.year, fechaConsulta.month + 1, 1);

      final querySnapshot = await _firestore
          .collection(_ventasCollection)
          .where('fh', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes))
          .where('fh', isLessThan: Timestamp.fromDate(finMes))
          .orderBy('fh', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VentaModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo ventas del mes: $e');
      return [];
    }
  }

  // Obtener ventas por cliente
  Future<List<VentaModel>> obtenerVentasPorCliente(String clienteId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_ventasCollection)
          .where('cliRef', isEqualTo: clienteId)
          .orderBy('fh', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VentaModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo ventas por cliente: $e');
      return [];
    }
  }

  // Obtener ventas por usuario
  Future<List<VentaModel>> obtenerVentasPorUsuario(String usuarioId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_ventasCollection)
          .where('usrRef', isEqualTo: usuarioId)
          .orderBy('fh', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VentaModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo ventas por usuario: $e');
      return [];
    }
  }

  // Obtener estadísticas de ventas
  Future<Map<String, dynamic>> obtenerEstadisticasVentas() async {
    try {
      final hoy = DateTime.now();
      
      // Ventas del día
      final ventasHoy = await obtenerVentasDelDia();
      final totalHoy = ventasHoy.fold<double>(0, (sum, venta) => sum + venta.total);
      final gananciasHoy = ventasHoy.fold<double>(0, (sum, venta) => sum + venta.ganancia);
      
      // Ventas de la semana
      final ventasSemana = await obtenerVentasDeLaSemana();
      final totalSemana = ventasSemana.fold<double>(0, (sum, venta) => sum + venta.total);
      final gananciasSemana = ventasSemana.fold<double>(0, (sum, venta) => sum + venta.ganancia);
      
      // Ventas del mes
      final ventasMes = await obtenerVentasDelMes();
      final totalMes = ventasMes.fold<double>(0, (sum, venta) => sum + venta.total);
      final gananciasMes = ventasMes.fold<double>(0, (sum, venta) => sum + venta.ganancia);

      // Estadísticas por tipo de venta
      final ventasNuevas = ventasMes.where((v) => v.tipo == TipoVenta.nueva).length;
      final recargas = ventasMes.where((v) => v.tipo == TipoVenta.recarga).length;
      final prestamos = ventasMes.where((v) => v.tipo == TipoVenta.prestamo).length;

      return {
        'hoy': {
          'cantidad': ventasHoy.length,
          'total': totalHoy,
          'ganancias': gananciasHoy,
        },
        'semana': {
          'cantidad': ventasSemana.length,
          'total': totalSemana,
          'ganancias': gananciasSemana,
        },
        'mes': {
          'cantidad': ventasMes.length,
          'total': totalMes,
          'ganancias': gananciasMes,
          'ventasNuevas': ventasNuevas,
          'recargas': recargas,
          'prestamos': prestamos,
        },
      };
    } catch (e) {
      debugPrint('Error obteniendo estadísticas de ventas: $e');
      return {};
    }
  }

  // Actualizar venta
  Future<bool> actualizarVenta(String ventaId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(_ventasCollection)
          .doc(ventaId)
          .update(updates);

      debugPrint('Venta actualizada exitosamente: $ventaId');
      return true;
    } catch (e) {
      debugPrint('Error actualizando venta: $e');
      return false;
    }
  }

  // Eliminar venta (solo admin)
  Future<bool> eliminarVenta(String ventaId, UserModel usuarioActual) async {
    try {
      if (!usuarioActual.isAdmin) {
        debugPrint('Solo los administradores pueden eliminar ventas');
        return false;
      }

      // Obtener la venta antes de eliminarla para restaurar stock si es necesario
      final venta = await obtenerVentaPorId(ventaId);
      if (venta == null) return false;

      // Si era venta nueva, restaurar stock
      if (venta.tipo == TipoVenta.nueva || venta.tipo == TipoVenta.prestamo) {
        await _inventarioService.aumentarStock(venta.cantidad);
      }

      await _firestore
          .collection(_ventasCollection)
          .doc(ventaId)
          .delete();

      debugPrint('Venta eliminada exitosamente: $ventaId');
      return true;
    } catch (e) {
      debugPrint('Error eliminando venta: $e');
      return false;
    }
  }

  // Stream para escuchar ventas en tiempo real
  Stream<List<VentaModel>> escucharVentasDelDia() {
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = inicioDia.add(const Duration(days: 1));

    return _firestore
        .collection(_ventasCollection)
        .where('fh', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('fh', isLessThan: Timestamp.fromDate(finDia))
        .orderBy('fh', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VentaModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Obtener top clientes del mes
  Future<List<Map<String, dynamic>>> obtenerTopClientesDelMes() async {
    try {
      final ventasMes = await obtenerVentasDelMes();
      final clientesVentas = <String, Map<String, dynamic>>{};

      for (final venta in ventasMes) {
        if (clientesVentas.containsKey(venta.clienteId)) {
          clientesVentas[venta.clienteId]!['total'] += venta.total;
          clientesVentas[venta.clienteId]!['cantidad'] += venta.cantidad;
        } else {
          clientesVentas[venta.clienteId] = {
            'clienteId': venta.clienteId,
            'total': venta.total,
            'cantidad': venta.cantidad,
          };
        }
      }

      final topClientes = clientesVentas.values.toList();
      topClientes.sort((a, b) => b['total'].compareTo(a['total']));
      
      return topClientes.take(10).toList();
    } catch (e) {
      debugPrint('Error obteniendo top clientes: $e');
      return [];
    }
  }
}
