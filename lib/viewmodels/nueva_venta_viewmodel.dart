import 'package:flutter/material.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/cliente_model.dart';
import '../models/venta_model.dart';
import '../models/inventario_model.dart';
import '../services/cliente_service.dart';
import '../services/venta_service.dart';
import '../services/inventario_service.dart';

class NuevaVentaViewModel extends ChangeNotifier {
  final ClienteService _clienteService = ClienteService();
  final VentaService _ventaService = VentaService();
  final InventarioService _inventarioService = InventarioService();

  // Estado del formulario
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Datos del formulario
  ClienteModel? _clienteSeleccionado;
  TipoVenta _tipoVenta = TipoVenta.recarga;
  int _cantidad = 1;
  double _precioUnitario = 10.0;
  double _costoBidon = 0.0;
  
  // Lista de clientes para autocompletado
  List<ClienteModel> _clientesSugeridos = [];
  List<ClienteModel> _todosLosClientes = []; // Cache de todos los clientes
  InventarioModel? _inventarioActual;
  bool _isBuscandoClientes = false;

  // Debouncing para búsqueda
  Timer? _debounceTimer;
  String _ultimaBusqueda = '';

  // Controladores de texto
  final TextEditingController clienteController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController(text: '1');
  final TextEditingController precioController = TextEditingController(text: '10.0');
  final TextEditingController costoController = TextEditingController(text: '0.0');

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  ClienteModel? get clienteSeleccionado => _clienteSeleccionado;
  TipoVenta get tipoVenta => _tipoVenta;
  int get cantidad => _cantidad;
  double get precioUnitario => _precioUnitario;
  double get costoBidon => _costoBidon;
  List<ClienteModel> get clientesSugeridos => _clientesSugeridos;
  InventarioModel? get inventarioActual => _inventarioActual;
  bool get isBuscandoClientes => _isBuscandoClientes;

  // Cálculos automáticos
  double get total => _precioUnitario * _cantidad;
  double get ganancia => total - (_costoBidon * _cantidad);
  bool get stockSuficiente => _inventarioActual != null && 
      _inventarioActual!.stockDisponible >= _cantidad;

  // Inicializar datos
  Future<void> inicializar() async {
    _setLoading(true);
    try {
      await Future.wait([
        _cargarInventario(),
        _cargarCacheClientes(), // Cargar cache de clientes para mejor rendimiento
      ]);
      _actualizarPreciosPorDefecto();
    } catch (e) {
      _setError('Error al inicializar: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Cargar inventario actual
  Future<void> _cargarInventario() async {
    try {
      _inventarioActual = await _inventarioService.obtenerInventario();
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando inventario: $e');
    }
  }

  // Buscar clientes para autocompletado con debouncing
  void buscarClientes(String query) {
    // Cancelar búsqueda anterior si existe
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      _clientesSugeridos.clear();
      _isBuscandoClientes = false;
      _ultimaBusqueda = '';
      notifyListeners();
      return;
    }

    // Si es la misma búsqueda, no hacer nada
    if (query == _ultimaBusqueda) return;

    _ultimaBusqueda = query;
    _isBuscandoClientes = true;
    notifyListeners();

    // Configurar debounce de 300ms
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _ejecutarBusquedaClientes(query);
    });
  }

  // Ejecutar búsqueda real de clientes
  Future<void> _ejecutarBusquedaClientes(String query) async {
    try {
      // Primero buscar en cache local si existe
      if (_todosLosClientes.isNotEmpty) {
        _clientesSugeridos = _filtrarClientesLocalmente(query);
      } else {
        // Si no hay cache, buscar en servidor
        _clientesSugeridos = await _clienteService.buscarClientesPorNombre(query);
        
        // Actualizar cache si es la primera búsqueda
        if (_todosLosClientes.isEmpty && query.length <= 2) {
          _todosLosClientes = await _clienteService.obtenerTodosLosClientes();
        }
      }
      
      _isBuscandoClientes = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error buscando clientes: $e');
      _isBuscandoClientes = false;
      notifyListeners();
    }
  }

  // Filtrar clientes localmente para mejor rendimiento
  List<ClienteModel> _filtrarClientesLocalmente(String query) {
    final queryLower = query.toLowerCase();
    return _todosLosClientes.where((cliente) {
      return cliente.nombreCompleto.toLowerCase().contains(queryLower) ||
             cliente.distrito.toLowerCase().contains(queryLower) ||
             cliente.referencia.toLowerCase().contains(queryLower) ||
             (cliente.telefono?.toLowerCase().contains(queryLower) ?? false);
    }).take(10).toList(); // Limitar a 10 resultados para mejor rendimiento
  }

  // Cargar todos los clientes para cache (llamar al inicializar)
  Future<void> _cargarCacheClientes() async {
    try {
      _todosLosClientes = await _clienteService.obtenerTodosLosClientes();
    } catch (e) {
      debugPrint('Error cargando cache de clientes: $e');
    }
  }

  // Seleccionar cliente
  void seleccionarCliente(ClienteModel cliente) {
    // Si el cliente tiene ID vacío, significa que se está limpiando la selección
    if (cliente.id.isEmpty) {
      _clienteSeleccionado = null;
      clienteController.clear();
    } else {
      _clienteSeleccionado = cliente;
      clienteController.text = cliente.nombreCompleto;
    }
    _clientesSugeridos.clear();
    _clearMessages();
    notifyListeners();
  }

  // Cambiar tipo de venta
  void cambiarTipoVenta(TipoVenta nuevoTipo) {
    _tipoVenta = nuevoTipo;
    _actualizarPreciosPorDefecto();
    _clearMessages();
    notifyListeners();
  }

  // Actualizar precios por defecto según tipo de venta
  void _actualizarPreciosPorDefecto() {
    switch (_tipoVenta) {
      case TipoVenta.nueva:
        _precioUnitario = 25.0;
        precioController.text = '25.0';
        break;
      case TipoVenta.recarga:
      case TipoVenta.prestamo:
        _precioUnitario = 10.0;
        precioController.text = '10.0';
        break;
    }
    notifyListeners();
  }

  // Actualizar cantidad
  void actualizarCantidad(String value) {
    final nuevaCantidad = int.tryParse(value) ?? 1;
    if (nuevaCantidad > 0 && nuevaCantidad <= 50) { // Límite razonable
      _cantidad = nuevaCantidad;
      cantidadController.text = nuevaCantidad.toString();
      _clearMessages();
      notifyListeners();
    }
  }

  // Actualizar precio unitario
  void actualizarPrecioUnitario(String value) {
    final nuevoPrecio = double.tryParse(value) ?? 0.0;
    if (nuevoPrecio >= 0) {
      _precioUnitario = nuevoPrecio;
      _clearMessages();
      notifyListeners();
    }
  }

  // Actualizar costo del bidón
  void actualizarCostoBidon(String value) {
    final nuevoCosto = double.tryParse(value) ?? 0.0;
    if (nuevoCosto >= 0) {
      _costoBidon = nuevoCosto;
      _clearMessages();
      notifyListeners();
    }
  }

  // Validar formulario
  String? _validarFormulario() {
    if (_clienteSeleccionado == null) {
      return 'Debe seleccionar un cliente';
    }
    
    if (_cantidad <= 0) {
      return 'La cantidad debe ser mayor a 0';
    }
    
    if (_precioUnitario <= 0) {
      return 'El precio debe ser mayor a 0';
    }

    // Validar stock para ventas nuevas y préstamos
    if ((_tipoVenta == TipoVenta.nueva || _tipoVenta == TipoVenta.prestamo) && 
        !stockSuficiente) {
      return 'Stock insuficiente. Disponible: ${_inventarioActual?.stockDisponible ?? 0}';
    }

    return null;
  }

  // Registrar venta
  Future<bool> registrarVenta(UserModel usuarioActual) async {
    _clearMessages();
    
    final validationError = _validarFormulario();
    if (validationError != null) {
      _setError(validationError);
      return false;
    }

    _setLoading(true);
    
    try {
      final ventaId = await _ventaService.crearVenta(
        clienteId: _clienteSeleccionado!.id,
        tipo: _tipoVenta,
        cantidad: _cantidad,
        precioUnitario: _precioUnitario,
        costoBidon: _costoBidon,
        usuarioActual: usuarioActual,
      );

      if (ventaId != null) {
        _setSuccess('¡Venta registrada exitosamente!');
        await _cargarInventario(); // Actualizar inventario
        _limpiarFormulario();
        return true;
      } else {
        _setError('Error al registrar la venta');
        return false;
      }
    } catch (e) {
      _setError('Error al registrar venta: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Limpiar formulario después de venta exitosa
  void _limpiarFormulario() {
    _clienteSeleccionado = null;
    clienteController.clear();
    _cantidad = 1;
    cantidadController.text = '1';
    _actualizarPreciosPorDefecto();
    costoController.text = '0.0';
    _costoBidon = 0.0;
    _clientesSugeridos.clear();
    notifyListeners();
  }

  // Crear cliente rápido
  Future<bool> crearClienteRapido({
    required String nombreCompleto,
    required String distrito,
    required String referencia,
    String? telefono,
    required UserModel usuarioActual,
  }) async {
    _setLoading(true);
    
    try {
      // Separar nombre completo en partes
      final partes = nombreCompleto.trim().split(' ');
      if (partes.length < 2) {
        _setError('Ingrese nombre y apellido completos');
        return false;
      }

      final nombre = partes[0];
      final apellidoPaterno = partes.length > 1 ? partes[1] : '';
      final apellidoMaterno = partes.length > 2 ? partes.sublist(2).join(' ') : '';

      final clienteId = await _clienteService.crearCliente(
        nombre: nombre,
        apellidoPaterno: apellidoPaterno,
        apellidoMaterno: apellidoMaterno,
        distrito: distrito,
        referencia: referencia,
        telefono: telefono,
        usuarioActual: usuarioActual,
      );

      if (clienteId != null) {
        // Obtener el cliente recién creado
        final nuevoCliente = await _clienteService.obtenerClientePorId(clienteId);
        if (nuevoCliente != null) {
          seleccionarCliente(nuevoCliente);
          _setSuccess('Cliente creado exitosamente');
          return true;
        }
      }
      
      _setError('Error al crear el cliente');
      return false;
    } catch (e) {
      _setError('Error creando cliente: $e');
      return false;
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
    _debounceTimer?.cancel(); // Limpiar timer de debouncing
    clienteController.dispose();
    cantidadController.dispose();
    precioController.dispose();
    costoController.dispose();
    super.dispose();
  }
}
