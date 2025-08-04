import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/cliente_model.dart';
import '../models/user_model.dart';

class ClienteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _clientesCollection = 'clientes';
  
  // Singleton pattern
  static final ClienteService _instance = ClienteService._internal();
  factory ClienteService() => _instance;
  ClienteService._internal();

  // Crear nuevo cliente
  Future<String?> crearCliente({
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String distrito,
    required String referencia,
    String? telefono,
    required UserModel usuarioActual,
  }) async {
    try {
      final clienteData = {
        'nom': nombre.trim(),
        'apePat': apellidoPaterno.trim(),
        'apeMat': apellidoMaterno.trim(),
        'distrito': distrito.trim(),
        'referencia': referencia.trim(),
        'tel': telefono?.trim(),
        'crePor': _firestore.collection('usuarios').doc(usuarioActual.id),
        'fhCre': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection(_clientesCollection)
          .add(clienteData);

      debugPrint('Cliente creado exitosamente: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creando cliente: $e');
      return null;
    }
  }

  // Obtener cliente por ID
  Future<ClienteModel?> obtenerClientePorId(String clienteId) async {
    try {
      final doc = await _firestore
          .collection(_clientesCollection)
          .doc(clienteId)
          .get();

      if (doc.exists && doc.data() != null) {
        return ClienteModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error obteniendo cliente: $e');
      return null;
    }
  }

  // Obtener todos los clientes
  Future<List<ClienteModel>> obtenerTodosLosClientes() async {
    try {
      final querySnapshot = await _firestore
          .collection(_clientesCollection)
          .orderBy('fhCre', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ClienteModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo clientes: $e');
      return [];
    }
  }

  // Buscar clientes por nombre (para autocompletado)
  Future<List<ClienteModel>> buscarClientesPorNombre(String query) async {
    try {
      if (query.isEmpty) return [];

      final queryLower = query.toLowerCase();
      
      // Buscar por nombre
      final querySnapshot = await _firestore
          .collection(_clientesCollection)
          .orderBy('nom')
          .startAt([queryLower])
          .endAt([queryLower + '\uf8ff'])
          .limit(10)
          .get();

      final clientes = querySnapshot.docs
          .map((doc) => ClienteModel.fromFirestore(doc.data(), doc.id))
          .toList();

      // Filtrar también por apellidos si no hay suficientes resultados
      if (clientes.length < 5) {
        final apellidoQuery = await _firestore
            .collection(_clientesCollection)
            .orderBy('apePat')
            .startAt([queryLower])
            .endAt([queryLower + '\uf8ff'])
            .limit(5)
            .get();

        final clientesPorApellido = apellidoQuery.docs
            .map((doc) => ClienteModel.fromFirestore(doc.data(), doc.id))
            .where((cliente) => !clientes.any((c) => c.id == cliente.id))
            .toList();

        clientes.addAll(clientesPorApellido);
      }

      return clientes;
    } catch (e) {
      debugPrint('Error buscando clientes: $e');
      return [];
    }
  }

  // Actualizar cliente
  Future<bool> actualizarCliente(String clienteId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(_clientesCollection)
          .doc(clienteId)
          .update(updates);

      debugPrint('Cliente actualizado exitosamente: $clienteId');
      return true;
    } catch (e) {
      debugPrint('Error actualizando cliente: $e');
      return false;
    }
  }

  // Eliminar cliente
  Future<bool> eliminarCliente(String clienteId) async {
    try {
      // Verificar si el cliente tiene ventas asociadas
      final clienteRef = _firestore.collection(_clientesCollection).doc(clienteId);
      final ventasQuery = await _firestore
          .collection('ventas')
          .where('cliRef', isEqualTo: clienteRef)
          .limit(1)
          .get();

      if (ventasQuery.docs.isNotEmpty) {
        debugPrint('No se puede eliminar cliente con ventas asociadas');
        return false;
      }

      await _firestore
          .collection(_clientesCollection)
          .doc(clienteId)
          .delete();

      debugPrint('Cliente eliminado exitosamente: $clienteId');
      return true;
    } catch (e) {
      debugPrint('Error eliminando cliente: $e');
      return false;
    }
  }

  // Método para limpiar datos huérfanos (solo para administradores)
  Future<Map<String, dynamic>> limpiarDatosHuerfanos() async {
    try {
      int ventasLimpiadas = 0;
      int stockRestaurado = 0;

      // Obtener todas las ventas
      final ventasSnapshot = await _firestore.collection('ventas').get();
      
      for (final ventaDoc in ventasSnapshot.docs) {
        final ventaData = ventaDoc.data();
        final clienteRef = ventaData['cliRef'] as DocumentReference?;
        
        if (clienteRef != null) {
          // Verificar si el cliente existe
          final clienteDoc = await clienteRef.get();
          
          if (!clienteDoc.exists) {
            // Cliente no existe, esta venta es huérfana
            debugPrint('Venta huérfana encontrada: ${ventaDoc.id}');
            
            // Si era venta nueva o préstamo, restaurar stock
            final tipoVenta = ventaData['tp'] as String?;
            final cantidad = ventaData['cant'] as int? ?? 0;
            
            if ((tipoVenta == 'nueva' || tipoVenta == 'prestamo') && cantidad > 0) {
              // Restaurar stock al inventario
              final inventarioDoc = await _firestore
                  .collection('inventario')
                  .doc('bidones')
                  .get();
              
              if (inventarioDoc.exists) {
                final inventarioData = inventarioDoc.data()!;
                final stockActual = inventarioData['stockDisponible'] as int? ?? 0;
                final nuevoStock = stockActual + cantidad;
                
                await _firestore
                    .collection('inventario')
                    .doc('bidones')
                    .update({
                  'stockDisponible': nuevoStock,
                  'fechaActualizacion': FieldValue.serverTimestamp(),
                });
                
                stockRestaurado += cantidad;
                debugPrint('Stock restaurado: $cantidad bidones');
              }
            }
            
            // Eliminar la venta huérfana
            await ventaDoc.reference.delete();
            ventasLimpiadas++;
          }
        }
      }

      return {
        'ventasLimpiadas': ventasLimpiadas,
        'stockRestaurado': stockRestaurado,
        'mensaje': ventasLimpiadas > 0 
            ? 'Se limpiaron $ventasLimpiadas ventas huérfanas y se restauraron $stockRestaurado bidones al inventario'
            : 'No se encontraron datos huérfanos',
      };
    } catch (e) {
      debugPrint('Error limpiando datos huérfanos: $e');
      return {
        'ventasLimpiadas': 0,
        'stockRestaurado': 0,
        'error': 'Error durante la limpieza: $e',
      };
    }
  }

  // Verificar integridad de datos
  Future<Map<String, dynamic>> verificarIntegridadDatos() async {
    try {
      int ventasHuerfanas = 0;
      int clientesSinVentas = 0;
      
      // Verificar ventas huérfanas
      final ventasSnapshot = await _firestore.collection('ventas').get();
      
      for (final ventaDoc in ventasSnapshot.docs) {
        final ventaData = ventaDoc.data();
        final clienteRef = ventaData['cliRef'] as DocumentReference?;
        
        if (clienteRef != null) {
          final clienteDoc = await clienteRef.get();
          if (!clienteDoc.exists) {
            ventasHuerfanas++;
          }
        }
      }

      // Verificar clientes sin ventas (opcional, para estadísticas)
      final clientesSnapshot = await _firestore.collection(_clientesCollection).get();
      
      for (final clienteDoc in clientesSnapshot.docs) {
        final clienteRef = _firestore.collection(_clientesCollection).doc(clienteDoc.id);
        final ventasCliente = await _firestore
            .collection('ventas')
            .where('cliRef', isEqualTo: clienteRef)
            .limit(1)
            .get();
        
        if (ventasCliente.docs.isEmpty) {
          clientesSinVentas++;
        }
      }

      return {
        'ventasHuerfanas': ventasHuerfanas,
        'clientesSinVentas': clientesSinVentas,
        'totalClientes': clientesSnapshot.docs.length,
        'totalVentas': ventasSnapshot.docs.length,
        'integridad': ventasHuerfanas == 0 ? 'Buena' : 'Problemas detectados',
      };
    } catch (e) {
      debugPrint('Error verificando integridad: $e');
      return {
        'error': 'Error verificando integridad: $e',
      };
    }
  }

  // Obtener clientes por distrito
  Future<List<ClienteModel>> obtenerClientesPorDistrito(String distrito) async {
    try {
      final querySnapshot = await _firestore
          .collection(_clientesCollection)
          .where('distrito', isEqualTo: distrito)
          .orderBy('fhCre', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ClienteModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo clientes por distrito: $e');
      return [];
    }
  }

  // Obtener estadísticas de clientes
  Future<Map<String, int>> obtenerEstadisticasClientes() async {
    try {
      final querySnapshot = await _firestore
          .collection(_clientesCollection)
          .get();

      final clientes = querySnapshot.docs
          .map((doc) => ClienteModel.fromFirestore(doc.data(), doc.id))
          .toList();

      final hoy = DateTime.now();
      final inicioMes = DateTime(hoy.year, hoy.month, 1);
      final inicioSemana = hoy.subtract(Duration(days: hoy.weekday - 1));

      return {
        'total': clientes.length,
        'nuevosEsteMes': clientes
            .where((c) => c.fechaCreacion.isAfter(inicioMes))
            .length,
        'nuevosEstaSemana': clientes
            .where((c) => c.fechaCreacion.isAfter(inicioSemana))
            .length,
      };
    } catch (e) {
      debugPrint('Error obteniendo estadísticas de clientes: $e');
      return {'total': 0, 'nuevosEsteMes': 0, 'nuevosEstaSemana': 0};
    }
  }

  // Stream para escuchar cambios en tiempo real
  Stream<List<ClienteModel>> escucharClientes() {
    return _firestore
        .collection(_clientesCollection)
        .orderBy('fhCre', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClienteModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
