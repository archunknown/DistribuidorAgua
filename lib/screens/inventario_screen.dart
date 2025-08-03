import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../models/user_model.dart';
import '../models/inventario_model.dart';
import '../viewmodels/inventario_viewmodel.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';

class InventarioScreen extends StatefulWidget {
  final UserModel usuario;

  const InventarioScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> with SingleTickerProviderStateMixin {
  late InventarioViewModel _viewModel;
  late TabController _tabController;
  
  // Claves de formulario separadas para cada sección
  final _stockTotalFormKey = GlobalKey<FormState>();
  final _agregarStockFormKey = GlobalKey<FormState>();
  final _ajusteStockFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = InventarioViewModel();
    _tabController = TabController(length: 3, vsync: this);
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
        body: Consumer<InventarioViewModel>(
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
                        _buildEstadisticasTab(viewModel),
                        _buildControlStockTab(viewModel),
                        _buildHistorialTab(viewModel),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Control de Inventario'),
      backgroundColor: AppColors.darkNavy,
      foregroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Consumer<InventarioViewModel>(
          builder: (context, viewModel, child) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => viewModel.refrescar(),
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
            icon: Icon(Icons.analytics),
            text: 'Estadísticas',
          ),
          Tab(
            icon: Icon(Icons.inventory_2),
            text: 'Control Stock',
          ),
          Tab(
            icon: Icon(Icons.history),
            text: 'Historial',
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasTab(InventarioViewModel viewModel) {
    final stats = viewModel.estadisticasInventario;
    final alertas = viewModel.alertasInventario;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResumenGeneral(stats),
          SizedBox(height: AppDimensions.marginLg),
          _buildIndicadoresStock(stats),
          SizedBox(height: AppDimensions.marginLg),
          _buildGraficoStock(stats),
          if (alertas.isNotEmpty) ...[
            SizedBox(height: AppDimensions.marginLg),
            _buildAlertasInventario(alertas),
          ],
        ],
      ),
    );
  }

  Widget _buildResumenGeneral(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen General',
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
              child: _buildStatCard(
                'Stock Total',
                '${stats['stockTotal']}',
                Icons.inventory,
                AppColors.mediumBlue,
              ),
            ),
            SizedBox(width: AppDimensions.marginMd),
            Expanded(
              child: _buildStatCard(
                'Disponible',
                '${stats['stockDisponible']}',
                Icons.check_circle,
                AppColors.success,
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.marginMd),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'En Préstamo',
                '${stats['stockPrestado']}',
                Icons.people,
                AppColors.lightBlue,
              ),
            ),
            SizedBox(width: AppDimensions.marginMd),
            Expanded(
              child: _buildStatCard(
                'Disponibilidad',
                '${stats['porcentajeDisponible'].toStringAsFixed(1)}%',
                Icons.pie_chart,
                _getColorByPercentage(stats['porcentajeDisponible']),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: AppDimensions.iconMd),
              SizedBox(width: AppDimensions.marginSm),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: AppDimensions.textSm,
                    color: AppColors.darkBrown.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.marginSm),
          Text(
            valor,
            style: TextStyle(
              fontSize: AppDimensions.textXl,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadoresStock(Map<String, dynamic> stats) {
    final porcentaje = stats['porcentajeDisponible'] as double;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicadores de Stock',
          style: TextStyle(
            fontSize: AppDimensions.textXl,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        Container(
          padding: EdgeInsets.all(AppDimensions.paddingMd),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.darkNavy.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Stock Disponible',
                    style: TextStyle(
                      fontSize: AppDimensions.textMd,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  Text(
                    '${porcentaje.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: AppDimensions.textMd,
                      fontWeight: FontWeight.bold,
                      color: _getColorByPercentage(porcentaje),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimensions.marginSm),
              LinearProgressIndicator(
                value: porcentaje / 100,
                backgroundColor: AppColors.darkBrown.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getColorByPercentage(porcentaje),
                ),
                minHeight: 8.h,
              ),
              SizedBox(height: AppDimensions.marginSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${stats['stockDisponible']} disponibles',
                    style: TextStyle(
                      fontSize: AppDimensions.textSm,
                      color: AppColors.darkBrown.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    '${stats['stockPrestado']} prestados',
                    style: TextStyle(
                      fontSize: AppDimensions.textSm,
                      color: AppColors.darkBrown.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGraficoStock(Map<String, dynamic> stats) {
    final disponible = stats['stockDisponible'] as int;
    final prestado = stats['stockPrestado'] as int;
    final total = stats['stockTotal'] as int;

    if (total == 0) {
      return Container(
        padding: EdgeInsets.all(AppDimensions.paddingLg),
        decoration: BoxDecoration(
          color: AppColors.darkNavy.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Center(
          child: Text(
            'No hay datos de inventario',
            style: TextStyle(
              fontSize: AppDimensions.textMd,
              color: AppColors.darkBrown.withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distribución del Stock',
          style: TextStyle(
            fontSize: AppDimensions.textXl,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        Container(
          padding: EdgeInsets.all(AppDimensions.paddingMd),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.darkNavy.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              // Gráfico de barras simple
              Row(
                children: [
                  if (disponible > 0)
                    Expanded(
                      flex: disponible,
                      child: Container(
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(AppDimensions.radiusSm),
                          ),
                        ),
                      ),
                    ),
                  if (prestado > 0)
                    Expanded(
                      flex: prestado,
                      child: Container(
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(AppDimensions.radiusSm),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppDimensions.marginMd),
              Row(
                children: [
                  _buildLeyenda('Disponible', AppColors.success, disponible),
                  SizedBox(width: AppDimensions.marginLg),
                  _buildLeyenda('Prestado', AppColors.lightBlue, prestado),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeyenda(String titulo, Color color, int cantidad) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: AppDimensions.marginSm),
        Text(
          '$titulo ($cantidad)',
          style: TextStyle(
            fontSize: AppDimensions.textSm,
            color: AppColors.darkBrown,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertasInventario(List<String> alertas) {
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
        ...alertas.map((alerta) => Container(
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
                size: AppDimensions.iconMd,
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
        )),
      ],
    );
  }

  Widget _buildControlStockTab(InventarioViewModel viewModel) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEstadoActual(viewModel),
          SizedBox(height: AppDimensions.marginLg),
          _buildAccionesStock(viewModel),
          if (viewModel.errorMessage != null)
            _buildErrorMessage(viewModel.errorMessage!),
          if (viewModel.successMessage != null)
            _buildSuccessMessage(viewModel.successMessage!),
        ],
      ),
    );
  }

  Widget _buildEstadoActual(InventarioViewModel viewModel) {
    final inventario = viewModel.inventario;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado Actual del Inventario',
          style: TextStyle(
            fontSize: AppDimensions.textXl,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        Container(
          padding: EdgeInsets.all(AppDimensions.paddingMd),
          decoration: BoxDecoration(
            color: AppColors.mediumBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.mediumBlue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    color: AppColors.mediumBlue,
                    size: AppDimensions.iconLg,
                  ),
                  SizedBox(width: AppDimensions.marginMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock Total: ${inventario?.stockTotal ?? 0} bidones',
                          style: TextStyle(
                            fontSize: AppDimensions.textLg,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mediumBlue,
                          ),
                        ),
                        Text(
                          'Disponibles: ${inventario?.stockDisponible ?? 0} bidones',
                          style: TextStyle(
                            fontSize: AppDimensions.textMd,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        if (inventario?.fechaActualizacion != null)
                          Text(
                            'Última actualización: ${DateFormat('dd/MM/yyyy HH:mm').format(inventario!.fechaActualizacion)}',
                            style: TextStyle(
                              fontSize: AppDimensions.textSm,
                              color: AppColors.darkBrown.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccionesStock(InventarioViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones de Stock',
          style: TextStyle(
            fontSize: AppDimensions.textXl,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        
        // Actualizar stock total
        _buildSeccionAccion(
          'Actualizar Stock Total',
          'Cambiar el stock total del inventario',
          Icons.update,
          AppColors.mediumBlue,
          [
            CustomTextField(
              controller: viewModel.stockTotalController,
              labelText: 'Nuevo Stock Total *',
              prefixIcon: Icons.inventory,
              keyboardType: TextInputType.number,
              validator: viewModel.validarStockInicial,
              onChanged: (_) => viewModel.clearMessages(),
            ),
            SizedBox(height: AppDimensions.marginMd),
            CustomTextField(
              controller: viewModel.motivoStockTotalController,
              labelText: 'Motivo *',
              prefixIcon: Icons.description,
              validator: viewModel.validarMotivo,
              onChanged: (_) => viewModel.clearMessages(),
              maxLines: 2,
            ),
            SizedBox(height: AppDimensions.marginMd),
            CustomButton(
              text: 'Actualizar Stock Total',
              onPressed: viewModel.isLoading ? null : () => _actualizarStockTotal(viewModel),
              isLoading: viewModel.isLoading,
              width: double.infinity,
              icon: Icons.update,
            ),
          ],
        ),
        
        SizedBox(height: AppDimensions.marginLg),
        
        // Agregar stock
        _buildSeccionAccion(
          'Agregar Stock',
          'Compra de nuevos bidones',
          Icons.add_circle,
          AppColors.success,
          [
            CustomTextField(
              controller: viewModel.agregarStockController,
              labelText: 'Cantidad a Agregar *',
              prefixIcon: Icons.add,
              keyboardType: TextInputType.number,
              validator: viewModel.validarStockInicial,
              onChanged: (_) => viewModel.clearMessages(),
            ),
            SizedBox(height: AppDimensions.marginMd),
            CustomTextField(
              controller: viewModel.motivoAgregarController,
              labelText: 'Motivo *',
              prefixIcon: Icons.description,
              validator: viewModel.validarMotivo,
              onChanged: (_) => viewModel.clearMessages(),
              maxLines: 2,
            ),
            SizedBox(height: AppDimensions.marginMd),
            CustomButton(
              text: 'Agregar Stock',
              onPressed: viewModel.isLoading ? null : () => _agregarStock(viewModel),
              isLoading: viewModel.isLoading,
              width: double.infinity,
              backgroundColor: AppColors.success,
              icon: Icons.add_circle,
            ),
          ],
        ),
        
        SizedBox(height: AppDimensions.marginLg),
        
        // Ajustar stock disponible
        _buildSeccionAccion(
          'Ajustar Stock Disponible',
          'Correcciones manuales (+/-)',
          Icons.tune,
          AppColors.cyan,
          [
            CustomTextField(
              controller: viewModel.ajusteStockController,
              labelText: 'Ajuste (+/-) *',
              prefixIcon: Icons.tune,
              keyboardType: TextInputType.number,
              validator: viewModel.validarAjuste,
              onChanged: (_) => viewModel.clearMessages(),
              hintText: 'Ej: +5 para agregar, -3 para quitar',
            ),
            SizedBox(height: AppDimensions.marginMd),
            CustomTextField(
              controller: viewModel.motivoAjusteController,
              labelText: 'Motivo *',
              prefixIcon: Icons.description,
              validator: viewModel.validarMotivo,
              onChanged: (_) => viewModel.clearMessages(),
              maxLines: 2,
            ),
            SizedBox(height: AppDimensions.marginMd),
            CustomButton(
              text: 'Ajustar Stock',
              onPressed: viewModel.isLoading ? null : () => _ajustarStockDisponible(viewModel),
              isLoading: viewModel.isLoading,
              width: double.infinity,
              backgroundColor: AppColors.cyan,
              icon: Icons.tune,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeccionAccion(
    String titulo,
    String descripcion,
    IconData icono,
    Color color,
    List<Widget> campos,
  ) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: AppDimensions.iconMd),
              SizedBox(width: AppDimensions.marginMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: AppDimensions.textLg,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: AppDimensions.textSm,
                        color: AppColors.darkBrown.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.marginMd),
          ...campos,
        ],
      ),
    );
  }

  Widget _buildHistorialTab(InventarioViewModel viewModel) {
    final historial = viewModel.historialMovimientos;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(AppDimensions.paddingMd),
          color: AppColors.lightBlue.withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                Icons.history,
                color: AppColors.lightBlue,
                size: AppDimensions.iconMd,
              ),
              SizedBox(width: AppDimensions.marginMd),
              Expanded(
                child: Text(
                  'Historial de Movimientos',
                  style: TextStyle(
                    fontSize: AppDimensions.textLg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBrown,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: historial.isEmpty
              ? _buildHistorialVacio()
              : ListView.builder(
                  padding: EdgeInsets.all(AppDimensions.paddingMd),
                  itemCount: historial.length,
                  itemBuilder: (context, index) {
                    final movimiento = historial[index];
                    return _buildMovimientoItem(movimiento);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistorialVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80.r,
            color: AppColors.darkBrown.withOpacity(0.3),
          ),
          SizedBox(height: AppDimensions.marginLg),
          Text(
            'No hay movimientos registrados',
            style: TextStyle(
              fontSize: AppDimensions.textLg,
              color: AppColors.darkBrown.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovimientoItem(Map<String, dynamic> movimiento) {
    final tipo = movimiento['tipo'] as String;
    final cantidad = movimiento['cantidad'] as int;
    final fecha = movimiento['fecha'] as DateTime;
    final motivo = movimiento['motivo'] as String;
    final stockResultante = movimiento['stockResultante'] as int;

    Color colorTipo = AppColors.mediumBlue;
    IconData iconoTipo = Icons.swap_horiz;

    switch (tipo) {
      case 'Compra':
      case 'Ajuste +':
        colorTipo = AppColors.success;
        iconoTipo = Icons.add_circle;
        break;
      case 'Venta':
      case 'Ajuste -':
        colorTipo = AppColors.error;
        iconoTipo = Icons.remove_circle;
        break;
      case 'Actualización Total':
        colorTipo = AppColors.mediumBlue;
        iconoTipo = Icons.update;
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: AppDimensions.marginMd),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingMd),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppDimensions.paddingSm),
              decoration: BoxDecoration(
                color: colorTipo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(
                iconoTipo,
                color: colorTipo,
                size: AppDimensions.iconMd,
              ),
            ),
            SizedBox(width: AppDimensions.marginMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tipo,
                        style: TextStyle(
                          fontSize: AppDimensions.textMd,
                          fontWeight: FontWeight.w600,
                          color: colorTipo,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${cantidad > 0 ? '+' : ''}$cantidad',
                        style: TextStyle(
                          fontSize: AppDimensions.textMd,
                          fontWeight: FontWeight.bold,
                          color: colorTipo,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppDimensions.marginXs),
                  Text(
                    motivo,
                    style: TextStyle(
                      fontSize: AppDimensions.textSm,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  SizedBox(height: AppDimensions.marginXs),
                  Row(
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(fecha),
                        style: TextStyle(
                          fontSize: AppDimensions.textSm,
                          color: AppColors.darkBrown.withOpacity(0.6),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Stock: $stockResultante',
                        style: TextStyle(
                          fontSize: AppDimensions.textSm,
                          color: AppColors.darkBrown.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Color _getColorByPercentage(double percentage) {
    if (percentage >= 50) {
      return AppColors.success;
    } else if (percentage >= 20) {
      return AppColors.cyan;
    } else if (percentage >= 10) {
      return Colors.orange;
    } else {
      return AppColors.error;
    }
  }

  void _actualizarStockTotal(InventarioViewModel viewModel) async {
    // Validar solo los campos de esta sección
    if (viewModel.validarStockInicial(viewModel.stockTotalController.text) == null &&
        viewModel.validarMotivo(viewModel.motivoStockTotalController.text) == null) {
      final stockTotal = int.tryParse(viewModel.stockTotalController.text);
      final motivo = viewModel.motivoStockTotalController.text.trim();
      
      if (stockTotal != null) {
        final success = await viewModel.actualizarStockTotal(stockTotal, motivo, widget.usuario);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Stock total actualizado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
  }

  void _agregarStock(InventarioViewModel viewModel) async {
    // Validar solo los campos de esta sección
    if (viewModel.validarStockInicial(viewModel.agregarStockController.text) == null &&
        viewModel.validarMotivo(viewModel.motivoAgregarController.text) == null) {
      final cantidad = int.tryParse(viewModel.agregarStockController.text);
      final motivo = viewModel.motivoAgregarController.text.trim();
      
      if (cantidad != null) {
        final success = await viewModel.agregarStock(cantidad, motivo, widget.usuario);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Stock agregado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
  }

  void _ajustarStockDisponible(InventarioViewModel viewModel) async {
    // Validar solo los campos de esta sección
    if (viewModel.validarAjuste(viewModel.ajusteStockController.text) == null &&
        viewModel.validarMotivo(viewModel.motivoAjusteController.text) == null) {
      final ajuste = int.tryParse(viewModel.ajusteStockController.text);
      final motivo = viewModel.motivoAjusteController.text.trim();
      
      if (ajuste != null) {
        final success = await viewModel.ajustarStockDisponible(ajuste, motivo);
        
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Stock ajustado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }
}
