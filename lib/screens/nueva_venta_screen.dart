import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../models/user_model.dart';
import '../models/venta_model.dart';
import '../models/cliente_model.dart';
import '../viewmodels/nueva_venta_viewmodel.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';

class NuevaVentaScreen extends StatefulWidget {
  final UserModel usuario;

  const NuevaVentaScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  late NuevaVentaViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = NuevaVentaViewModel();
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
        body: Consumer<NuevaVentaViewModel>(
          builder: (context, viewModel, child) {
            return LoadingOverlay(
              isLoading: viewModel.isLoading,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(AppDimensions.paddingLg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStockInfo(viewModel),
                            SizedBox(height: AppDimensions.marginLg),
                            _buildClienteSection(viewModel),
                            SizedBox(height: AppDimensions.marginLg),
                            _buildTipoVentaSection(viewModel),
                            SizedBox(height: AppDimensions.marginLg),
                            _buildDetallesVenta(viewModel),
                            SizedBox(height: AppDimensions.marginLg),
                            _buildResumenVenta(viewModel),
                            SizedBox(height: AppDimensions.marginXl),
                            if (viewModel.errorMessage != null)
                              _buildErrorMessage(viewModel.errorMessage!),
                            if (viewModel.successMessage != null)
                              _buildSuccessMessage(viewModel.successMessage!),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomSection(viewModel),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Nueva Venta'),
      backgroundColor: AppColors.darkNavy,
      foregroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildStockInfo(NuevaVentaViewModel viewModel) {
    final inventario = viewModel.inventarioActual;
    if (inventario == null) return const SizedBox.shrink();

    Color stockColor = AppColors.success;
    if (inventario.stockBajo) stockColor = AppColors.error;
    else if (inventario.stockCritico) stockColor = Colors.orange;

    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: stockColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: stockColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory,
            color: stockColor,
            size: AppDimensions.iconMd,
          ),
          SizedBox(width: AppDimensions.marginMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock Disponible',
                  style: TextStyle(
                    fontSize: AppDimensions.textSm,
                    color: AppColors.darkBrown.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${inventario.stockDisponible} bidones',
                  style: TextStyle(
                    fontSize: AppDimensions.textLg,
                    fontWeight: FontWeight.bold,
                    color: stockColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            inventario.estadoStock,
            style: TextStyle(
              fontSize: AppDimensions.textSm,
              fontWeight: FontWeight.w600,
              color: stockColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteSection(NuevaVentaViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cliente',
          style: TextStyle(
            fontSize: AppDimensions.textLg,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        
        // Campo de búsqueda de cliente
        CustomTextField(
          controller: viewModel.clienteController,
          labelText: 'Buscar cliente',
          prefixIcon: Icons.person_search,
          onChanged: (value) => viewModel.buscarClientes(value),
          suffixIcon: viewModel.clienteSeleccionado != null
              ? Icon(Icons.check_circle, color: AppColors.success)
              : IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _mostrarDialogoNuevoCliente(viewModel),
                ),
        ),
        
        // Lista de sugerencias
        if (viewModel.clientesSugeridos.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: AppDimensions.marginSm),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackWithOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: viewModel.clientesSugeridos.length,
              itemBuilder: (context, index) {
                final cliente = viewModel.clientesSugeridos[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.lightBlue,
                    child: Text(
                      cliente.iniciales,
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(cliente.nombreCompleto),
                  subtitle: Text(cliente.direccionCompleta),
                  onTap: () => viewModel.seleccionarCliente(cliente),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTipoVentaSection(NuevaVentaViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Venta',
          style: TextStyle(
            fontSize: AppDimensions.textLg,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        
        Row(
          children: [
            Expanded(
              child: _buildTipoVentaCard(
                viewModel,
                TipoVenta.nueva,
                'Garrafón Nuevo',
                'S/ 25',
                Icons.add_shopping_cart,
                AppColors.lightBlue,
              ),
            ),
            SizedBox(width: AppDimensions.marginMd),
            Expanded(
              child: _buildTipoVentaCard(
                viewModel,
                TipoVenta.recarga,
                'Recarga',
                'S/ 10',
                Icons.refresh,
                AppColors.mediumBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.marginMd),
        _buildTipoVentaCard(
          viewModel,
          TipoVenta.prestamo,
          'Préstamo + Agua',
          'S/ 10',
          Icons.handshake,
          AppColors.cyan,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildTipoVentaCard(
    NuevaVentaViewModel viewModel,
    TipoVenta tipo,
    String titulo,
    String precio,
    IconData icono,
    Color color, {
    bool fullWidth = false,
  }) {
    final isSelected = viewModel.tipoVenta == tipo;
    
    return GestureDetector(
      onTap: () => viewModel.cambiarTipoVenta(tipo),
      child: Container(
        padding: EdgeInsets.all(AppDimensions.paddingMd),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: isSelected ? AppColors.white : color,
              size: AppDimensions.iconLg,
            ),
            SizedBox(height: AppDimensions.marginSm),
            Text(
              titulo,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.darkBrown,
                fontSize: AppDimensions.textMd,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              precio,
              style: TextStyle(
                color: isSelected ? AppColors.white : color,
                fontSize: AppDimensions.textLg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetallesVenta(NuevaVentaViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles de la Venta',
          style: TextStyle(
            fontSize: AppDimensions.textLg,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: viewModel.cantidadController,
                labelText: 'Cantidad',
                prefixIcon: Icons.format_list_numbered,
                keyboardType: TextInputType.number,
                onChanged: viewModel.actualizarCantidad,
              ),
            ),
            SizedBox(width: AppDimensions.marginMd),
            Expanded(
              child: CustomTextField(
                controller: viewModel.precioController,
                labelText: 'Precio Unit.',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                onChanged: viewModel.actualizarPrecioUnitario,
              ),
            ),
          ],
        ),
        
        SizedBox(height: AppDimensions.marginMd),
        
        CustomTextField(
          controller: viewModel.costoController,
          labelText: 'Costo del Bidón (opcional)',
          prefixIcon: Icons.money_off,
          keyboardType: TextInputType.number,
          onChanged: viewModel.actualizarCostoBidon,
        ),
      ],
    );
  }

  Widget _buildResumenVenta(NuevaVentaViewModel viewModel) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        color: AppColors.darkNavy.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.darkNavy.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen',
            style: TextStyle(
              fontSize: AppDimensions.textLg,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBrown,
            ),
          ),
          SizedBox(height: AppDimensions.marginMd),
          
          _buildResumenRow('Cantidad:', '${viewModel.cantidad} bidón${viewModel.cantidad > 1 ? 'es' : ''}'),
          _buildResumenRow('Precio unitario:', 'S/ ${viewModel.precioUnitario.toStringAsFixed(2)}'),
          _buildResumenRow('Costo bidón:', 'S/ ${viewModel.costoBidon.toStringAsFixed(2)}'),
          
          const Divider(),
          
          _buildResumenRow(
            'TOTAL:',
            'S/ ${viewModel.total.toStringAsFixed(2)}',
            isTotal: true,
          ),
          
          if (viewModel.ganancia > 0)
            _buildResumenRow(
              'Ganancia:',
              'S/ ${viewModel.ganancia.toStringAsFixed(2)}',
              color: AppColors.success,
            ),
        ],
      ),
    );
  }

  Widget _buildResumenRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? AppDimensions.textLg : AppDimensions.textMd,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color ?? AppColors.darkBrown,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? AppDimensions.textLg : AppDimensions.textMd,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isTotal ? AppColors.mediumBlue : AppColors.darkBrown),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(NuevaVentaViewModel viewModel) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingLg),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.blackWithOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: CustomButton(
          text: 'Registrar Venta',
          onPressed: viewModel.isLoading ? null : () => _registrarVenta(viewModel),
          isLoading: viewModel.isLoading,
          width: double.infinity,
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.marginMd),
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
      margin: EdgeInsets.only(bottom: AppDimensions.marginMd),
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

  void _mostrarDialogoNuevoCliente(NuevaVentaViewModel viewModel) {
    final nombreController = TextEditingController();
    final distritoController = TextEditingController();
    final referenciaController = TextEditingController();
    final telefonoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Cliente'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: nombreController,
                labelText: 'Nombre completo',
                prefixIcon: Icons.person,
              ),
              SizedBox(height: AppDimensions.marginMd),
              CustomTextField(
                controller: distritoController,
                labelText: 'Distrito',
                prefixIcon: Icons.location_city,
              ),
              SizedBox(height: AppDimensions.marginMd),
              CustomTextField(
                controller: referenciaController,
                labelText: 'Referencia',
                prefixIcon: Icons.home,
              ),
              SizedBox(height: AppDimensions.marginMd),
              CustomTextField(
                controller: telefonoController,
                labelText: 'Teléfono (opcional)',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreController.text.isNotEmpty &&
                  distritoController.text.isNotEmpty &&
                  referenciaController.text.isNotEmpty) {
                
                Navigator.pop(context);
                
                await viewModel.crearClienteRapido(
                  nombreCompleto: nombreController.text,
                  distrito: distritoController.text,
                  referencia: referenciaController.text,
                  telefono: telefonoController.text.isEmpty ? null : telefonoController.text,
                  usuarioActual: widget.usuario,
                );
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _registrarVenta(NuevaVentaViewModel viewModel) async {
    final success = await viewModel.registrarVenta(widget.usuario);
    
    if (success && mounted) {
      // Mostrar confirmación y regresar al dashboard
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Venta registrada exitosamente!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Opcional: regresar al dashboard después de un delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context, true); // true indica que se registró una venta
        }
      });
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
