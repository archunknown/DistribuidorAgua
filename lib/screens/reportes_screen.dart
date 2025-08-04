import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../models/user_model.dart';
import '../models/reporte_model.dart';
import '../viewmodels/reportes_viewmodel.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';

class ReportesScreen extends StatefulWidget {
  final UserModel usuario;

  const ReportesScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> with SingleTickerProviderStateMixin {
  late ReportesViewModel _viewModel;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _viewModel = ReportesViewModel();
    _tabController = TabController(length: 4, vsync: this);
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
        body: Consumer<ReportesViewModel>(
          builder: (context, viewModel, child) {
            return LoadingOverlay(
              isLoading: viewModel.isLoading,
              child: Column(
                children: [
                  _buildFiltrosSection(viewModel),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildResumenTab(viewModel),
                        _buildGraficosTab(viewModel),
                        _buildDetalleTab(viewModel),
                        _buildAnalisisTab(viewModel),
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
      title: const Text('Reportes y Análisis'),
      backgroundColor: AppColors.darkNavy,
      foregroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Consumer<ReportesViewModel>(
          builder: (context, viewModel, child) {
            return PopupMenuButton<String>(
              icon: const Icon(Icons.file_download),
              onSelected: (opcion) => _manejarOpcionExport(viewModel, opcion),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Exportar PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'excel',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Exportar Excel'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'compartir',
                  child: Row(
                    children: [
                      Icon(Icons.share, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Compartir PDF'),
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

  Widget _buildFiltrosSection(ReportesViewModel viewModel) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.darkNavy.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: AppColors.darkNavy.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Selector de tipo de reporte
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.mediumBlue,
                size: AppDimensions.iconSm,
              ),
              SizedBox(width: AppDimensions.marginSm),
              Text(
                'Período:',
                style: TextStyle(
                  fontSize: AppDimensions.textMd,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBrown,
                ),
              ),
              SizedBox(width: AppDimensions.marginMd),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: TipoReporte.values.map((tipo) {
                      final isSelected = viewModel.filtroActual.tipoReporte == tipo;
                      return Padding(
                        padding: EdgeInsets.only(right: AppDimensions.marginSm),
                        child: FilterChip(
                          label: Text(tipo.displayName),
                          selected: isSelected,
                          onSelected: (_) => viewModel.cambiarTipoReporte(tipo),
                          selectedColor: AppColors.mediumBlue.withOpacity(0.2),
                          checkmarkColor: AppColors.mediumBlue,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          
          // Filtros adicionales para período personalizado
          if (viewModel.filtroActual.tipoReporte == TipoReporte.personalizado) ...[
            SizedBox(height: AppDimensions.marginMd),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: viewModel.fechaInicioController,
                    labelText: 'Fecha Inicio',
                    prefixIcon: Icons.date_range,
                    readOnly: true,
                    onTap: () => _seleccionarFecha(context, true, viewModel),
                    validator: viewModel.validarFecha,
                  ),
                ),
                SizedBox(width: AppDimensions.marginMd),
                Expanded(
                  child: CustomTextField(
                    controller: viewModel.fechaFinController,
                    labelText: 'Fecha Fin',
                    prefixIcon: Icons.date_range,
                    readOnly: true,
                    onTap: () => _seleccionarFecha(context, false, viewModel),
                    validator: viewModel.validarFecha,
                  ),
                ),
              ],
            ),
          ],
          
          // Botón de limpiar filtros
          if (viewModel.filtroActual.tipoReporte != TipoReporte.diario) ...[
            SizedBox(height: AppDimensions.marginSm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: viewModel.limpiarFiltros,
                icon: const Icon(Icons.clear),
                label: const Text('Limpiar Filtros'),
              ),
            ),
          ],
        ],
      ),
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
        isScrollable: true,
        tabs: const [
          Tab(
            icon: Icon(Icons.dashboard),
            text: 'Resumen',
          ),
          Tab(
            icon: Icon(Icons.bar_chart),
            text: 'Gráficos',
          ),
          Tab(
            icon: Icon(Icons.list),
            text: 'Detalle',
          ),
          Tab(
            icon: Icon(Icons.insights),
            text: 'Análisis',
          ),
        ],
      ),
    );
  }

  Widget _buildResumenTab(ReportesViewModel viewModel) {
    final stats = viewModel.estadisticasReporte;
    final reporte = viewModel.reporteActual;

    if (reporte == null) {
      return _buildEmptyState('No hay datos para mostrar');
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodoHeader(reporte),
          SizedBox(height: AppDimensions.marginLg),
          _buildEstadisticasGenerales(stats),
          SizedBox(height: AppDimensions.marginLg),
          _buildVentasPorTipo(stats),
          SizedBox(height: AppDimensions.marginLg),
          _buildClientesTop(reporte.clientesTop),
          if (viewModel.errorMessage != null)
            _buildErrorMessage(viewModel.errorMessage!),
          if (viewModel.successMessage != null)
            _buildSuccessMessage(viewModel.successMessage!),
        ],
      ),
    );
  }

  Widget _buildGraficosTab(ReportesViewModel viewModel) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGraficoVentasPeriodo(viewModel),
          SizedBox(height: AppDimensions.marginLg),
          _buildGraficoTiposVenta(viewModel),
          SizedBox(height: AppDimensions.marginLg),
          _buildGraficoIngresos(viewModel),
        ],
      ),
    );
  }

  Widget _buildDetalleTab(ReportesViewModel viewModel) {
    final reporte = viewModel.reporteActual;
    
    if (reporte == null || reporte.ventasDetalle.isEmpty) {
      return _buildEmptyState('No hay ventas en este período');
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(AppDimensions.paddingMd),
          color: AppColors.lightBlue.withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: AppColors.lightBlue,
                size: AppDimensions.iconMd,
              ),
              SizedBox(width: AppDimensions.marginMd),
              Text(
                'Detalle de Ventas (${reporte.ventasDetalle.length})',
                style: TextStyle(
                  fontSize: AppDimensions.textLg,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(AppDimensions.paddingMd),
            itemCount: reporte.ventasDetalle.length,
            itemBuilder: (context, index) {
              final venta = reporte.ventasDetalle[index];
              return _buildVentaDetalleItem(venta);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalisisTab(ReportesViewModel viewModel) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppDimensions.paddingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalisisRendimiento(viewModel),
          SizedBox(height: AppDimensions.marginLg),
          _buildSugerenciasMejora(viewModel),
          SizedBox(height: AppDimensions.marginLg),
          _buildComparacionPeriodos(viewModel),
        ],
      ),
    );
  }

  Widget _buildPeriodoHeader(ReporteVentas reporte) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingMd),
      decoration: BoxDecoration(
        color: AppColors.mediumBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.mediumBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month,
            color: AppColors.mediumBlue,
            size: AppDimensions.iconLg,
          ),
          SizedBox(width: AppDimensions.marginMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Período del Reporte',
                  style: TextStyle(
                    fontSize: AppDimensions.textSm,
                    color: AppColors.darkBrown.withOpacity(0.7),
                  ),
                ),
                Text(
                  reporte.periodoTexto,
                  style: TextStyle(
                    fontSize: AppDimensions.textLg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mediumBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasGenerales(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas Generales',
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
                'Total Ventas',
                '${stats['totalVentas']}',
                Icons.shopping_cart,
                AppColors.lightBlue,
              ),
            ),
            SizedBox(width: AppDimensions.marginMd),
            Expanded(
              child: _buildStatCard(
                'Ingresos',
                'S/ ${stats['totalIngresos'].toStringAsFixed(2)}',
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
              child: _buildStatCard(
                'Ganancias',
                'S/ ${stats['totalGanancias'].toStringAsFixed(2)}',
                Icons.trending_up,
                AppColors.success,
              ),
            ),
            SizedBox(width: AppDimensions.marginMd),
            Expanded(
              child: _buildStatCard(
                'Margen',
                '${stats['margenGanancia'].toStringAsFixed(1)}%',
                Icons.percent,
                _getColorByPercentage(stats['margenGanancia']),
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
              Icon(icono, color: color, size: AppDimensions.iconSm),
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
              fontSize: AppDimensions.textLg,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentasPorTipo(Map<String, dynamic> stats) {
    final ventasPorTipo = stats['ventasPorTipo'] as Map<String, int>;
    
    if (ventasPorTipo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ventas por Tipo',
          style: TextStyle(
            fontSize: AppDimensions.textXl,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        ...ventasPorTipo.entries.map((entry) {
          final tipo = entry.key;
          final cantidad = entry.value;
          final total = stats['totalVentas'] as int;
          final porcentaje = total > 0 ? (cantidad / total) * 100 : 0.0;
          
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
                Container(
                  padding: EdgeInsets.all(AppDimensions.paddingSm),
                  decoration: BoxDecoration(
                    color: _getTipoColor(tipo).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Icon(
                    _getTipoIcon(tipo),
                    color: _getTipoColor(tipo),
                    size: AppDimensions.iconSm,
                  ),
                ),
                SizedBox(width: AppDimensions.marginMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTipoDisplayName(tipo),
                        style: TextStyle(
                          fontSize: AppDimensions.textMd,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      Text(
                        '$cantidad ventas (${porcentaje.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: AppDimensions.textSm,
                          color: AppColors.darkBrown.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'S/ ${(stats['ingresosPorTipo'][tipo] ?? 0.0).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: AppDimensions.textMd,
                    fontWeight: FontWeight.bold,
                    color: _getTipoColor(tipo),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildClientesTop(List<ClienteReporte> clientesTop) {
    if (clientesTop.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mejores Clientes',
          style: TextStyle(
            fontSize: AppDimensions.textXl,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        ...clientesTop.take(5).map((cliente) => Container(
          margin: EdgeInsets.only(bottom: AppDimensions.marginSm),
          padding: EdgeInsets.all(AppDimensions.paddingMd),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.darkNavy.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.cyan.withOpacity(0.2),
                child: Text(
                  cliente.nombre.isNotEmpty ? cliente.nombre[0].toUpperCase() : 'C',
                  style: TextStyle(
                    color: AppColors.cyan,
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
                      cliente.nombreCompleto,
                      style: TextStyle(
                        fontSize: AppDimensions.textMd,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBrown,
                      ),
                    ),
                    Text(
                      '${cliente.totalVentas} compras',
                      style: TextStyle(
                        fontSize: AppDimensions.textSm,
                        color: AppColors.darkBrown.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'S/ ${cliente.totalCompras.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: AppDimensions.textMd,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mediumBlue,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildGraficoVentasPeriodo(ReportesViewModel viewModel) {
    final datos = viewModel.datosGraficoVentas;
    
    if (datos.isEmpty) {
      return _buildEmptyChart('No hay datos para el gráfico de ventas');
    }

    return _buildChartContainer(
      'Ventas por Período',
      Icons.bar_chart,
      AppColors.lightBlue,
      Container(
        height: 200.h,
        padding: EdgeInsets.all(AppDimensions.paddingMd),
        child: _buildSimpleBarChart(datos),
      ),
    );
  }

  Widget _buildGraficoTiposVenta(ReportesViewModel viewModel) {
    final datos = viewModel.datosGraficoTipos;
    
    if (datos.isEmpty) {
      return _buildEmptyChart('No hay datos para el gráfico de tipos');
    }

    return _buildChartContainer(
      'Distribución por Tipo de Venta',
      Icons.pie_chart,
      AppColors.mediumBlue,
      Container(
        height: 200.h,
        padding: EdgeInsets.all(AppDimensions.paddingMd),
        child: _buildSimplePieChart(datos),
      ),
    );
  }

  Widget _buildGraficoIngresos(ReportesViewModel viewModel) {
    final datos = viewModel.datosGraficoIngresos;
    
    if (datos.isEmpty) {
      return _buildEmptyChart('No hay datos para el gráfico de ingresos');
    }

    return _buildChartContainer(
      'Ingresos por Tipo de Venta',
      Icons.monetization_on,
      AppColors.success,
      Container(
        height: 200.h,
        padding: EdgeInsets.all(AppDimensions.paddingMd),
        child: _buildSimpleBarChart(datos, useIngresos: true),
      ),
    );
  }

  Widget _buildChartContainer(String titulo, IconData icono, Color color, Widget chart) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(AppDimensions.paddingMd),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusMd),
              ),
            ),
            child: Row(
              children: [
                Icon(icono, color: color, size: AppDimensions.iconMd),
                SizedBox(width: AppDimensions.marginMd),
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: AppDimensions.textLg,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBrown,
                  ),
                ),
              ],
            ),
          ),
          chart,
        ],
      ),
    );
  }

  Widget _buildSimpleBarChart(List<Map<String, dynamic>> datos, {bool useIngresos = false}) {
    if (datos.isEmpty) return const SizedBox.shrink();

    // Manejo seguro de valores null
    final maxValue = datos.map((d) {
      if (useIngresos) {
        return (d['ingresos'] ?? 0.0) as double;
      } else {
        return ((d['ventas'] ?? 0) as int).toDouble();
      }
    }).reduce((a, b) => a > b ? a : b);
    
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: datos.map((dato) {
              // Manejo seguro de valores null
              final value = useIngresos 
                  ? (dato['ingresos'] ?? 0.0) as double 
                  : ((dato['ventas'] ?? 0) as int).toDouble();
              final height = maxValue > 0 ? (value / maxValue) * 150.h : 0.0;
              final periodo = (dato['periodo'] ?? 'N/A').toString();
              
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppDimensions.radiusSm),
                          ),
                        ),
                      ),
                      SizedBox(height: AppDimensions.marginXs),
                      Text(
                        periodo,
                        style: TextStyle(
                          fontSize: AppDimensions.textXs,
                          color: AppColors.darkBrown.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSimplePieChart(List<Map<String, dynamic>> datos) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Center(
            child: Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkNavy.withOpacity(0.1), width: 2),
              ),
              child: const Center(
                child: Text('Gráfico\nCircular', textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: datos.map((dato) => Padding(
              padding: EdgeInsets.only(bottom: AppDimensions.marginSm),
              child: Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: _getTipoColor(dato['tipo']),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: AppDimensions.marginSm),
                  Expanded(
                    child: Text(
                      '${dato['tipo']}: ${dato['porcentaje'].toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: AppDimensions.textSm,
                        color: AppColors.darkBrown,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildVentaDetalleItem(VentaReporte venta) {
    return Card(
      margin: EdgeInsets.only(bottom: AppDimensions.marginMd),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppDimensions.paddingSm),
                  decoration: BoxDecoration(
                    color: _getTipoColor(venta.tipo).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Icon(
                    _getTipoIcon(venta.tipo),
                    color: _getTipoColor(venta.tipo),
                    size: AppDimensions.iconSm,
                  ),
                ),
                SizedBox(width: AppDimensions.marginMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venta.tipoDisplayName,
                        style: TextStyle(
                          fontSize: AppDimensions.textMd,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(venta.fecha),
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
            SizedBox(height: AppDimensions.marginSm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cliente: ${venta.clienteNombre}',
                    style: TextStyle(
                      fontSize: AppDimensions.textSm,
                      color: AppColors.darkBrown.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Cantidad: ${venta.cantidad}',
                  style: TextStyle(
                    fontSize: AppDimensions.textSm,
                    color: AppColors.darkBrown.withOpacity(0.6),
                  ),
                ),
                SizedBox(width: AppDimensions.marginLg),
                Text(
                  'Ganancia: S/ ${venta.ganancia.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: AppDimensions.textSm,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares
  Widget _buildEmptyState(String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80.r,
            color: AppColors.darkBrown.withOpacity(0.3),
          ),
          SizedBox(height: AppDimensions.marginLg),
          Text(
            mensaje,
            style: TextStyle(
              fontSize: AppDimensions.textLg,
              color: AppColors.darkBrown.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String mensaje) {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.darkNavy.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 60.r,
              color: AppColors.darkBrown.withOpacity(0.3),
            ),
            SizedBox(height: AppDimensions.marginMd),
            Text(
              mensaje,
              style: TextStyle(
                fontSize: AppDimensions.textMd,
                color: AppColors.darkBrown.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
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

  Widget _buildAnalisisRendimiento(ReportesViewModel viewModel) {
    final stats = viewModel.estadisticasReporte;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis de Rendimiento',
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
              _buildAnalisisItem(
                'Promedio por Venta',
                'S/ ${stats['promedioVenta'].toStringAsFixed(2)}',
                Icons.trending_up,
                AppColors.mediumBlue,
              ),
              Divider(color: AppColors.darkNavy.withOpacity(0.1)),
              _buildAnalisisItem(
                'Margen de Ganancia',
                '${stats['margenGanancia'].toStringAsFixed(1)}%',
                Icons.percent,
                _getColorByPercentage(stats['margenGanancia']),
              ),
              Divider(color: AppColors.darkNavy.withOpacity(0.1)),
              _buildAnalisisItem(
                'Eficiencia de Ventas',
                _getEficienciaTexto(stats),
                Icons.speed,
                _getEficienciaColor(stats),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalisisItem(String titulo, String valor, IconData icono, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.marginSm),
      child: Row(
        children: [
          Icon(icono, color: color, size: AppDimensions.iconMd),
          SizedBox(width: AppDimensions.marginMd),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: AppDimensions.textMd,
                color: AppColors.darkBrown,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: AppDimensions.textMd,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSugerenciasMejora(ReportesViewModel viewModel) {
    final sugerencias = viewModel.sugerenciasMejora;
    
    if (sugerencias.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sugerencias de Mejora',
          style: TextStyle(
            fontSize: AppDimensions.textXl,
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
          ),
        ),
        SizedBox(height: AppDimensions.marginMd),
        ...sugerencias.map((sugerencia) => Container(
          margin: EdgeInsets.only(bottom: AppDimensions.marginSm),
          padding: EdgeInsets.all(AppDimensions.paddingMd),
          decoration: BoxDecoration(
            color: AppColors.cyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.cyan,
                size: AppDimensions.iconMd,
              ),
              SizedBox(width: AppDimensions.marginMd),
              Expanded(
                child: Text(
                  sugerencia,
                  style: TextStyle(
                    fontSize: AppDimensions.textMd,
                    color: AppColors.darkBrown,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildComparacionPeriodos(ReportesViewModel viewModel) {
    return FutureBuilder<Map<String, dynamic>>(
      future: viewModel.obtenerComparacionPeriodos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final comparacion = snapshot.data!;
        final variaciones = comparacion['variaciones'] as Map<String, dynamic>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparación con Período Anterior',
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
                  _buildVariacionItem('Ventas', variaciones['ventas']),
                  Divider(color: AppColors.darkNavy.withOpacity(0.1)),
                  _buildVariacionItem('Ingresos', variaciones['ingresos']),
                  Divider(color: AppColors.darkNavy.withOpacity(0.1)),
                  _buildVariacionItem('Ganancias', variaciones['ganancias']),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVariacionItem(String titulo, double variacion) {
    final isPositiva = variacion >= 0;
    final color = isPositiva ? AppColors.success : AppColors.error;
    final icono = isPositiva ? Icons.trending_up : Icons.trending_down;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.marginSm),
      child: Row(
        children: [
          Icon(icono, color: color, size: AppDimensions.iconMd),
          SizedBox(width: AppDimensions.marginMd),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: AppDimensions.textMd,
                color: AppColors.darkBrown,
              ),
            ),
          ),
          Text(
            '${isPositiva ? '+' : ''}${variacion.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: AppDimensions.textMd,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Métodos de utilidad
  Color _getColorByPercentage(double percentage) {
    if (percentage >= 40) {
      return AppColors.success;
    } else if (percentage >= 20) {
      return AppColors.cyan;
    } else if (percentage >= 10) {
      return Colors.orange;
    } else {
      return AppColors.error;
    }
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'nueva':
      case 'Venta Nueva':
        return AppColors.lightBlue;
      case 'recarga':
      case 'Recarga':
        return AppColors.mediumBlue;
      case 'prestamo':
      case 'Préstamo':
        return AppColors.cyan;
      default:
        return AppColors.darkNavy;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'nueva':
        return Icons.add_shopping_cart;
      case 'recarga':
        return Icons.refresh;
      case 'prestamo':
        return Icons.handshake;
      default:
        return Icons.shopping_cart;
    }
  }

  String _getTipoDisplayName(String tipo) {
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

  String _getEficienciaTexto(Map<String, dynamic> stats) {
    final margen = stats['margenGanancia'] as double;
    if (margen >= 40) return 'Excelente';
    if (margen >= 30) return 'Buena';
    if (margen >= 20) return 'Regular';
    return 'Baja';
  }

  Color _getEficienciaColor(Map<String, dynamic> stats) {
    final margen = stats['margenGanancia'] as double;
    if (margen >= 40) return AppColors.success;
    if (margen >= 30) return AppColors.cyan;
    if (margen >= 20) return Colors.orange;
    return AppColors.error;
  }

  void _manejarOpcionExport(ReportesViewModel viewModel, String opcion) async {
    try {
      if (opcion == 'compartir') {
        await viewModel.compartirReporte();
      } else {
        final nombreArchivo = await viewModel.exportarReporte(opcion);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reporte exportado: $nombreArchivo'),
              backgroundColor: AppColors.success,
              action: SnackBarAction(
                label: 'Ver ubicación',
                textColor: AppColors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Archivo guardado en Downloads'),
                      backgroundColor: AppColors.mediumBlue,
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _seleccionarFecha(BuildContext context, bool esInicio, ReportesViewModel viewModel) async {
    final fechaInicial = DateTime.now().subtract(const Duration(days: 30));
    final fechaFinal = DateTime.now();

    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: esInicio ? fechaInicial : fechaFinal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );

    if (fechaSeleccionada != null) {
      if (esInicio) {
        viewModel.fechaInicioController.text = DateFormat('dd/MM/yyyy').format(fechaSeleccionada);
        
        // Si ya hay fecha fin, generar reporte
        if (viewModel.fechaFinController.text.isNotEmpty) {
          final fechaFin = DateFormat('dd/MM/yyyy').parse(viewModel.fechaFinController.text);
          await viewModel.establecerPeriodoPersonalizado(fechaSeleccionada, fechaFin);
        }
      } else {
        viewModel.fechaFinController.text = DateFormat('dd/MM/yyyy').format(fechaSeleccionada);
        
        // Si ya hay fecha inicio, generar reporte
        if (viewModel.fechaInicioController.text.isNotEmpty) {
          final fechaInicio = DateFormat('dd/MM/yyyy').parse(viewModel.fechaInicioController.text);
          await viewModel.establecerPeriodoPersonalizado(fechaInicio, fechaSeleccionada);
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
