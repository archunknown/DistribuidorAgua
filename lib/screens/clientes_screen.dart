import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../models/user_model.dart';
import '../models/cliente_model.dart';
import '../models/venta_model.dart';
import '../viewmodels/clientes_viewmodel.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';

class ClientesScreen extends StatefulWidget {
  final UserModel usuario;

  const ClientesScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> with SingleTickerProviderStateMixin {
  late ClientesViewModel _viewModel;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = ClientesViewModel();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.inicializar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: _buildAppBar(),
        body: Consumer<ClientesViewModel>(
          builder: (context, viewModel, child) {
            return LoadingOverlay(
              isLoading: viewModel.isLoading,
              child: Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildListaClientes(viewModel),
                        _buildFormularioCliente(viewModel),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Gestión de Clientes'),
      backgroundColor: AppColors.darkNavy,
      foregroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Consumer<ClientesViewModel>(
          builder: (context, viewModel, child) {
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _manejarAccionMenu(value, viewModel),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'refrescar',
                  child: Row(
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Refrescar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'verificar',
                  child: Row(
                    children: [
                      Icon(Icons.verified_user),
                      SizedBox(width: 8),
                      Text('Verificar Integridad'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'limpiar',
                  child: Row(
                    children: [
                      Icon(Icons.cleaning_services),
                      SizedBox(width: 8),
                      Text('Limpiar Datos Huérfanos'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.darkNavy,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.cyan,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.white.withOpacity(0.7),
        tabs: const [
          Tab(
            icon: Icon(Icons.people),
            text: 'Lista de Clientes',
          ),
          Tab(
            icon: Icon(Icons.person_add),
            text: 'Nuevo Cliente',
          ),
        ],
      ),
    );
  }

  Widget _buildListaClientes(ClientesViewModel viewModel) {
    return Column(
      children: [
        _buildEstadisticasGenerales(viewModel),
        _buildBarraBusqueda(viewModel),
        Expanded(
          child: viewModel.clientes.isEmpty
              ? _buildEstadoVacio()
              : _buildListaClientesContent(viewModel),
        ),
      ],
    );
  }

  Widget _buildEstadisticasGenerales(ClientesViewModel viewModel) {
    final stats = viewModel.estadisticasGenerales;
    
    return Container(
      margin: EdgeInsets.all(AppDimensions.marginMd),
      padding: EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard('Total', '${stats['total']}', Icons.people),
          ),
          SizedBox(width: AppDimensions.marginMd),
          Expanded(
            child: _buildStatCard('Nuevos', '${stats['nuevosEsteMes']}', Icons.person_add),
          ),
          SizedBox(width: AppDimensions.marginMd),
          Expanded(
            child: _buildStatCard('Activos', '${stats['clientesActivos']}', Icons.trending_up),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String titulo, String valor, IconData icono) {
    return Column(
      children: [
        Icon(icono, color: AppColors.lightBlue, size: AppDimensions.iconMd),
        SizedBox(height: AppDimensions.marginSm),
        Text(
          valor,
          style: TextStyle(
            fontSize: AppDimensions.textLg,
            fontWeight: FontWeight.bold,
            color: AppColors.lightBlue,
          ),
        ),
        Text(
          titulo,
          style: TextStyle(
            fontSize: AppDimensions.textSm,
            color: AppColors.darkBrown.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildBarraBusqueda(ClientesViewModel viewModel) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.marginMd),
      child: CustomTextField(
        controller: viewModel.busquedaController,
        labelText: 'Buscar clientes...',
        prefixIcon: Icons.search,
        onChanged: viewModel.buscarClientes,
        suffixIcon: viewModel.filtroActual.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  viewModel.busquedaController.clear();
                  viewModel.buscarClientes('');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80.r,
            color: AppColors.darkBrown.withOpacity(0.3),
          ),
          SizedBox(height: AppDimensions.marginLg),
          Text(
            'No hay clientes registrados',
            style: TextStyle(
              fontSize: AppDimensions.textLg,
              color: AppColors.darkBrown.withOpacity(0.6),
            ),
          ),
          SizedBox(height: AppDimensions.marginMd),
          CustomButton(
            text: 'Agregar Primer Cliente',
            onPressed: () => _tabController.animateTo(1),
            icon: Icons.person_add,
          ),
        ],
      ),
    );
  }

  Widget _buildListaClientesContent(ClientesViewModel viewModel) {
    return ListView.builder(
      padding: EdgeInsets.all(AppDimensions.paddingMd),
      itemCount: viewModel.clientes.length,
      itemBuilder: (context, index) {
        final cliente = viewModel.clientes[index];
        return _buildClienteCard(cliente, viewModel);
      },
    );
  }

  Widget _buildClienteCard(ClienteModel cliente, ClientesViewModel viewModel) {
    return Card(
      margin: EdgeInsets.only(bottom: AppDimensions.marginMd),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: InkWell(
        onTap: () => _mostrarDetallesCliente(cliente, viewModel),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingMd),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25.r,
                backgroundColor: AppColors.lightBlue,
                child: Text(
                  cliente.iniciales,
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: AppDimensions.textMd,
                  ),
                ),
              ),
              SizedBox(width: AppDimensions.marginMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nombreCompleto,
                      style: TextStyle(
                        fontSize: AppDimensions.textMd,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    SizedBox(height: AppDimensions.marginXs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: AppDimensions.iconSm,
                          color: AppColors.mediumBlue,
                        ),
                        SizedBox(width: AppDimensions.marginXs),
                        Expanded(
                          child: Text(
                            cliente.direccionCompleta,
                            style: TextStyle(
                              fontSize: AppDimensions.textSm,
                              color: AppColors.darkBrown.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (cliente.telefono != null) ...[
                      SizedBox(height: AppDimensions.marginXs),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: AppDimensions.iconSm,
                            color: AppColors.mediumBlue,
                          ),
                          SizedBox(width: AppDimensions.marginXs),
                          Text(
                            cliente.telefono!,
                            style: TextStyle(
                              fontSize: AppDimensions.textSm,
                              color: AppColors.darkBrown.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: AppDimensions.iconSm,
                color: AppColors.darkBrown.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormularioCliente(ClientesViewModel viewModel) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.paddingLg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (viewModel.clienteSeleccionado != null) ...[
              _buildTituloFormulario('Editar Cliente'),
              SizedBox(height: AppDimensions.marginMd),
            ] else ...[
              _buildTituloFormulario('Nuevo Cliente'),
              SizedBox(height: AppDimensions.marginMd),
            ],
            
            _buildCamposFormulario(viewModel),
            
            SizedBox(height: AppDimensions.marginXl),
            
            _buildBotonesFormulario(viewModel),
            
            if (viewModel.errorMessage != null)
              _buildErrorMessage(viewModel.errorMessage!),
            
            if (viewModel.successMessage != null)
              _buildSuccessMessage(viewModel.successMessage!),
          ],
        ),
      ),
    );
  }

  Widget _buildTituloFormulario(String titulo) {
    return Text(
      titulo,
      style: TextStyle(
        fontSize: AppDimensions.textXl,
        fontWeight: FontWeight.bold,
        color: AppColors.darkBrown,
      ),
    );
  }

  Widget _buildCamposFormulario(ClientesViewModel viewModel) {
    return Column(
      children: [
        CustomTextField(
          controller: viewModel.nombreController,
          labelText: 'Nombre *',
          prefixIcon: Icons.person,
          validator: (value) => value?.isEmpty == true ? 'Campo obligatorio' : null,
          onChanged: (_) => viewModel.clearMessages(),
        ),
        
        SizedBox(height: AppDimensions.marginMd),
        
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: viewModel.apellidoPaternoController,
                labelText: 'Apellido Paterno *',
                prefixIcon: Icons.person_outline,
                validator: (value) => value?.isEmpty == true ? 'Campo obligatorio' : null,
                onChanged: (_) => viewModel.clearMessages(),
              ),
            ),
            SizedBox(width: AppDimensions.marginMd),
            Expanded(
              child: CustomTextField(
                controller: viewModel.apellidoMaternoController,
                labelText: 'Apellido Materno',
                prefixIcon: Icons.person_outline,
                onChanged: (_) => viewModel.clearMessages(),
              ),
            ),
          ],
        ),
        
        SizedBox(height: AppDimensions.marginMd),
        
        CustomTextField(
          controller: viewModel.distritoController,
          labelText: 'Distrito *',
          prefixIcon: Icons.location_city,
          validator: (value) => value?.isEmpty == true ? 'Campo obligatorio' : null,
          onChanged: (_) => viewModel.clearMessages(),
        ),
        
        SizedBox(height: AppDimensions.marginMd),
        
        CustomTextField(
          controller: viewModel.referenciaController,
          labelText: 'Referencia de Vivienda *',
          prefixIcon: Icons.home,
          validator: (value) => value?.isEmpty == true ? 'Campo obligatorio' : null,
          onChanged: (_) => viewModel.clearMessages(),
          maxLines: 2,
        ),
        
        SizedBox(height: AppDimensions.marginMd),
        
        CustomTextField(
          controller: viewModel.telefonoController,
          labelText: 'Teléfono (opcional)',
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
          maxLength: 9,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (value.length != 9) {
                return 'El teléfono debe tener exactamente 9 dígitos';
              }
              if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                return 'Solo se permiten números';
              }
            }
            return null;
          },
          onChanged: (_) => viewModel.clearMessages(),
          hintText: 'Ej: 987654321',
        ),
      ],
    );
  }

  Widget _buildBotonesFormulario(ClientesViewModel viewModel) {
    return Column(
      children: [
        if (viewModel.clienteSeleccionado != null) ...[
          // Botones para edición
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Actualizar',
                  onPressed: viewModel.isLoading ? null : () => _actualizarCliente(viewModel),
                  isLoading: viewModel.isLoading,
                ),
              ),
              SizedBox(width: AppDimensions.marginMd),
              Expanded(
                child: CustomButton(
                  text: 'Cancelar',
                  onPressed: () => _cancelarEdicion(viewModel),
                  backgroundColor: AppColors.darkBrown.withOpacity(0.1),
                  textColor: AppColors.darkBrown,
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.marginMd),
          CustomButton(
            text: 'Eliminar Cliente',
            onPressed: () => _confirmarEliminacion(viewModel.clienteSeleccionado!, viewModel),
            backgroundColor: AppColors.error,
            width: double.infinity,
            icon: Icons.delete,
          ),
        ] else ...[
          // Botón para crear
          CustomButton(
            text: 'Crear Cliente',
            onPressed: viewModel.isLoading ? null : () => _crearCliente(viewModel),
            isLoading: viewModel.isLoading,
            width: double.infinity,
            icon: Icons.person_add,
          ),
        ],
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: EdgeInsets.only(top: AppDimensions.marginMd),
      padding: EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: AppDimensions.iconMd,
          ),
          SizedBox(width: AppDimensions.marginMd),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.error,
                fontSize: AppDimensions.textMd,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(String message) {
    return Container(
      margin: EdgeInsets.only(top: AppDimensions.marginMd),
      padding: EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: AppDimensions.iconMd,
          ),
          SizedBox(width: AppDimensions.marginMd),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.success,
                fontSize: AppDimensions.textMd,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _tabController.animateTo(1),
      backgroundColor: AppColors.lightBlue,
      child: const Icon(Icons.person_add, color: AppColors.white),
    );
  }

  void _mostrarDetallesCliente(ClienteModel cliente, ClientesViewModel viewModel) async {
    await viewModel.seleccionarCliente(cliente);
    
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildDetallesClienteModal(cliente, viewModel),
      );
    }
  }

  Widget _buildDetallesClienteModal(ClienteModel cliente, ClientesViewModel viewModel) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Handle del modal
              Container(
                margin: EdgeInsets.symmetric(vertical: AppDimensions.marginMd),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.darkBrown.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(AppDimensions.paddingLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderDetalles(cliente),
                      SizedBox(height: AppDimensions.marginLg),
                      _buildInformacionPersonal(cliente),
                      SizedBox(height: AppDimensions.marginLg),
                      _buildEstadisticasCliente(viewModel),
                      SizedBox(height: AppDimensions.marginLg),
                      _buildHistorialVentas(viewModel),
                      SizedBox(height: AppDimensions.marginLg),
                      _buildAccionesCliente(cliente, viewModel),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderDetalles(ClienteModel cliente) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30.r,
          backgroundColor: AppColors.lightBlue,
          child: Text(
            cliente.iniciales,
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: AppDimensions.textLg,
            ),
          ),
        ),
        SizedBox(width: AppDimensions.marginMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cliente.nombreCompleto,
                style: TextStyle(
                  fontSize: AppDimensions.textXl,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
              Text(
                'Cliente desde ${DateFormat('dd/MM/yyyy').format(cliente.fechaCreacion)}',
                style: TextStyle(
                  fontSize: AppDimensions.textSm,
                  color: AppColors.darkBrown.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInformacionPersonal(ClienteModel cliente) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Personal',
          style: TextStyle(
            fontSize: AppDimensions.textLg,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        _buildInfoRow(Icons.location_on, 'Dirección', cliente.direccionCompleta),
        if (cliente.telefono != null)
          _buildTelefonoRow(cliente.telefono!),
      ],
    );
  }

  Widget _buildInfoRow(IconData icono, String titulo, String valor) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.marginMd),
      child: Row(
        children: [
          Icon(icono, color: AppColors.mediumBlue, size: AppDimensions.iconMd),
          SizedBox(width: AppDimensions.marginMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: AppDimensions.textSm,
                    color: AppColors.darkBrown.withOpacity(0.6),
                  ),
                ),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: AppDimensions.textMd,
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelefonoRow(String telefono) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppDimensions.marginMd),
      child: Row(
        children: [
          Icon(Icons.phone, color: AppColors.mediumBlue, size: AppDimensions.iconMd),
          SizedBox(width: AppDimensions.marginMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teléfono',
                  style: TextStyle(
                    fontSize: AppDimensions.textSm,
                    color: AppColors.darkBrown.withOpacity(0.6),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      telefono,
                      style: TextStyle(
                        fontSize: AppDimensions.textMd,
                        color: AppColors.darkBrown,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: AppDimensions.marginMd),
                    InkWell(
                      onTap: () => _abrirWhatsApp(telefono),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingSm,
                          vertical: AppDimensions.paddingXs,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366), // Color oficial de WhatsApp
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.chat,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: AppDimensions.marginXs),
                            Text(
                              'WhatsApp',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: AppDimensions.textSm,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirWhatsApp(String telefono) async {
    // Agregar código de país 51 para Perú
    final numeroCompleto = '51$telefono';
    
    // Lista de URLs para intentar (en orden de preferencia)
    final urls = [
      'whatsapp://send?phone=$numeroCompleto', // URL scheme de WhatsApp
      'https://wa.me/$numeroCompleto',         // URL web de WhatsApp
      'https://api.whatsapp.com/send?phone=$numeroCompleto', // URL alternativa
    ];
    
    bool success = false;
    
    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri, 
            mode: url.startsWith('whatsapp://') 
                ? LaunchMode.externalApplication 
                : LaunchMode.externalApplication
          );
          success = true;
          break;
        }
      } catch (e) {
        // Continuar con la siguiente URL
        continue;
      }
    }
    
    if (!success && mounted) {
      // Si ninguna URL funcionó, mostrar diálogo con opciones
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('WhatsApp no disponible'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No se pudo abrir WhatsApp automáticamente.'),
              const SizedBox(height: 12),
              Text('Número: +$numeroCompleto'),
              const SizedBox(height: 8),
              const Text('Opciones:'),
              const Text('• Instala WhatsApp desde Play Store'),
              const Text('• Copia el número manualmente'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            TextButton(
              onPressed: () async {
                // Copiar número al portapapeles
                await _copiarNumero(numeroCompleto);
                Navigator.pop(context);
              },
              child: const Text('Copiar Número'),
            ),
          ],
        ),
      );
    }
  }
  
  Future<void> _copiarNumero(String numero) async {
    try {
      // Importar Clipboard si no está importado
      await Future.delayed(Duration.zero); // Placeholder para clipboard
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Número copiado: +$numero'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al copiar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildEstadisticasCliente(ClientesViewModel viewModel) {
    final stats = viewModel.estadisticasCliente;
    if (stats.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas',
          style: TextStyle(
            fontSize: AppDimensions.textLg,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        Container(
          padding: EdgeInsets.all(AppDimensions.paddingMd),
          decoration: BoxDecoration(
            color: AppColors.lightBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Compras', '${stats['totalVentas']}'),
                  ),
                  Expanded(
                    child: _buildStatItem('Total Gastado', 'S/ ${(stats['montoTotal'] as double).toStringAsFixed(2)}'),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.marginMd),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Tipo Preferido', stats['tipoPreferido']),
                  ),
                  Expanded(
                    child: _buildStatItem('Frecuencia', stats['frecuenciaCompras']),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String titulo, String valor) {
    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: AppDimensions.textLg,
            fontWeight: FontWeight.bold,
            color: AppColors.lightBlue,
          ),
        ),
        Text(
          titulo,
          style: TextStyle(
            fontSize: AppDimensions.textSm,
            color: AppColors.darkBrown.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHistorialVentas(ClientesViewModel viewModel) {
    if (viewModel.ventasCliente.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historial de Ventas',
            style: TextStyle(
              fontSize: AppDimensions.textLg,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBrown,
            ),
          ),
          SizedBox(height: AppDimensions.marginMd),
          Text(
            'No hay ventas registradas para este cliente',
            style: TextStyle(
              fontSize: AppDimensions.textMd,
              color: AppColors.darkBrown.withOpacity(0.6),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Historial de Ventas',
          style: TextStyle(
            fontSize: AppDimensions.textLg,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        ...viewModel.ventasCliente.take(5).map((venta) => _buildVentaItem(venta)),
        if (viewModel.ventasCliente.length > 5)
          TextButton(
            onPressed: () {
              // TODO: Mostrar todas las ventas
            },
            child: Text('Ver todas las ventas (${viewModel.ventasCliente.length})'),
          ),
      ],
    );
  }

  Widget _buildVentaItem(VentaModel venta) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.marginSm),
      padding: EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.darkNavy.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart,
            color: AppColors.lightBlue,
            size: AppDimensions.iconMd,
          ),
          SizedBox(width: AppDimensions.marginMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venta.tipo.displayName,
                  style: TextStyle(
                    fontSize: AppDimensions.textMd,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBrown,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(venta.fechaHora),
                  style: TextStyle(
                    fontSize: AppDimensions.textSm,
                    color: AppColors.darkBrown.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/ ${venta.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppDimensions.textMd,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mediumBlue,
                ),
              ),
              Text(
                '${venta.cantidad} bidón${venta.cantidad > 1 ? 'es' : ''}',
                style: TextStyle(
                  fontSize: AppDimensions.textSm,
                  color: AppColors.darkBrown.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccionesCliente(ClienteModel cliente, ClientesViewModel viewModel) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Editar',
                onPressed: () => _editarCliente(cliente, viewModel),
                icon: Icons.edit,
              ),
            ),
            SizedBox(width: AppDimensions.marginMd),
            Expanded(
              child: CustomButton(
                text: 'Eliminar',
                onPressed: () => _confirmarEliminacion(cliente, viewModel),
                backgroundColor: AppColors.error,
                icon: Icons.delete,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _crearCliente(ClientesViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      final success = await viewModel.crearCliente(widget.usuario);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cliente creado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        _tabController.animateTo(0); // Volver a la lista
      }
    }
  }

  void _actualizarCliente(ClientesViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      final success = await viewModel.actualizarCliente();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cliente actualizado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        _tabController.animateTo(0); // Volver a la lista
      }
    }
  }

  void _cancelarEdicion(ClientesViewModel viewModel) {
    viewModel.limpiarSeleccion();
    _tabController.animateTo(0); // Volver a la lista
  }

  void _editarCliente(ClienteModel cliente, ClientesViewModel viewModel) {
    Navigator.pop(context); // Cerrar modal
    viewModel.cargarClienteEnFormulario(cliente);
    _tabController.animateTo(1); // Ir al formulario
  }

  void _confirmarEliminacion(ClienteModel cliente, ClientesViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${cliente.nombreCompleto}?\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Cerrar modal si está abierto
              
              final success = await viewModel.eliminarCliente(cliente);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Cliente eliminado exitosamente'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _manejarAccionMenu(String accion, ClientesViewModel viewModel) async {
    switch (accion) {
      case 'refrescar':
        await viewModel.refrescar();
        break;
      case 'verificar':
        _mostrarDialogoVerificarIntegridad(viewModel);
        break;
      case 'limpiar':
        _mostrarDialogoLimpiarDatos(viewModel);
        break;
    }
  }

  void _mostrarDialogoVerificarIntegridad(ClientesViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: Colors.blue),
            SizedBox(width: 8),
            Text('Verificar Integridad'),
          ],
        ),
        content: const Text(
          'Esta acción verificará la integridad de los datos, '
          'buscando ventas huérfanas y otros problemas de consistencia.\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final resultado = await viewModel.verificarIntegridadDatos();
              
              if (mounted) {
                _mostrarResultadoIntegridad(resultado);
              }
            },
            child: const Text('Verificar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoLimpiarDatos(ClientesViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cleaning_services, color: Colors.orange),
            SizedBox(width: 8),
            Text('Limpiar Datos Huérfanos'),
          ],
        ),
        content: const Text(
          'Esta acción eliminará las ventas huérfanas (ventas de clientes que ya no existen) '
          'y restaurará el stock correspondiente al inventario.\n\n'
          '⚠️ Esta acción no se puede deshacer.\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final resultado = await viewModel.limpiarDatosHuerfanos();
              
              if (mounted) {
                _mostrarResultadoLimpieza(resultado);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }

  void _mostrarResultadoIntegridad(Map<String, dynamic> resultado) {
    final ventasHuerfanas = resultado['ventasHuerfanas'] ?? 0;
    final totalVentas = resultado['totalVentas'] ?? 0;
    final totalClientes = resultado['totalClientes'] ?? 0;
    final integridad = resultado['integridad'] ?? 'Desconocida';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              ventasHuerfanas > 0 ? Icons.warning : Icons.check_circle,
              color: ventasHuerfanas > 0 ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 8),
            const Text('Resultado de Verificación'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estado: $integridad'),
            const SizedBox(height: 8),
            Text('Total de clientes: $totalClientes'),
            Text('Total de ventas: $totalVentas'),
            Text('Ventas huérfanas: $ventasHuerfanas'),
            if (ventasHuerfanas > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Text(
                  '⚠️ Se recomienda ejecutar la limpieza de datos huérfanos.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (ventasHuerfanas > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _mostrarDialogoLimpiarDatos(_viewModel);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Limpiar Ahora'),
            ),
        ],
      ),
    );
  }

  void _mostrarResultadoLimpieza(Map<String, dynamic> resultado) {
    final ventasLimpiadas = resultado['ventasLimpiadas'] ?? 0;
    final stockRestaurado = resultado['stockRestaurado'] ?? 0;
    final mensaje = resultado['mensaje'] ?? 'Operación completada';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Limpieza Completada'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensaje),
            const SizedBox(height: 12),
            if (ventasLimpiadas > 0) ...[
              Text('✅ Ventas huérfanas eliminadas: $ventasLimpiadas'),
              Text('📦 Stock restaurado: $stockRestaurado bidones'),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }
}
