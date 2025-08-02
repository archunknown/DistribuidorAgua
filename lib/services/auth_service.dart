import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'usuarios';
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  UserModel? _currentUser;
  
  // Getter para usuario actual
  UserModel? get currentUser => _currentUser;
  
  // Método de login con Firestore
  Future<UserModel?> login(String usuario, String password) async {
    try {
      // Buscar usuario en Firestore
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('usuario', isEqualTo: usuario)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        debugPrint('Usuario no encontrado: $usuario');
        return null;
      }
      
      final userDoc = querySnapshot.docs.first;
      final userData = userDoc.data();
      
      // Verificar contraseña (en producción debería estar hasheada)
      if (userData['pass'] != password) {
        debugPrint('Contraseña incorrecta para usuario: $usuario');
        return null;
      }
      
      final user = UserModel.fromFirestore(userData, userDoc.id);
      _currentUser = user;
      debugPrint('Login exitoso para usuario: ${user.nombreCompleto}');
      return user;
      
    } catch (e) {
      debugPrint('Error en login: $e');
      return null;
    }
  }
  
  // Método para obtener usuario actual
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }
  
  // Método de logout
  Future<void> logout() async {
    _currentUser = null;
  }
  
  // Verificar si el usuario está logueado
  bool isLoggedIn() {
    return _currentUser != null;
  }
  
  // Crear nuevo usuario (solo para admin)
  Future<bool> createUser({
    required String usuario,
    required String password,
    required String nombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String rol,
  }) async {
    try {
      // Verificar que el usuario actual sea admin
      if (_currentUser == null || !_currentUser!.isAdmin) {
        throw Exception('Solo los administradores pueden crear usuarios');
      }
      
      // Verificar que el usuario no exista
      final existingUser = await _firestore
          .collection(_usersCollection)
          .where('usuario', isEqualTo: usuario)
          .get();
      
      if (existingUser.docs.isNotEmpty) {
        throw Exception('El usuario ya existe');
      }
      
      // Crear nuevo usuario
      await _firestore.collection(_usersCollection).add({
        'usuario': usuario,
        'pass': password, // TODO: Hashear contraseña
        'nom': nombre,
        'apePat': apellidoPaterno,
        'apeMat': apellidoMaterno,
        'rol': rol,
        'fhCre': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error creando usuario: $e');
      return false;
    }
  }
  
  // Obtener todos los usuarios (solo para admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      if (_currentUser == null || !_currentUser!.isAdmin) {
        throw Exception('Solo los administradores pueden ver todos los usuarios');
      }
      
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .orderBy('fhCre', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error obteniendo usuarios: $e');
      return [];
    }
  }
  
  // Actualizar usuario
  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      if (_currentUser == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Solo admin puede actualizar otros usuarios, o el usuario puede actualizarse a sí mismo
      if (!_currentUser!.isAdmin && _currentUser!.id != userId) {
        throw Exception('No tienes permisos para actualizar este usuario');
      }
      
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update(updates);
      
      return true;
    } catch (e) {
      debugPrint('Error actualizando usuario: $e');
      return false;
    }
  }
  
  // Eliminar usuario (solo admin)
  Future<bool> deleteUser(String userId) async {
    try {
      if (_currentUser == null || !_currentUser!.isAdmin) {
        throw Exception('Solo los administradores pueden eliminar usuarios');
      }
      
      // No permitir que el admin se elimine a sí mismo
      if (_currentUser!.id == userId) {
        throw Exception('No puedes eliminarte a ti mismo');
      }
      
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .delete();
      
      return true;
    } catch (e) {
      debugPrint('Error eliminando usuario: $e');
      return false;
    }
  }
}
