import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/inventario_model.dart';
import '../models/user_model.dart';

class InventarioService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _inventarioCollection = 'inventario';
  static const String _bidonesDoc = 'bidones';
  
  // Singleton pattern
  static final InventarioService _instance = InventarioService._internal();
  factory InventarioService() => _instance;
  InventarioService._internal();

  // Obtener inventario actual con cálculo correcto de préstamos
  Future<InventarioModel?> obtenerInventario() async {
    try {
      final doc = await _firestore
          .collection(_inventarioCollection)
          .doc(_bidonesDoc)
          .get();

      InventarioModel? inventarioBase;
      if (doc.exists && doc.data() != null) {
        inventarioBase = InventarioModel.fromFirestore(doc.data()!, doc.id);
      } else {
        // Si no existe, crear inventario inicial
        inventarioBase = await _crearInventarioInicial();
      }

      if (inventarioBase == null) return null;

      // Calcular bidones prestados y vendidos correctamente
      final estadisticasVentas = await _calcularEstadisticasVentas();
      
      return InventarioModel(
        id: inventarioBase.id,
        stockTotal: inventarioBase.stockTotal,
        stockDisponible: inventarioBase.stockDisponible,
        fechaActualizacion: inventarioBase.fechaActualizacion,
        bidonesVendidos: estadisticasVentas['vendidos'],
        bidonesPrestados: estadisticasVentas['prestados'],
      );
    } catch (e) {
      debugPrint('Error obteniendo inventario: $e');
      return null;
    }
  }

  // Calcular estadísticas reales de ventas
  Future<Map<String, int>> _calcularEstadisticasVentas() async {
    try {
      // Obtener todas las ventas para calcular correctamente
      final ventasSnapshot = await _firestore
          .collection('ventas')
          .get();

      int bidonesVendidos = 0; // Garrafón nuevo (cliente compra el bidón)
      int bidonesPrestados = 0; // Préstamo + agua (cliente recibe bidón prestado)

      for (final doc in ventasSnapshot.docs) {
        final data = doc.data();
        final tipo = data['tp']?.toString() ?? '';
        final cantidad = (data['cant'] ?? 0) as int;

        switch (tipo) {
          case 'nueva':
            // Garrafón nuevo: el cliente COMPRA el bidón (no es préstamo)
            bidonesVendidos += cantidad;
            break;
          case 'prestamo':
            // Préstamo + agua: el cliente recibe el bidón PRESTADO
            bidonesPrestados += cantidad;
            break;
          case 'recarga':
            // Recarga: no afecta el stock de bidones (cliente ya tiene uno)
            break;
        }
      }

      debugPrint('📊 INVENTARIO DEBUG - Bidones vendidos: $bidonesVendidos');
      debugPrint('📊 INVENTARIO DEBUG - Bidones prestados: $bidonesPrestados');

      return {
        'vendidos': bidonesVendidos,
        'prestados': bidonesPrestados,
      };
    } catch (e) {
      debugPrint('❌ INVENTARIO ERROR - Error calculando estadísticas: $e');
      return {
        'vendidos': 0,
        'prestados': 0,
      };
    }
  }

  // Crear inventario inicial
  Future<InventarioModel?> _crearInventarioInicial() async {
    try {
      final inventarioInicial = InventarioModel(
        id: _bidonesDoc,
        stockTotal: 0,
        stockDisponible: 0,
        fechaActualizacion: DateTime.now(),
      );

      await _firestore
          .collection(_inventarioCollection)
          .doc(_bidonesDoc)
          .set(inventarioInicial.toFirestore());

      debugPrint('Inventario inicial creado');
      return inventarioInicial;
    } catch (e) {
      debugPrint('Error creando inventario inicial: $e');
      return null;
    }
  }

  // Agregar stock (cuando se compran más bidones)
  Future<bool> agregarStock(int cantidad, UserModel usuarioActual) async {
    try {
      if (!usuarioActual.isAdmin) {
        debugPrint('Solo los administradores pueden agregar stock');
        return false;
      }

      final inventarioActual = await obtenerInventario();
      if (inventarioActual == null) return false;

      final nuevoInventario = inventarioActual.agregarStock(cantidad);

      await _firestore
          .collection(_inventarioCollection)
          .doc(_bidonesDoc)
          .update(nuevoInventario.toFirestore());

      debugPrint('Stock agregado exitosamente: $cantidad bidones');
      return true;
    } catch (e) {
      debugPrint('Error agregando stock: $e');
      return false;
    }
  }

  // Reducir stock disponible (cuando se hace una venta nueva)
  Future<bool> reducirStock(int cantidad) async {
    try {
      final inventarioActual = await obtenerInventario();
      if (inventarioActual == null) return false;

      // Verificar si hay suficiente stock
      if (inventarioActual.stockDisponible < cantidad) {
        debugPrint('Stock insuficiente. Disponible: ${inventarioActual.stockDisponible}, Solicitado: $cantidad');
        return false;
      }

      final nuevoInventario = inventarioActual.reducirStock(cantidad);

      await _firestore
          .collection(_inventarioCollection)
          .doc(_bidonesDoc)
          .update(nuevoInventario.toFirestore());

      debugPrint('Stock reducido exitosamente: $cantidad bidones');
      return true;
    } catch (e) {
      debugPrint('Error reduciendo stock: $e');
      return false;
    }
  }

  // Aumentar stock disponible (cuando devuelven bidones)
  Future<bool> aumentarStock(int cantidad) async {
    try {
      final inventarioActual = await obtenerInventario();
      if (inventarioActual == null) return false;

      final nuevoInventario = inventarioActual.aumentarStock(cantidad);

      await _firestore
          .collection(_inventarioCollection)
          .doc(_bidonesDoc)
          .update(nuevoInventario.toFirestore());

      debugPrint('Stock aumentado exitosamente: $cantidad bidones');
      return true;
    } catch (e) {
      debugPrint('Error aumentando stock: $e');
      return false;
    }
  }

  // Actualizar stock total (ajuste de inventario)
  Future<bool> actualizarStockTotal(int nuevoStockTotal, UserModel usuarioActual) async {
    try {
      if (!usuarioActual.isAdmin) {
        debugPrint('Solo los administradores pueden actualizar el stock total');
        return false;
      }

      final inventarioActual = await obtenerInventario();
      if (inventarioActual == null) return false;

      // Calcular nuevo stock disponible manteniendo la proporción
      final stockEnUso = inventarioActual.stockEnUso;
      final nuevoStockDisponible = (nuevoStockTotal - stockEnUso).clamp(0, nuevoStockTotal);

      final nuevoInventario = inventarioActual.copyWith(
        stockTotal: nuevoStockTotal,
        stockDisponible: nuevoStockDisponible,
        fechaActualizacion: DateTime.now(),
      );

      await _firestore
          .collection(_inventarioCollection)
          .doc(_bidonesDoc)
          .update(nuevoInventario.toFirestore());

      debugPrint('Stock total actualizado exitosamente: $nuevoStockTotal');
      return true;
    } catch (e) {
      debugPrint('Error actualizando stock total: $e');
      return false;
    }
  }

  // Obtener historial de movimientos de inventario (simulado)
  Future<List<Map<String, dynamic>>> obtenerHistorialMovimientos() async {
    try {
      // En una implementación completa, esto vendría de una colección separada
      // Por ahora, retornamos datos simulados basados en el inventario actual
      final inventario = await obtenerInventario();
      if (inventario == null) return [];

      return [
        {
          'fecha': inventario.fechaActualizacion,
          'tipo': 'Actualización',
          'cantidad': inventario.stockTotal,
          'descripcion': 'Estado actual del inventario',
        }
      ];
    } catch (e) {
      debugPrint('Error obteniendo historial: $e');
      return [];
    }
  }

  // Verificar alertas de stock
  Future<Map<String, dynamic>> verificarAlertas() async {
    try {
      final inventario = await obtenerInventario();
      if (inventario == null) {
        return {'alertas': [], 'nivel': 'normal'};
      }

      final alertas = <String>[];
      String nivel = 'normal';

      if (inventario.sinStock) {
        alertas.add('¡Sin stock disponible!');
        nivel = 'critico';
      } else if (inventario.stockCritico) {
        alertas.add('Stock crítico: ${inventario.stockDisponible} bidones disponibles');
        nivel = 'critico';
      } else if (inventario.stockBajo) {
        alertas.add('Stock bajo: ${inventario.stockDisponible} bidones disponibles');
        nivel = 'advertencia';
      }

      return {
        'alertas': alertas,
        'nivel': nivel,
        'stockDisponible': inventario.stockDisponible,
        'stockTotal': inventario.stockTotal,
        'porcentaje': inventario.porcentajeDisponible,
      };
    } catch (e) {
      debugPrint('Error verificando alertas: $e');
      return {'alertas': [], 'nivel': 'error'};
    }
  }

  // Stream para escuchar cambios en el inventario
  Stream<InventarioModel?> escucharInventario() {
    return _firestore
        .collection(_inventarioCollection)
        .doc(_bidonesDoc)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return InventarioModel.fromFirestore(snapshot.data()!, snapshot.id);
          }
          return null;
        });
  }

  // Obtener estadísticas del inventario
  Future<Map<String, dynamic>> obtenerEstadisticasInventario() async {
    try {
      final inventario = await obtenerInventario();
      if (inventario == null) {
        return {
          'stockTotal': 0,
          'stockDisponible': 0,
          'stockEnUso': 0,
          'porcentajeDisponible': 0.0,
          'estado': 'Sin datos',
        };
      }

      return {
        'stockTotal': inventario.stockTotal,
        'stockDisponible': inventario.stockDisponible,
        'stockEnUso': inventario.stockEnUso,
        'porcentajeDisponible': inventario.porcentajeDisponible,
        'estado': inventario.estadoStock,
        'ultimaActualizacion': inventario.fechaActualizacion,
      };
    } catch (e) {
      debugPrint('Error obteniendo estadísticas de inventario: $e');
      return {};
    }
  }
}
