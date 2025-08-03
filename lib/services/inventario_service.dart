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

  // Obtener inventario actual
  Future<InventarioModel?> obtenerInventario() async {
    try {
      final doc = await _firestore
          .collection(_inventarioCollection)
          .doc(_bidonesDoc)
          .get();

      if (doc.exists && doc.data() != null) {
        return InventarioModel.fromFirestore(doc.data()!, doc.id);
      }
      
      // Si no existe, crear inventario inicial
      return await _crearInventarioInicial();
    } catch (e) {
      debugPrint('Error obteniendo inventario: $e');
      return null;
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
