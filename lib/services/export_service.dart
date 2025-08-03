import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../models/reporte_model.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  // Exportar reporte a PDF
  Future<String> exportarPDF(ReporteVentas reporte) async {
    try {
      // Solicitar permisos
      await _solicitarPermisos();

      final pdf = pw.Document();
      
      // Crear el contenido del PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildPDFHeader(reporte),
              pw.SizedBox(height: 20),
              _buildPDFEstadisticas(reporte),
              pw.SizedBox(height: 20),
              _buildPDFVentasPorTipo(reporte),
              pw.SizedBox(height: 20),
              _buildPDFClientesTop(reporte),
              pw.SizedBox(height: 20),
              _buildPDFDetalleVentas(reporte),
            ];
          },
        ),
      );

      // Guardar el archivo
      final fileName = 'reporte_${_formatearFechaArchivo(reporte.fechaInicio)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = await _guardarArchivo(await pdf.save(), fileName);
      
      return filePath;
    } catch (e) {
      debugPrint('Error exportando PDF: $e');
      throw Exception('Error al exportar PDF: $e');
    }
  }

  // Exportar reporte a Excel
  Future<String> exportarExcel(ReporteVentas reporte) async {
    try {
      // Solicitar permisos
      await _solicitarPermisos();

      final excel = Excel.createExcel();
      
      // Crear hoja de resumen
      final resumenSheet = excel['Resumen'];
      _crearHojaResumen(resumenSheet, reporte);
      
      // Crear hoja de detalle de ventas
      final detalleSheet = excel['Detalle de Ventas'];
      _crearHojaDetalle(detalleSheet, reporte);
      
      // Crear hoja de clientes top
      final clientesSheet = excel['Clientes Top'];
      _crearHojaClientes(clientesSheet, reporte);

      // Eliminar hoja por defecto
      excel.delete('Sheet1');

      // Guardar el archivo
      final fileName = 'reporte_${_formatearFechaArchivo(reporte.fechaInicio)}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final bytes = excel.encode()!;
      final filePath = await _guardarArchivo(Uint8List.fromList(bytes), fileName);
      
      return filePath;
    } catch (e) {
      debugPrint('Error exportando Excel: $e');
      throw Exception('Error al exportar Excel: $e');
    }
  }

  // Compartir PDF
  Future<void> compartirPDF(ReporteVentas reporte) async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildPDFHeader(reporte),
              pw.SizedBox(height: 20),
              _buildPDFEstadisticas(reporte),
              pw.SizedBox(height: 20),
              _buildPDFVentasPorTipo(reporte),
              pw.SizedBox(height: 20),
              _buildPDFClientesTop(reporte),
              pw.SizedBox(height: 20),
              _buildPDFDetalleVentas(reporte),
            ];
          },
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'reporte_${_formatearFechaArchivo(reporte.fechaInicio)}.pdf',
      );
    } catch (e) {
      debugPrint('Error compartiendo PDF: $e');
      throw Exception('Error al compartir PDF: $e');
    }
  }

  // Métodos privados para construir el PDF
  pw.Widget _buildPDFHeader(ReporteVentas reporte) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'REPORTE DE VENTAS',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Distribuidora de Agua',
          style: pw.TextStyle(
            fontSize: 16,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Período: ${reporte.periodoTexto}',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey600,
          ),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildPDFEstadisticas(ReporteVentas reporte) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ESTADÍSTICAS GENERALES',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildPDFStatCard('Total Ventas', '${reporte.totalVentas}'),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: _buildPDFStatCard('Total Ingresos', 'S/ ${reporte.totalIngresos.toStringAsFixed(2)}'),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildPDFStatCard('Total Ganancias', 'S/ ${reporte.totalGanancias.toStringAsFixed(2)}'),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: _buildPDFStatCard('Margen Ganancia', '${reporte.margenGanancia.toStringAsFixed(1)}%'),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPDFStatCard(String titulo, String valor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFVentasPorTipo(ReporteVentas reporte) {
    if (reporte.ventasPorTipo.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'VENTAS POR TIPO',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Tipo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Cantidad', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Ingresos', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            ...reporte.ventasPorTipo.entries.map((entry) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(_getTipoDisplayName(entry.key)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${entry.value}'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('S/ ${(reporte.ingresosPorTipo[entry.key] ?? 0.0).toStringAsFixed(2)}'),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPDFClientesTop(ReporteVentas reporte) {
    if (reporte.clientesTop.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'MEJORES CLIENTES',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Cliente', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Ventas', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Total Compras', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            ...reporte.clientesTop.take(10).map((cliente) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(cliente.nombreCompleto),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${cliente.totalVentas}'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('S/ ${cliente.totalCompras.toStringAsFixed(2)}'),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPDFDetalleVentas(ReporteVentas reporte) {
    if (reporte.ventasDetalle.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DETALLE DE VENTAS',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Fecha', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Cliente', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Tipo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Cant.', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
            ...reporte.ventasDetalle.take(50).map((venta) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(DateFormat('dd/MM/yy').format(venta.fecha), style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(venta.clienteNombre, style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(venta.tipoDisplayName, style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('${venta.cantidad}', style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('S/ ${venta.total.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                ),
              ],
            )),
          ],
        ),
        if (reporte.ventasDetalle.length > 50)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Mostrando las primeras 50 ventas de ${reporte.ventasDetalle.length} total.',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
      ],
    );
  }

  // Métodos para crear hojas de Excel
  void _crearHojaResumen(Sheet sheet, ReporteVentas reporte) {
    // Encabezados
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('REPORTE DE VENTAS - RESUMEN');
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('Período: ${reporte.periodoTexto}');
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');

    // Estadísticas generales
    sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('ESTADÍSTICAS GENERALES');
    sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('Total Ventas');
    sheet.cell(CellIndex.indexByString('B6')).value = IntCellValue(reporte.totalVentas);
    sheet.cell(CellIndex.indexByString('A7')).value = TextCellValue('Total Ingresos');
    sheet.cell(CellIndex.indexByString('B7')).value = DoubleCellValue(reporte.totalIngresos);
    sheet.cell(CellIndex.indexByString('A8')).value = TextCellValue('Total Ganancias');
    sheet.cell(CellIndex.indexByString('B8')).value = DoubleCellValue(reporte.totalGanancias);
    sheet.cell(CellIndex.indexByString('A9')).value = TextCellValue('Margen Ganancia (%)');
    sheet.cell(CellIndex.indexByString('B9')).value = DoubleCellValue(reporte.margenGanancia);

    // Ventas por tipo
    int row = 11;
    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('VENTAS POR TIPO');
    row++;
    sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue('Tipo');
    sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue('Cantidad');
    sheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue('Ingresos');
    row++;

    for (final entry in reporte.ventasPorTipo.entries) {
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(_getTipoDisplayName(entry.key));
      sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(entry.value);
      sheet.cell(CellIndex.indexByString('C$row')).value = DoubleCellValue(reporte.ingresosPorTipo[entry.key] ?? 0.0);
      row++;
    }
  }

  void _crearHojaDetalle(Sheet sheet, ReporteVentas reporte) {
    // Encabezados
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Fecha');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Cliente');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Tipo');
    sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Cantidad');
    sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Precio Unitario');
    sheet.cell(CellIndex.indexByString('F1')).value = TextCellValue('Total');
    sheet.cell(CellIndex.indexByString('G1')).value = TextCellValue('Ganancia');

    // Datos
    int row = 2;
    for (final venta in reporte.ventasDetalle) {
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(venta.fecha));
      sheet.cell(CellIndex.indexByString('B$row')).value = TextCellValue(venta.clienteNombre);
      sheet.cell(CellIndex.indexByString('C$row')).value = TextCellValue(venta.tipoDisplayName);
      sheet.cell(CellIndex.indexByString('D$row')).value = IntCellValue(venta.cantidad);
      sheet.cell(CellIndex.indexByString('E$row')).value = DoubleCellValue(venta.precioUnitario);
      sheet.cell(CellIndex.indexByString('F$row')).value = DoubleCellValue(venta.total);
      sheet.cell(CellIndex.indexByString('G$row')).value = DoubleCellValue(venta.ganancia);
      row++;
    }
  }

  void _crearHojaClientes(Sheet sheet, ReporteVentas reporte) {
    // Encabezados
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Cliente');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Total Ventas');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Total Compras');
    sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Promedio Compra');
    sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Última Compra');

    // Datos
    int row = 2;
    for (final cliente in reporte.clientesTop) {
      sheet.cell(CellIndex.indexByString('A$row')).value = TextCellValue(cliente.nombreCompleto);
      sheet.cell(CellIndex.indexByString('B$row')).value = IntCellValue(cliente.totalVentas);
      sheet.cell(CellIndex.indexByString('C$row')).value = DoubleCellValue(cliente.totalCompras);
      sheet.cell(CellIndex.indexByString('D$row')).value = DoubleCellValue(cliente.promedioCompra);
      sheet.cell(CellIndex.indexByString('E$row')).value = TextCellValue(DateFormat('dd/MM/yyyy').format(cliente.ultimaCompra));
      row++;
    }
  }

  // Métodos auxiliares
  Future<void> _solicitarPermisos() async {
    if (Platform.isAndroid) {
      // Para Android 11+ (API 30+), usar manageExternalStorage
      if (await Permission.manageExternalStorage.isGranted) {
        return;
      }
      
      // Intentar con manageExternalStorage primero
      var status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return;
      }
      
      // Si no funciona, intentar con storage tradicional
      status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        if (!result.isGranted) {
          throw Exception('Permisos de almacenamiento requeridos para guardar archivos. Por favor, otorga permisos en la configuración de la aplicación.');
        }
      }
    } else if (Platform.isIOS) {
      // iOS no requiere permisos explícitos para almacenamiento en el directorio de documentos
    }
  }

  Future<String> _guardarArchivo(Uint8List bytes, String fileName) async {
    try {
      if (Platform.isAndroid) {
        // Para Android, usar múltiples estrategias
        return await _guardarArchivoAndroid(bytes, fileName);
      } else {
        // Para iOS, usar el directorio de documentos
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        return file.path;
      }
    } catch (e) {
      debugPrint('Error guardando archivo: $e');
      // Fallback final: usar directorio de documentos de la app
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    }
  }

  Future<String> _guardarArchivoAndroid(Uint8List bytes, String fileName) async {
    try {
      // Estrategia 1: Intentar guardar en Downloads público tradicional
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        final file = File('${downloadsDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        debugPrint('✅ Archivo guardado exitosamente en Downloads: ${file.path}');
        
        // Verificar que el archivo se creó correctamente
        if (await file.exists()) {
          final fileSize = await file.length();
          debugPrint('📁 Archivo confirmado - Tamaño: ${fileSize} bytes');
          return file.path;
        }
      }
    } catch (e) {
      debugPrint('❌ Error guardando en Downloads público: $e');
    }

    try {
      // Estrategia 2: Usar getExternalStorageDirectory
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        // Crear carpeta Downloads dentro del directorio externo
        final downloadsDir = Directory('${externalDir.path}/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        
        final file = File('${downloadsDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        debugPrint('✅ Archivo guardado en directorio externo: ${file.path}');
        
        // Verificar que el archivo se creó correctamente
        if (await file.exists()) {
          final fileSize = await file.length();
          debugPrint('📁 Archivo confirmado - Tamaño: ${fileSize} bytes');
          return file.path;
        }
      }
    } catch (e) {
      debugPrint('❌ Error guardando en directorio externo: $e');
    }

    try {
      // Estrategia 3: Usar directorio de documentos de la app como último recurso
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      debugPrint('✅ Archivo guardado en directorio de la app: ${file.path}');
      
      // Verificar que el archivo se creó correctamente
      if (await file.exists()) {
        final fileSize = await file.length();
        debugPrint('📁 Archivo confirmado - Tamaño: ${fileSize} bytes');
        return file.path;
      }
    } catch (e) {
      debugPrint('❌ Error guardando en directorio de la app: $e');
      throw Exception('No se pudo guardar el archivo en ningún directorio');
    }
    
    throw Exception('No se pudo verificar que el archivo se guardó correctamente');
  }

  String _formatearFechaArchivo(DateTime fecha) {
    return DateFormat('yyyyMMdd').format(fecha);
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
}
