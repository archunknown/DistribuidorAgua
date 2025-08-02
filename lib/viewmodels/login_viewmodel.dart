import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  // Estado del login
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  UserModel? _currentUser;
  
  // Controladores de texto
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  
  // Setter para loading
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  // Setter para error
  set errorMessage(String? value) {
    _errorMessage = value;
    _successMessage = null; // Limpiar mensaje de éxito cuando hay error
    notifyListeners();
  }
  
  // Setter para mensaje de éxito
  set successMessage(String? value) {
    _successMessage = value;
    _errorMessage = null; // Limpiar mensaje de error cuando hay éxito
    notifyListeners();
  }
  
  // Método para limpiar errores
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Método para limpiar mensajes de éxito
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }
  
  // Método para limpiar todos los mensajes
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
  
  // Método para validar campos
  String? validateUsuario(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su usuario';
    }
    if (value.length < 3) {
      return 'El usuario debe tener al menos 3 caracteres';
    }
    return null;
  }
  
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese su contraseña';
    }
    if (value.length < 4) {
      return 'La contraseña debe tener al menos 4 caracteres';
    }
    return null;
  }
  
  // Método principal de login
  Future<bool> login() async {
    clearError();
    isLoading = true;
    
    try {
      final usuario = usuarioController.text.trim();
      final password = passwordController.text.trim();
      
      // Validaciones básicas
      if (usuario.isEmpty || password.isEmpty) {
        errorMessage = 'Por favor complete todos los campos';
        return false;
      }
      
      // Intentar login con el servicio de autenticación
      final user = await _authService.login(usuario, password);
      
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      } else {
        errorMessage = 'Usuario o contraseña incorrectos';
        return false;
      }
      
    } catch (e) {
      errorMessage = 'Error al iniciar sesión: ${e.toString()}';
      return false;
    } finally {
      isLoading = false;
    }
  }
  
  // Método para logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      _currentUser = null;
      usuarioController.clear();
      passwordController.clear();
      clearError();
      notifyListeners();
    } catch (e) {
      errorMessage = 'Error al cerrar sesión: ${e.toString()}';
    }
  }
  
  // Método para verificar sesión existente
  Future<void> checkExistingSession() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking existing session: $e');
    }
  }
  
  // Método para login con Firestore
  Future<bool> loginDemo() async {
    clearMessages();
    isLoading = true;
    
    try {
      final usuario = usuarioController.text.trim();
      final password = passwordController.text.trim();
      
      // Validaciones básicas
      if (usuario.isEmpty || password.isEmpty) {
        errorMessage = 'Por favor complete todos los campos';
        return false;
      }
      
      // Intentar login con el servicio de autenticación usando Firestore
      final user = await _authService.login(usuario, password);
      
      if (user != null) {
        _currentUser = user;
        successMessage = '¡Login exitoso! Bienvenido ${user.nombreCompleto}';
        notifyListeners();
        return true;
      } else {
        errorMessage = 'Usuario o contraseña incorrectos';
        return false;
      }
      
    } catch (e) {
      errorMessage = 'Error al iniciar sesión: ${e.toString()}';
      return false;
    } finally {
      isLoading = false;
    }
  }
  
  @override
  void dispose() {
    usuarioController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
