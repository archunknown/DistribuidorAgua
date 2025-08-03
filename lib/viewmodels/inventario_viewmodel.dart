import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/inventario_model.dart';
import '../services/inventario_service.dart';

class InventarioViewModel extends ChangeNotifier {
  final InventarioService _inventarioService = InventarioService();

  // Estado de la vista
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Datos del inventario
  InventarioModel? _inventario;
  List<Map<String, dynamic>> _historialMovimientos = [];

  // Controladores separados para cada sección
  // Sección 1: Actualizar Stock Total
  final TextEditingController stockTotalController = TextEditingController();
  final TextEditingController motivoStockTotalController = TextEditingController();
  
  // Sección 2: Agregar Stock
  final TextEditingController agregarStockController = TextEditingController();
  final TextEditingController motivoAgregarController = TextEditingController();
  
  // Sección 3: Ajustar Stock Disponible
  final TextEditingController ajusteStockController = TextEditingController();
  final TextEditingController motivoAjusteController = TextEditingController();

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  InventarioModel? get inventario => _inventario;
  List<Map<String, dynamic>> get historialMovimientos => _historialMovimientos;

  // Estadísticas calculadas
  Map<String, dynamic> get estadisticasInventario {
    if (_inventario == null) {
      return {
        'stockTotal': 0,
        'stockDisponible': 0,
        'stockPrestado': 0,
        'porcentajeDisponible': 0.0,
        'alertaStockBajo': false,
      };
    }

    final stockPrestado = _inventario!.stockTotal - _inventario!.stockDisponible;
    final porcentajeDisponible = _inventario!.stockTotal > 0 
        ? (_inventario!.stockDisponible / _inventario!.stockTotal) * 100 
        : 0.0;
    
    return {
      'stockTotal': _inventario!.stockTotal,
      'stockDisponible': _inventario!.stockDisponible,
      'stockPrestado': stockPrestado,
      'porcentajeDisponible': porcentajeDisponible,
      'alertaStockBajo': _inventario!.stockBajo,
    };
  }

  // Inicializar datos
  Future<void> inicializar() async {
    await cargarInventario();
    await cargarHistorialMovimientos();
  }

  // Cargar inventario actual
  Future<void> cargarInventario() async {
    _setLoading(true);
    try {
      _inventario = await _inventarioService.obtenerInventario();
      _clearMessages();
    } catch (e) {
      _setError('Error cargando inventario: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Cargar historial de movimientos (simulado por ahora)
  Future<void> cargarHistorialMovimientos() async {
    try {
      // Por ahora simulamos el historial, en el futuro se podría crear una colección separada
      _historialMovimientos = [
        {
          'fecha': DateTime.now().subtract(const Duration(days: 1)),
          'tipo': 'Compra',
          'cantidad': 50,
          'motivo': 'Compra inicial de bidones',
          'stockResultante': _inventario?.stockTotal ?? 0,
        },
        {
          'fecha': DateTime.now().subtract(const Duration(days: 2)),
          'tipo': 'Ajuste',
          'cantidad': -5,
          'motivo': 'Bidones dañados',
          'stockResultante': (_inventario?.stockTotal ?? 0) - 50,
        },
      ];
    } catch (e) {
      _setError('Error cargando historial: $e');
    }
  }

  // Actualizar stock total (primera vez o ajuste mayor)
  Future<bool> actualizarStockTotal(int nuevoStockTotal, String motivo, UserModel usuarioActual) async {
    _clearMessages();
    
    if (nuevoStockTotal <= 0) {
      _setError('El stock total debe ser mayor a 0');
      return false;
    }

    if (motivo.trim().isEmpty) {
      _setError('El motivo es obligatorio');
      return false;
    }

    _setLoading(true);
    
    try {
      final success = await _inventarioService.actualizarStockTotal(nuevoStockTotal, usuarioActual);
      
      if (success) {
        _setSuccess('Stock total actualizado correctamente');
        await cargarInventario();
        
        // Agregar al historial
        _historialMovimientos.insert(0, {
          'fecha': DateTime.now(),
          'tipo': 'Actualización Total',
          'cantidad': nuevoStockTotal,
          'motivo': motivo,
          'stockResultante': nuevoStockTotal,
        });
        
        stockTotalController.clear();
        motivoStockTotalController.clear();
        return true;
      } else {
        _setError('Error al actualizar el stock total');
        return false;
      }
    } catch (e) {
      _setError('Error actualizando stock total: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Agregar stock (compra de nuevos bidones)
  Future<bool> agregarStock(int cantidad, String motivo, UserModel usuarioActual) async {
    _clearMessages();
    
    if (cantidad <= 0) {
      _setError('La cantidad debe ser mayor a 0');
      return false;
    }

    if (motivo.trim().isEmpty) {
      _setError('El motivo es obligatorio');
      return false;
    }

    _setLoading(true);
    
    try {
      final success = await _inventarioService.agregarStock(cantidad, usuarioActual);
      
      if (success) {
        _setSuccess('Stock agregado correctamente');
        await cargarInventario();
        
        // Agregar al historial
        _historialMovimientos.insert(0, {
          'fecha': DateTime.now(),
          'tipo': 'Compra',
          'cantidad': cantidad,
          'motivo': motivo,
          'stockResultante': _inventario?.stockTotal ?? 0,
        });
        
        agregarStockController.clear();
        motivoAgregarController.clear();
        return true;
      } else {
        _setError('Error al agregar stock');
        return false;
      }
    } catch (e) {
      _setError('Error agregando stock: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Ajustar stock disponible (correcciones manuales)
  Future<bool> ajustarStockDisponible(int cantidad, String motivo) async {
    _clearMessages();
    
    if (cantidad == 0) {
      _setError('La cantidad no puede ser 0');
      return false;
    }

    if (motivo.trim().isEmpty) {
      _setError('El motivo es obligatorio');
      return false;
    }

    _setLoading(true);
    
    try {
      bool success;
      
      if (cantidad > 0) {
        // Aumentar stock disponible
        success = await _inventarioService.aumentarStock(cantidad);
      } else {
        // Reducir stock disponible
        success = await _inventarioService.reducirStock(cantidad.abs());
      }
      
      if (success) {
        _setSuccess('Stock ajustado correctamente');
        await cargarInventario();
        
        // Agregar al historial
        _historialMovimientos.insert(0, {
          'fecha': DateTime.now(),
          'tipo': cantidad > 0 ? 'Ajuste +' : 'Ajuste -',
          'cantidad': cantidad,
          'motivo': motivo,
          'stockResultante': _inventario?.stockDisponible ?? 0,
        });
        
        ajusteStockController.clear();
        motivoAjusteController.clear();
        return true;
      } else {
        _setError('Error al ajustar stock');
        return false;
      }
    } catch (e) {
      _setError('Error ajustando stock: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Obtener alertas de inventario
  List<String> get alertasInventario {
    final alertas = <String>[];
    
    if (_inventario == null) return alertas;
    
    if (_inventario!.stockBajo) {
      alertas.add('Stock bajo: Solo ${_inventario!.stockDisponible} bidones disponibles');
    }
    
    if (_inventario!.stockDisponible == 0) {
      alertas.add('¡Sin stock disponible! No se pueden realizar ventas nuevas');
    }
    
    final stats = estadisticasInventario;
    final porcentajePrestado = stats['porcentajeDisponible'] as double;
    
    if (porcentajePrestado < 20) {
      alertas.add('Más del 80% del stock está prestado a clientes');
    }
    
    return alertas;
  }

  // Simular movimiento por venta (para mostrar en historial)
  void registrarMovimientoPorVenta(String tipoVenta, int cantidad) {
    if (tipoVenta == 'nueva' || tipoVenta == 'prestamo') {
      _historialMovimientos.insert(0, {
        'fecha': DateTime.now(),
        'tipo': 'Venta',
        'cantidad': -cantidad,
        'motivo': 'Venta de ${tipoVenta == 'nueva' ? 'bidón nuevo' : 'préstamo'}',
        'stockResultante': _inventario?.stockDisponible ?? 0,
      });
      notifyListeners();
    }
  }

  // Refrescar datos
  Future<void> refrescar() async {
    await cargarInventario();
    await cargarHistorialMovimientos();
  }

  // Validar formulario de stock inicial
  String? validarStockInicial(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }
    
    final cantidad = int.tryParse(value);
    if (cantidad == null || cantidad <= 0) {
      return 'Debe ser un número mayor a 0';
    }
    
    return null;
  }

  // Validar formulario de ajuste
  String? validarAjuste(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }
    
    final ajuste = int.tryParse(value);
    if (ajuste == null || ajuste == 0) {
      return 'Debe ser un número diferente de 0';
    }
    
    return null;
  }

  // Validar motivo
  String? validarMotivo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El motivo es obligatorio';
    }
    
    if (value.trim().length < 5) {
      return 'El motivo debe tener al menos 5 caracteres';
    }
    
    return null;
  }

  // Métodos de utilidad
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _successMessage = null;
    notifyListeners();
  }

  void _setSuccess(String success) {
    _successMessage = success;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() => _clearMessages();

  @override
  void dispose() {
    // Sección 1: Actualizar Stock Total
    stockTotalController.dispose();
    motivoStockTotalController.dispose();
    
    // Sección 2: Agregar Stock
    agregarStockController.dispose();
    motivoAgregarController.dispose();
    
    // Sección 3: Ajustar Stock Disponible
    ajusteStockController.dispose();
    motivoAjusteController.dispose();
    
    super.dispose();
  }
}
