import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_overlay.dart';
import 'nueva_venta_screen.dart';
import 'clientes_screen.dart';
import 'inventario_screen.dart';
import 'reportes_screen.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel usuario;

  const DashboardScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.inicializar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.darkNavy,
        body: Consumer<DashboardViewModel>(
          builder: (context, viewModel, child) {
            return LoadingOverlay(
              isLoading: viewModel.isLoading,
              child: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(AppDimensions.radiusXl),
                            topRight: Radius.circular(AppDimensions.radiusXl),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(AppDimensions.paddingLg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildEstadisticasRapidas(viewModel),
                              SizedBox(height: AppDimensions.marginLg),
                              _buildAccionesRapidas(),
                              SizedBox(height: AppDimensions.marginLg),
                              _buildVentasRecientes(viewModel),
                              SizedBox(height: AppDimensions.marginLg),
                              _buildAlertasInventario(viewModel),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingLg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25.r,
            backgroundColor: AppColors.lightBlue,
            child: Text(
              widget.usuario.iniciales,
              style: TextStyle(
                color: AppColors.white,
                fontSize: AppDimensions.textLg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: AppDimensions.marginMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, ${widget.usuario.nombre}!',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: AppDimensions.textXl,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.usuario.rol.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontSize: AppDimensions.textSm,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _mostrarMenuUsuario,
            icon: Icon(
              Icons.more_vert,
              color: AppColors.white,
              size: AppDimensions.iconMd,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasRapidas(DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen de Hoy',
          style: TextStyle(
            fontSize: AppDimensions.textXl,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        Row(
          children: [
            Expanded(
              child: _buildEstadisticaCard(
                'Ventas',
                '${viewModel.estadisticas['hoy']?['cantidad'] ?? 0}',
                Icons.shopping_cart,
                AppColors.lightBlue,
              ),
            ),
            SizedBox(width: AppDimensions.marginMd),
            Expanded(
              child: _buildEstadisticaCard(
                'Ingresos',
                'S/ ${(viewModel.estadisticas['hoy']?['total'] ?? 0.0).toStringAsFixed(2)}',
                Icons.attach_money,
                AppColors.mediumBlue,
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.marginMd),
        Row(
          children: [
            Expanded(
              child: _buildEstadisticaCard(
                'Ganancias',
                'S/ ${(viewModel.estadisticas['hoy']?['ganancias'] ?? 0.0).toStringAsFixed(2)}',
                Icons.trending_up,
                AppColors.cyan,
              ),
            ),
            SizedBox(width: AppDimensions.marginMd),
            Expanded(
              child: _buildEstadisticaCard(
                'Stock',
                '${viewModel.inventario?.stockDisponible ?? 0}',
                Icons.inventory,
                viewModel.inventario?.stockBajo == true 
                    ? AppColors.error 
                    : AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEstadisticaCard(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: AppDimensions.iconSm),
              SizedBox(width: AppDimensions.marginSm),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: AppDimensions.textSm,
                  color: AppColors.darkBrown.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.marginSm),
          Text(
            valor,
            style: TextStyle(
              fontSize: AppDimensions.textLg,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccionesRapidas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: TextStyle(
            fontSize: AppDimensions.textXl,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        Row(
          children: [
            Expanded(
              child: _buildAccionCard(
                'Nueva Venta',
                Icons.add_shopping_cart,
                AppColors.lightBlue,
                () => _navegarANuevaVenta(),
              ),
            ),
            SizedBox(width: AppDimensions.marginMd),
            Expanded(
              child: _buildAccionCard(
                'Clientes',
                Icons.people,
                AppColors.mediumBlue,
                () => _navegarAClientes(),
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.marginMd),
        Row(
          children: [
            Expanded(
              child: _buildAccionCard(
                'Inventario',
                Icons.inventory_2,
                AppColors.cyan,
                () => _navegarAInventario(),
              ),
            ),
            SizedBox(width: AppDimensions.marginMd),
            Expanded(
              child: _buildAccionCard(
                'Reportes',
                Icons.analytics,
                AppColors.darkNavy,
                () => _navegarAReportes(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccionCard(String titulo, IconData icono, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppDimensions.paddingLg),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icono,
              color: AppColors.white,
              size: AppDimensions.iconLg,
            ),
            SizedBox(height: AppDimensions.marginSm),
            Text(
              titulo,
              style: TextStyle(
                color: AppColors.white,
                fontSize: AppDimensions.textMd,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVentasRecientes(DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ventas Recientes',
              style: TextStyle(
                fontSize: AppDimensions.textXl,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),
            TextButton(
              onPressed: () => _navegarAReportes(),
              child: Text('Ver todas'),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.marginMd),
        if (viewModel.ventasRecientes.isEmpty)
          Container(
            padding: EdgeInsets.all(AppDimensions.paddingLg),
            decoration: BoxDecoration(
              color: AppColors.darkNavy.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Center(
              child: Text(
                'No hay ventas registradas hoy',
                style: TextStyle(
                  color: AppColors.darkBrown.withOpacity(0.6),
                  fontSize: AppDimensions.textMd,
                ),
              ),
            ),
          )
        else
          ...viewModel.ventasRecientes.take(3).map((venta) => 
            Container(
              margin: EdgeInsets.only(bottom: AppDimensions.marginSm),
              padding: EdgeInsets.all(AppDimensions.paddingMd),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.darkNavy.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppDimensions.paddingSm),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      color: AppColors.lightBlue,
                      size: AppDimensions.iconSm,
                    ),
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
                          '${venta.cantidad} bidón${venta.cantidad > 1 ? 'es' : ''}',
                          style: TextStyle(
                            fontSize: AppDimensions.textSm,
                            color: AppColors.darkBrown.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'S/ ${venta.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: AppDimensions.textMd,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mediumBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAlertasInventario(DashboardViewModel viewModel) {
    if (viewModel.alertasInventario.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alertas de Inventario',
          style: TextStyle(
            fontSize: AppDimensions.textXl,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        ...viewModel.alertasInventario.map((alerta) => 
          Container(
            margin: EdgeInsets.only(bottom: AppDimensions.marginSm),
            padding: EdgeInsets.all(AppDimensions.paddingMd),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: AppColors.error,
                  size: AppDimensions.iconSm,
                ),
                SizedBox(width: AppDimensions.marginMd),
                Expanded(
                  child: Text(
                    alerta,
                    style: TextStyle(
                      fontSize: AppDimensions.textMd,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarMenuUsuario() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(AppDimensions.paddingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person, color: AppColors.mediumBlue),
              title: Text('Mi Perfil'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navegar a perfil
              },
            ),
            if (widget.usuario.isAdmin) ...[
              ListTile(
                leading: Icon(Icons.people, color: AppColors.mediumBlue),
                title: Text('Gestionar Usuarios'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navegar a gestión de usuarios
                },
              ),
            ],
            ListTile(
              leading: Icon(Icons.settings, color: AppColors.mediumBlue),
              title: Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navegar a configuración
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.error),
              title: Text('Cerrar Sesión'),
              onTap: () => _cerrarSesion(),
            ),
          ],
        ),
      ),
    );
  }

  void _navegarANuevaVenta() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NuevaVentaScreen(usuario: widget.usuario),
      ),
    );
    
    // Si se registró una venta, refrescar el dashboard
    if (result == true) {
      _viewModel.refrescar();
    }
  }

  void _navegarAClientes() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientesScreen(usuario: widget.usuario),
      ),
    );
    
    // Si se realizaron cambios en clientes, refrescar el dashboard
    if (result == true) {
      _viewModel.refrescar();
    }
  }

  void _navegarAInventario() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InventarioScreen(usuario: widget.usuario),
      ),
    );
    
    // Si se realizaron cambios en inventario, refrescar el dashboard
    if (result == true) {
      _viewModel.refrescar();
    }
  }

  void _navegarAReportes() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportesScreen(usuario: widget.usuario),
      ),
    );
    
    // Si se realizaron cambios en reportes, refrescar el dashboard
    if (result == true) {
      _viewModel.refrescar();
    }
  }

  void _cerrarSesion() async {
    Navigator.pop(context); // Cerrar bottom sheet
    
    await AuthService().logout();
    
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
