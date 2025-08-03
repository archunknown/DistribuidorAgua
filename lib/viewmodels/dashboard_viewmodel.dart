import 'package:flutter/material.dart';
import '../models/venta_model.dart';
import '../models/inventario_model.dart';
import '../services/venta_service.dart';
import '../services/inventario_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final VentaService _ventaService = VentaService();
  final InventarioService _inventarioService = InventarioService();

  bool _isLoading = false;
  Map<String, dynamic> _estadisticas = {};
  List<VentaModel> _ventasRecientes = [];
  InventarioModel? _inventario;
  List<String> _alertasInventario = [];

  // Getters
  bool get isLoading => _isLoading;
  Map<String, dynamic> get estadisticas => _estadisticas;
  List<VentaModel> get ventasRecientes => _ventasRecientes;
  InventarioModel? get inventario => _inventario;
  List<String> get alertasInventario => _alertasInventario;

  // Inicializar datos del dashboard
  Future<void> inicializar() async {
    await _cargarDatos();
  }

  // Cargar todos los datos necesarios
  Future<void> _cargarDatos() async {
    _setLoading(true);
    
    try {
      await Future.wait([
        _cargarEstadisticas(),
        _cargarVentasRecientes(),
        _cargarInventario(),
        _cargarAlertas(),
      ]);
    } catch (e) {
      debugPrint('Error cargando datos del dashboard: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Cargar estadísticas de ventas
  Future<void> _cargarEstadisticas() async {
    try {
      _estadisticas = await _ventaService.obtenerEstadisticasVentas();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    }
  }

  // Cargar ventas recientes del día
  Future<void> _cargarVentasRecientes() async {
    try {
      _ventasRecientes = await _ventaService.obtenerVentasDelDia();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando ventas recientes: $e');
    }
  }

  // Cargar información del inventario
  Future<void> _cargarInventario() async {
    try {
      _inventario = await _inventarioService.obtenerInventario();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando inventario: $e');
    }
  }

  // Cargar alertas de inventario
  Future<void> _cargarAlertas() async {
    try {
      final alertas = await _inventarioService.verificarAlertas();
      _alertasInventario = List<String>.from(alertas['alertas'] ?? []);
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando alertas: $e');
    }
  }

  // Refrescar datos
  Future<void> refrescar() async {
    await _cargarDatos();
  }

  // Refrescar solo estadísticas (para actualizaciones rápidas)
  Future<void> refrescarEstadisticas() async {
    await _cargarEstadisticas();
    await _cargarVentasRecientes();
  }

  // Refrescar solo inventario
  Future<void> refrescarInventario() async {
    await _cargarInventario();
    await _cargarAlertas();
  }

  // Obtener resumen rápido para mostrar en cards
  Map<String, dynamic> get resumenRapido {
    final hoy = _estadisticas['hoy'] ?? {};
    final semana = _estadisticas['semana'] ?? {};
    final mes = _estadisticas['mes'] ?? {};

    return {
      'ventasHoy': hoy['cantidad'] ?? 0,
      'ingresosHoy': hoy['total'] ?? 0.0,
      'gananciasHoy': hoy['ganancias'] ?? 0.0,
      'ventasSemana': semana['cantidad'] ?? 0,
      'ingresosSemana': semana['total'] ?? 0.0,
      'ventasMes': mes['cantidad'] ?? 0,
      'ingresosMes': mes['total'] ?? 0.0,
      'stockDisponible': _inventario?.stockDisponible ?? 0,
      'stockTotal': _inventario?.stockTotal ?? 0,
      'porcentajeStock': _inventario?.porcentajeDisponible ?? 0.0,
    };
  }

  // Verificar si hay alertas críticas
  bool get hayAlertasCriticas {
    return _alertasInventario.isNotEmpty || 
           (_inventario?.stockCritico == true);
  }

  // Obtener color del estado del stock
  Color get colorEstadoStock {
    if (_inventario == null) return Colors.grey;
    
    if (_inventario!.sinStock || _inventario!.stockCritico) {
      return Colors.red;
    } else if (_inventario!.stockBajo) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  // Obtener texto del estado del stock
  String get textoEstadoStock {
    if (_inventario == null) return 'Sin datos';
    return _inventario!.estadoStock;
  }

  // Obtener tendencia de ventas (comparación con período anterior)
  Map<String, dynamic> get tendenciaVentas {
    final hoy = _estadisticas['hoy'] ?? {};
    final semana = _estadisticas['semana'] ?? {};
    
    // Simulamos comparación (en implementación real se compararía con períodos anteriores)
    return {
      'ventasHoyTendencia': 'estable', // 'subiendo', 'bajando', 'estable'
      'ingresosSemanaTendencia': 'subiendo',
      'porcentajeCambio': 15.5, // Porcentaje de cambio
    };
  }

  // Obtener distribución de tipos de venta del mes
  Map<String, int> get distribucionTiposVenta {
    final mes = _estadisticas['mes'] ?? {};
    return {
      'nuevas': mes['ventasNuevas'] ?? 0,
      'recargas': mes['recargas'] ?? 0,
      'prestamos': mes['prestamos'] ?? 0,
    };
  }

  // Método privado para manejar el estado de carga
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Limpiar datos al cerrar sesión
  void limpiar() {
    _estadisticas.clear();
    _ventasRecientes.clear();
    _inventario = null;
    _alertasInventario.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    limpiar();
    super.dispose();
  }
}
