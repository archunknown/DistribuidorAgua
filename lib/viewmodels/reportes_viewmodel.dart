import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reporte_model.dart';
import '../models/user_model.dart';
import '../services/reporte_service.dart';
import '../services/export_service.dart';

class ReportesViewModel extends ChangeNotifier {
  final ReporteService _reporteService = ReporteService();

  // Estado de la vista
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Datos de reportes
  ReporteVentas? _reporteActual;
  List<EstadisticasPeriodo> _estadisticasPeriodo = [];
  FiltroReporte _filtroActual = FiltroReporte(tipoReporte: TipoReporte.diario);

  // Controladores para filtros
  final TextEditingController fechaInicioController = TextEditingController();
  final TextEditingController fechaFinController = TextEditingController();
  final TextEditingController clienteBusquedaController = TextEditingController();

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  ReporteVentas? get reporteActual => _reporteActual;
  List<EstadisticasPeriodo> get estadisticasPeriodo => _estadisticasPeriodo;
  FiltroReporte get filtroActual => _filtroActual;

  // Estadísticas calculadas del reporte actual
  Map<String, dynamic> get estadisticasReporte {
    if (_reporteActual == null) {
      return {
        'totalVentas': 0,
        'totalIngresos': 0.0,
        'totalGanancias': 0.0,
        'margenGanancia': 0.0,
        'promedioVenta': 0.0,
        'ventasPorTipo': <String, int>{},
        'ingresosPorTipo': <String, double>{},
      };
    }

    return {
      'totalVentas': _reporteActual!.totalVentas,
      'totalIngresos': _reporteActual!.totalIngresos,
      'totalGanancias': _reporteActual!.totalGanancias,
      'margenGanancia': _reporteActual!.margenGanancia,
      'promedioVenta': _reporteActual!.promedioVenta,
      'ventasPorTipo': _reporteActual!.ventasPorTipo,
      'ingresosPorTipo': _reporteActual!.ingresosPorTipo,
    };
  }

  // Inicializar con reporte del día actual
  Future<void> inicializar() async {
    await generarReporte();
  }

  // Generar reporte con filtros actuales
  Future<void> generarReporte() async {
    _setLoading(true);
    _clearMessages();

    try {
      _reporteActual = await _reporteService.generarReporteVentas(_filtroActual);
      
      // Obtener estadísticas para gráficos
      if (_reporteActual != null) {
        _estadisticasPeriodo = await _reporteService.obtenerEstadisticasPeriodo(
          _filtroActual.tipoReporte,
          _reporteActual!.fechaInicio,
          _reporteActual!.fechaFin,
        );
      }

      _setSuccess('Reporte generado exitosamente');
    } catch (e) {
      _setError('Error generando reporte: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Cambiar tipo de reporte
  Future<void> cambiarTipoReporte(TipoReporte nuevoTipo) async {
    if (_filtroActual.tipoReporte != nuevoTipo) {
      _filtroActual = _filtroActual.copyWith(tipoReporte: nuevoTipo);
      
      // Limpiar fechas personalizadas si no es personalizado
      if (nuevoTipo != TipoReporte.personalizado) {
        _filtroActual = _filtroActual.copyWith(
          fechaInicio: null,
          fechaFin: null,
        );
        fechaInicioController.clear();
        fechaFinController.clear();
      }
      
      await generarReporte();
    }
  }

  // Establecer período personalizado
  Future<void> establecerPeriodoPersonalizado(DateTime fechaInicio, DateTime fechaFin) async {
    if (fechaInicio.isAfter(fechaFin)) {
      _setError('La fecha de inicio debe ser anterior a la fecha de fin');
      return;
    }

    _filtroActual = _filtroActual.copyWith(
      tipoReporte: TipoReporte.personalizado,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );

    fechaInicioController.text = DateFormat('dd/MM/yyyy').format(fechaInicio);
    fechaFinController.text = DateFormat('dd/MM/yyyy').format(fechaFin);

    await generarReporte();
  }

  // Filtrar por tipo de venta
  Future<void> filtrarPorTipoVenta(String? tipoVenta) async {
    _filtroActual = _filtroActual.copyWith(tipoVenta: tipoVenta);
    await generarReporte();
  }

  // Filtrar por cliente
  Future<void> filtrarPorCliente(String? clienteId) async {
    _filtroActual = _filtroActual.copyWith(clienteId: clienteId);
    await generarReporte();
  }

  // Limpiar filtros
  Future<void> limpiarFiltros() async {
    _filtroActual = FiltroReporte(tipoReporte: TipoReporte.diario);
    fechaInicioController.clear();
    fechaFinController.clear();
    clienteBusquedaController.clear();
    await generarReporte();
  }

  // Obtener datos para gráfico de barras (ventas por período)
  List<Map<String, dynamic>> get datosGraficoVentas {
    return _estadisticasPeriodo.map((stat) => {
      'periodo': stat.periodo,
      'ventas': stat.ventas,
      'ingresos': stat.ingresos,
      'ganancias': stat.ganancias,
    }).toList();
  }

  // Obtener datos para gráfico circular (ventas por tipo)
  List<Map<String, dynamic>> get datosGraficoTipos {
    if (_reporteActual == null) return [];

    return _reporteActual!.ventasPorTipo.entries.map((entry) => {
      'tipo': _getTipoVentaDisplayName(entry.key),
      'cantidad': entry.value,
      'porcentaje': _reporteActual!.totalVentas > 0 
          ? (entry.value / _reporteActual!.totalVentas) * 100 
          : 0.0,
    }).toList();
  }

  // Obtener datos para gráfico de ingresos por tipo
  List<Map<String, dynamic>> get datosGraficoIngresos {
    if (_reporteActual == null) return [];

    return _reporteActual!.ingresosPorTipo.entries.map((entry) => {
      'tipo': _getTipoVentaDisplayName(entry.key),
      'ingresos': entry.value,
      'porcentaje': _reporteActual!.totalIngresos > 0 
          ? (entry.value / _reporteActual!.totalIngresos) * 100 
          : 0.0,
    }).toList();
  }

  // Obtener resumen de comparación con períodos anteriores
  Future<Map<String, dynamic>> obtenerComparacionPeriodos() async {
    if (_reporteActual == null) return {};

    try {
      // Calcular período anterior
      final duracion = _reporteActual!.fechaFin.difference(_reporteActual!.fechaInicio);
      final fechaInicioAnterior = _reporteActual!.fechaInicio.subtract(duracion);
      final fechaFinAnterior = _reporteActual!.fechaInicio.subtract(const Duration(days: 1));

      final filtroAnterior = _filtroActual.copyWith(
        tipoReporte: TipoReporte.personalizado,
        fechaInicio: fechaInicioAnterior,
        fechaFin: fechaFinAnterior,
      );

      final reporteAnterior = await _reporteService.generarReporteVentas(filtroAnterior);

      // Calcular variaciones
      final variacionVentas = _calcularVariacion(
        _reporteActual!.totalVentas.toDouble(), 
        reporteAnterior.totalVentas.toDouble()
      );
      
      final variacionIngresos = _calcularVariacion(
        _reporteActual!.totalIngresos, 
        reporteAnterior.totalIngresos
      );
      
      final variacionGanancias = _calcularVariacion(
        _reporteActual!.totalGanancias, 
        reporteAnterior.totalGanancias
      );

      return {
        'periodoAnterior': {
          'ventas': reporteAnterior.totalVentas,
          'ingresos': reporteAnterior.totalIngresos,
          'ganancias': reporteAnterior.totalGanancias,
        },
        'variaciones': {
          'ventas': variacionVentas,
          'ingresos': variacionIngresos,
          'ganancias': variacionGanancias,
        },
      };
    } catch (e) {
      debugPrint('Error obteniendo comparación: $e');
      return {};
    }
  }

  // Exportar reporte
  Future<String> exportarReporte(String formato) async {
    if (_reporteActual == null) {
      throw Exception('No hay reporte para exportar');
    }

    _setLoading(true);
    
    try {
      final exportService = ExportService();
      String filePath;
      
      if (formato.toLowerCase() == 'pdf') {
        filePath = await exportService.exportarPDF(_reporteActual!);
      } else if (formato.toLowerCase() == 'excel' || formato.toLowerCase() == 'xlsx') {
        filePath = await exportService.exportarExcel(_reporteActual!);
      } else {
        throw Exception('Formato no soportado: $formato');
      }
      
      final fileName = filePath.split('/').last;
      final directory = filePath.contains('/Download/') ? 'Descargas' : 
                       filePath.contains('/Downloads/') ? 'Descargas' : 
                       'Documentos de la aplicación';
      _setSuccess('Reporte exportado exitosamente en $directory: $fileName');
      return filePath;
    } catch (e) {
      _setError('Error exportando reporte: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Compartir reporte en PDF
  Future<void> compartirReporte() async {
    if (_reporteActual == null) {
      throw Exception('No hay reporte para compartir');
    }

    _setLoading(true);
    
    try {
      final exportService = ExportService();
      await exportService.compartirPDF(_reporteActual!);
      _setSuccess('Reporte compartido exitosamente');
    } catch (e) {
      _setError('Error compartiendo reporte: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Obtener sugerencias de mejora basadas en el reporte
  List<String> get sugerenciasMejora {
    if (_reporteActual == null) return [];

    final sugerencias = <String>[];

    // Análisis de margen de ganancia
    if (_reporteActual!.margenGanancia < 30) {
      sugerencias.add('El margen de ganancia es bajo (${_reporteActual!.margenGanancia.toStringAsFixed(1)}%). Considera revisar los precios o costos.');
    }

    // Análisis de tipos de venta
    final ventasPorTipo = _reporteActual!.ventasPorTipo;
    final totalVentas = _reporteActual!.totalVentas;
    
    if (totalVentas > 0) {
      final porcentajeNuevas = ((ventasPorTipo['nueva'] ?? 0) / totalVentas) * 100;
      final porcentajeRecargas = ((ventasPorTipo['recarga'] ?? 0) / totalVentas) * 100;
      
      if (porcentajeNuevas > 70) {
        sugerencias.add('Alto porcentaje de ventas nuevas (${porcentajeNuevas.toStringAsFixed(1)}%). Enfócate en fidelizar clientes para más recargas.');
      }
      
      if (porcentajeRecargas < 20) {
        sugerencias.add('Pocas recargas (${porcentajeRecargas.toStringAsFixed(1)}%). Implementa estrategias de retención de clientes.');
      }
    }

    // Análisis de clientes top
    if (_reporteActual!.clientesTop.length < 5) {
      sugerencias.add('Pocos clientes frecuentes. Considera programas de fidelización.');
    }

    return sugerencias;
  }

  // Métodos auxiliares
  String _getTipoVentaDisplayName(String tipo) {
    switch (tipo) {
      case 'nueva':
        return 'Venta Nueva';
      case 'recarga':
        return 'Recarga';
      case 'prestamo':
        return 'Préstamo';
      default:
        return tipo;
    }
  }

  double _calcularVariacion(double actual, double anterior) {
    if (anterior == 0) return actual > 0 ? 100 : 0;
    return ((actual - anterior) / anterior) * 100;
  }

  // Validaciones
  String? validarFecha(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }
    
    try {
      DateFormat('dd/MM/yyyy').parse(value);
      return null;
    } catch (e) {
      return 'Formato de fecha inválido (dd/MM/yyyy)';
    }
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
    fechaInicioController.dispose();
    fechaFinController.dispose();
    clienteBusquedaController.dispose();
    super.dispose();
  }
}
