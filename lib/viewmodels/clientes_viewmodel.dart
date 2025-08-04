import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/cliente_model.dart';
import '../models/venta_model.dart';
import '../services/cliente_service.dart';
import '../services/venta_service.dart';

class ClientesViewModel extends ChangeNotifier {
  final ClienteService _clienteService = ClienteService();
  final VentaService _ventaService = VentaService();

  // Estado de la vista
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Datos
  List<ClienteModel> _clientes = [];
  List<ClienteModel> _clientesFiltrados = [];
  String _filtroActual = '';
  ClienteModel? _clienteSeleccionado;
  List<VentaModel> _ventasCliente = [];
  Map<String, dynamic> _estadisticasCliente = {};

  // Controladores para formulario
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidoPaternoController = TextEditingController();
  final TextEditingController apellidoMaternoController = TextEditingController();
  final TextEditingController distritoController = TextEditingController();
  final TextEditingController referenciaController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController busquedaController = TextEditingController();

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<ClienteModel> get clientes => _clientesFiltrados;
  List<ClienteModel> get todosLosClientes => _clientes;
  ClienteModel? get clienteSeleccionado => _clienteSeleccionado;
  List<VentaModel> get ventasCliente => _ventasCliente;
  Map<String, dynamic> get estadisticasCliente => _estadisticasCliente;
  String get filtroActual => _filtroActual;

  // Inicializar datos
  Future<void> inicializar() async {
    await cargarClientes();
  }

  // Cargar todos los clientes
  Future<void> cargarClientes() async {
    _setLoading(true);
    try {
      _clientes = await _clienteService.obtenerTodosLosClientes();
      _aplicarFiltro();
      _clearMessages();
    } catch (e) {
      _setError('Error cargando clientes: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Buscar clientes
  void buscarClientes(String query) {
    _filtroActual = query.toLowerCase();
    _aplicarFiltro();
  }

  // Aplicar filtro a la lista
  void _aplicarFiltro() {
    if (_filtroActual.isEmpty) {
      _clientesFiltrados = List.from(_clientes);
    } else {
      _clientesFiltrados = _clientes.where((cliente) {
        return cliente.nombreCompleto.toLowerCase().contains(_filtroActual) ||
               cliente.distrito.toLowerCase().contains(_filtroActual) ||
               cliente.referencia.toLowerCase().contains(_filtroActual) ||
               (cliente.telefono?.toLowerCase().contains(_filtroActual) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  // Seleccionar cliente para ver detalles
  Future<void> seleccionarCliente(ClienteModel cliente) async {
    _clienteSeleccionado = cliente;
    _setLoading(true);
    
    try {
      // Cargar ventas del cliente
      _ventasCliente = await _ventaService.obtenerVentasPorCliente(cliente.id);
      
      // Calcular estadísticas del cliente
      _calcularEstadisticasCliente();
      
      _clearMessages();
    } catch (e) {
      _setError('Error cargando datos del cliente: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Calcular estadísticas del cliente
  void _calcularEstadisticasCliente() {
    if (_ventasCliente.isEmpty) {
      _estadisticasCliente = {
        'totalVentas': 0,
        'montoTotal': 0.0,
        'ultimaCompra': null,
        'tipoPreferido': 'Sin datos',
        'frecuenciaCompras': 'Sin datos',
      };
      return;
    }

    final totalVentas = _ventasCliente.length;
    final montoTotal = _ventasCliente.fold<double>(0, (sum, venta) => sum + venta.total);
    final ultimaCompra = _ventasCliente.first.fechaHora;

    // Calcular tipo de venta preferido
    final tiposVenta = <TipoVenta, int>{};
    for (final venta in _ventasCliente) {
      tiposVenta[venta.tipo] = (tiposVenta[venta.tipo] ?? 0) + 1;
    }
    
    final tipoPreferido = tiposVenta.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key
        .displayName;

    // Calcular frecuencia de compras
    String frecuencia = 'Esporádico';
    if (_ventasCliente.length >= 10) {
      frecuencia = 'Muy frecuente';
    } else if (_ventasCliente.length >= 5) {
      frecuencia = 'Frecuente';
    } else if (_ventasCliente.length >= 2) {
      frecuencia = 'Regular';
    }

    _estadisticasCliente = {
      'totalVentas': totalVentas,
      'montoTotal': montoTotal,
      'ultimaCompra': ultimaCompra,
      'tipoPreferido': tipoPreferido,
      'frecuenciaCompras': frecuencia,
    };
  }

  // Crear nuevo cliente
  Future<bool> crearCliente(UserModel usuarioActual) async {
    _clearMessages();
    
    final validationError = _validarFormulario();
    if (validationError != null) {
      _setError(validationError);
      return false;
    }

    _setLoading(true);
    
    try {
      final clienteId = await _clienteService.crearCliente(
        nombre: nombreController.text.trim(),
        apellidoPaterno: apellidoPaternoController.text.trim(),
        apellidoMaterno: apellidoMaternoController.text.trim(),
        distrito: distritoController.text.trim(),
        referencia: referenciaController.text.trim(),
        telefono: telefonoController.text.trim().isEmpty ? null : telefonoController.text.trim(),
        usuarioActual: usuarioActual,
      );

      if (clienteId != null) {
        _setSuccess('Cliente creado exitosamente');
        _limpiarFormulario();
        await cargarClientes(); // Recargar lista
        return true;
      } else {
        _setError('Error al crear el cliente');
        return false;
      }
    } catch (e) {
      _setError('Error creando cliente: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Actualizar cliente existente
  Future<bool> actualizarCliente() async {
    if (_clienteSeleccionado == null) return false;
    
    _clearMessages();
    
    final validationError = _validarFormulario();
    if (validationError != null) {
      _setError(validationError);
      return false;
    }

    _setLoading(true);
    
    try {
      final updates = {
        'nom': nombreController.text.trim(),
        'apePat': apellidoPaternoController.text.trim(),
        'apeMat': apellidoMaternoController.text.trim(),
        'distrito': distritoController.text.trim(),
        'referencia': referenciaController.text.trim(),
        'tel': telefonoController.text.trim().isEmpty ? null : telefonoController.text.trim(),
      };

      final success = await _clienteService.actualizarCliente(_clienteSeleccionado!.id, updates);

      if (success) {
        _setSuccess('Cliente actualizado exitosamente');
        await cargarClientes(); // Recargar lista
        
        // Actualizar cliente seleccionado
        final clienteActualizado = _clientes.firstWhere(
          (c) => c.id == _clienteSeleccionado!.id,
          orElse: () => _clienteSeleccionado!,
        );
        _clienteSeleccionado = clienteActualizado;
        
        return true;
      } else {
        _setError('Error al actualizar el cliente');
        return false;
      }
    } catch (e) {
      _setError('Error actualizando cliente: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar cliente
  Future<bool> eliminarCliente(ClienteModel cliente) async {
    _setLoading(true);
    
    try {
      final success = await _clienteService.eliminarCliente(cliente.id);
      
      if (success) {
        _setSuccess('Cliente eliminado exitosamente');
        await cargarClientes(); // Recargar lista
        
        // Si era el cliente seleccionado, limpiar selección
        if (_clienteSeleccionado?.id == cliente.id) {
          _clienteSeleccionado = null;
          _ventasCliente.clear();
          _estadisticasCliente.clear();
        }
        
        return true;
      } else {
        _setError('No se puede eliminar un cliente con ventas asociadas');
        return false;
      }
    } catch (e) {
      _setError('Error eliminando cliente: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cargar datos del cliente en el formulario para edición
  void cargarClienteEnFormulario(ClienteModel cliente) {
    nombreController.text = cliente.nombre;
    apellidoPaternoController.text = cliente.apellidoPaterno;
    apellidoMaternoController.text = cliente.apellidoMaterno;
    distritoController.text = cliente.distrito;
    referenciaController.text = cliente.referencia;
    telefonoController.text = cliente.telefono ?? '';
  }

  // Validar formulario
  String? _validarFormulario() {
    if (nombreController.text.trim().isEmpty) {
      return 'El nombre es obligatorio';
    }
    
    if (apellidoPaternoController.text.trim().isEmpty) {
      return 'El apellido paterno es obligatorio';
    }
    
    if (distritoController.text.trim().isEmpty) {
      return 'El distrito es obligatorio';
    }
    
    if (referenciaController.text.trim().isEmpty) {
      return 'La referencia es obligatoria';
    }

    // Validar teléfono si se proporciona
    final telefono = telefonoController.text.trim();
    if (telefono.isNotEmpty && telefono.length < 9) {
      return 'El teléfono debe tener al menos 9 dígitos';
    }

    return null;
  }

  // Limpiar formulario
  void _limpiarFormulario() {
    nombreController.clear();
    apellidoPaternoController.clear();
    apellidoMaternoController.clear();
    distritoController.clear();
    referenciaController.clear();
    telefonoController.clear();
  }

  // Limpiar selección de cliente
  void limpiarSeleccion() {
    _clienteSeleccionado = null;
    _ventasCliente.clear();
    _estadisticasCliente.clear();
    _limpiarFormulario();
    notifyListeners();
  }

  // Obtener estadísticas generales de clientes
  Map<String, dynamic> get estadisticasGenerales {
    if (_clientes.isEmpty) {
      return {
        'total': 0,
        'nuevosEsteMes': 0,
        'clientesActivos': 0,
      };
    }

    final hoy = DateTime.now();
    final inicioMes = DateTime(hoy.year, hoy.month, 1);
    
    final nuevosEsteMes = _clientes
        .where((c) => c.fechaCreacion.isAfter(inicioMes))
        .length;

    // Clientes activos (con al menos una compra en los últimos 30 días)
    final hace30Dias = hoy.subtract(const Duration(days: 30));
    // Esta lógica se podría mejorar con datos de ventas, por ahora es estimativa
    final clientesActivos = (_clientes.length * 0.7).round(); // Estimación

    return {
      'total': _clientes.length,
      'nuevosEsteMes': nuevosEsteMes,
      'clientesActivos': clientesActivos,
    };
  }

  // Obtener clientes por distrito
  Map<String, int> get clientesPorDistrito {
    final distritos = <String, int>{};
    for (final cliente in _clientes) {
      distritos[cliente.distrito] = (distritos[cliente.distrito] ?? 0) + 1;
    }
    return distritos;
  }

  // Refrescar datos
  Future<void> refrescar() async {
    await cargarClientes();
    if (_clienteSeleccionado != null) {
      await seleccionarCliente(_clienteSeleccionado!);
    }
  }

  // Limpiar datos huérfanos (solo para administradores)
  Future<Map<String, dynamic>> limpiarDatosHuerfanos() async {
    _setLoading(true);
    try {
      final resultado = await _clienteService.limpiarDatosHuerfanos();
      
      if (resultado['error'] != null) {
        _setError(resultado['error']);
      } else {
        _setSuccess(resultado['mensaje']);
        await cargarClientes(); // Recargar datos después de la limpieza
      }
      
      return resultado;
    } catch (e) {
      _setError('Error durante la limpieza: $e');
      return {'error': 'Error durante la limpieza: $e'};
    } finally {
      _setLoading(false);
    }
  }

  // Verificar integridad de datos
  Future<Map<String, dynamic>> verificarIntegridadDatos() async {
    _setLoading(true);
    try {
      final resultado = await _clienteService.verificarIntegridadDatos();
      
      if (resultado['error'] != null) {
        _setError(resultado['error']);
      } else {
        final ventasHuerfanas = resultado['ventasHuerfanas'] as int;
        if (ventasHuerfanas > 0) {
          _setError('Se encontraron $ventasHuerfanas ventas huérfanas. Se recomienda ejecutar limpieza de datos.');
        } else {
          _setSuccess('Integridad de datos verificada: ${resultado['integridad']}');
        }
      }
      
      return resultado;
    } catch (e) {
      _setError('Error verificando integridad: $e');
      return {'error': 'Error verificando integridad: $e'};
    } finally {
      _setLoading(false);
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
    nombreController.dispose();
    apellidoPaternoController.dispose();
    apellidoMaternoController.dispose();
    distritoController.dispose();
    referenciaController.dispose();
    telefonoController.dispose();
    busquedaController.dispose();
    super.dispose();
  }
}
