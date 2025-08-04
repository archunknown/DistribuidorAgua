import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ResetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Singleton pattern
  static final ResetService _instance = ResetService._internal();
  factory ResetService() => _instance;
  ResetService._internal();

  // Resetear todos los datos de la aplicación (SOLO PARA DESARROLLO)
  Future<Map<String, dynamic>> resetearTodosLosDatos() async {
    try {
      int clientesEliminados = 0;
      int ventasEliminadas = 0;
      bool inventarioReseteado = false;

      // 1. Eliminar todas las ventas
      final ventasSnapshot = await _firestore.collection('ventas').get();
      for (final doc in ventasSnapshot.docs) {
        await doc.reference.delete();
        ventasEliminadas++;
      }
      debugPrint('Ventas eliminadas: $ventasEliminadas');

      // 2. Eliminar todos los clientes
      final clientesSnapshot = await _firestore.collection('clientes').get();
      for (final doc in clientesSnapshot.docs) {
        await doc.reference.delete();
        clientesEliminados++;
      }
      debugPrint('Clientes eliminados: $clientesEliminados');

      // 3. Resetear inventario a valores iniciales
      await _firestore.collection('inventario').doc('bidones').set({
        'stockTotal': 100,
        'stockDisponible': 100,
        'fechaActualizacion': FieldValue.serverTimestamp(),
      });
      inventarioReseteado = true;
      debugPrint('Inventario reseteado');

      // 4. Limpiar cualquier otra colección de prueba
      try {
        final pruebaSnapshot = await _firestore.collection('prueba').get();
        for (final doc in pruebaSnapshot.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        // Ignorar si no existe la colección de prueba
      }

      return {
        'success': true,
        'clientesEliminados': clientesEliminados,
        'ventasEliminadas': ventasEliminadas,
        'inventarioReseteado': inventarioReseteado,
        'mensaje': 'Todos los datos han sido reseteados exitosamente',
      };
    } catch (e) {
      debugPrint('Error reseteando datos: $e');
      return {
        'success': false,
        'error': 'Error durante el reseteo: $e',
      };
    }
  }

  // Obtener estadísticas antes del reseteo
  Future<Map<String, dynamic>> obtenerEstadisticasActuales() async {
    try {
      final clientesSnapshot = await _firestore.collection('clientes').get();
      final ventasSnapshot = await _firestore.collection('ventas').get();
      final inventarioDoc = await _firestore.collection('inventario').doc('bidones').get();

      return {
        'totalClientes': clientesSnapshot.docs.length,
        'totalVentas': ventasSnapshot.docs.length,
        'stockActual': inventarioDoc.exists ? (inventarioDoc.data()?['stockDisponible'] ?? 0) : 0,
      };
    } catch (e) {
      debugPrint('Error obteniendo estadísticas: $e');
      return {
        'totalClientes': 0,
        'totalVentas': 0,
        'stockActual': 0,
      };
    }
  }

  // Crear datos de prueba (opcional)
  Future<bool> crearDatosDePrueba() async {
    try {
      debugPrint('🔧 RESET DEBUG - Creando datos de prueba con referencias correctas');
      
      // Primero verificar si existe un usuario admin
      final usuariosSnapshot = await _firestore.collection('usuarios').where('rol', isEqualTo: 'admin').limit(1).get();
      DocumentReference adminRef;
      
      if (usuariosSnapshot.docs.isNotEmpty) {
        adminRef = usuariosSnapshot.docs.first.reference;
        debugPrint('🔧 RESET DEBUG - Usuario admin encontrado: ${adminRef.id}');
      } else {
        // Crear usuario admin si no existe
        final adminDoc = await _firestore.collection('usuarios').add({
          'usuario': 'admin',
          'pass': 'admin123', // En producción debería estar hasheado
          'nom': 'Administrador',
          'apePat': 'Sistema',
          'apeMat': '',
          'rol': 'admin',
          'fhCre': FieldValue.serverTimestamp(),
        });
        adminRef = adminDoc;
        debugPrint('🔧 RESET DEBUG - Usuario admin creado: ${adminRef.id}');
      }
      
      // Crear algunos clientes de prueba con referencias DocumentReference correctas
      final clientesPrueba = [
        {
          'nom': 'Juan',
          'apePat': 'Pérez',
          'apeMat': 'García',
          'distrito': 'San Isidro',
          'referencia': 'Av. Principal 123',
          'tel': '987654321',
          'crePor': adminRef, // Usar DocumentReference
          'fhCre': FieldValue.serverTimestamp(),
        },
        {
          'nom': 'María',
          'apePat': 'López',
          'apeMat': 'Rodríguez',
          'distrito': 'Miraflores',
          'referencia': 'Jr. Las Flores 456',
          'tel': '912345678',
          'crePor': adminRef, // Usar DocumentReference
          'fhCre': FieldValue.serverTimestamp(),
        },
        {
          'nom': 'Carlos',
          'apePat': 'Mendoza',
          'apeMat': 'Silva',
          'distrito': 'Surco',
          'referencia': 'Calle Los Pinos 789',
          'tel': null,
          'crePor': adminRef, // Usar DocumentReference
          'fhCre': FieldValue.serverTimestamp(),
        },
      ];

      for (final clienteData in clientesPrueba) {
        debugPrint('🔧 RESET DEBUG - Creando cliente: ${clienteData['nom']}');
        await _firestore.collection('clientes').add(clienteData);
      }

      debugPrint('🔧 RESET DEBUG - Datos de prueba creados exitosamente');
      return true;
    } catch (e) {
      debugPrint('❌ RESET ERROR - Error creando datos de prueba: $e');
      return false;
    }
  }
}
