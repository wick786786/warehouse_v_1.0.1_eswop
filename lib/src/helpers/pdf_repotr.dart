import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';

/// Styles for PDF document
class PdfStyles {
  static final title = pw.TextStyle(
    fontSize: 24,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blue900,
  );

  static final heading = pw.TextStyle(
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.blue800,
  );

  static final body = pw.TextStyle(
    fontSize: 12,
    color: PdfColors.black,
  );

  static final footer = pw.TextStyle(
    fontSize: 10,
    color: PdfColors.grey600,
  );
}

/// PDF Report Generator
class PdfReportGenerator {
  /// Generates and downloads a PDF report containing hardware information
  static Future<void> downloadPdfReport(
    BuildContext context,
    Map<String, String> hardwareInfo,
  ) async {
    try {
      final pdf = await _generatePdf(hardwareInfo);
      final savedFile = await _savePdfFile();

      if (savedFile == null) {
        _showNotification(
          context,
          'Save operation canceled',
          Colors.orange,
        );
        return;
      }

      await _writeAndOpenPdf(savedFile, pdf);
      _showNotification(
        context,
        'Report downloaded successfully. Opening PDF...',
        Colors.green,
      );
    } catch (error) {
      _showNotification(
        context,
        'Error generating report: $error',
        Colors.red,
      );
    }
  }

  /// Generates the PDF document with formatted content
  static Future<pw.Document> _generatePdf(
    Map<String, String> hardwareInfo,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: _buildHeader,
        footer: _buildFooter,
        build: (context) => _buildContent(hardwareInfo),
      ),
    );

    return pdf;
  }

  /// Builds the header section of the PDF
  static pw.Widget _buildHeader(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Hardware Details Report', style: PdfStyles.title),
          pw.SizedBox(height: 4),
          pw.Divider(borderStyle: pw.BorderStyle.dashed),
        ],
      ),
    );
  }

  /// Builds the footer section of the PDF
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Generated on: ${DateTime.now().toString()}',
        style: PdfStyles.footer,
      ),
    );
  }

  /// Builds the main content of the PDF
  static List<pw.Widget> _buildContent(Map<String, String> hardwareInfo) {
    return [
      pw.SizedBox(height: 20),
      ...hardwareInfo.entries.map((entry) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    '${entry.key}:',
                    style: PdfStyles.heading,
                  ),
                ),
                pw.Expanded(
                  flex: 3,
                  child: pw.Text(
                    entry.value,
                    style: PdfStyles.body,
                  ),
                ),
              ],
            ),
          )),
    ];
  }

  /// Prompts user to choose save location
  static Future<String?> _savePdfFile() async {
    return FilePicker.platform.saveFile(
      dialogTitle: 'Choose location to save report',
      allowedExtensions: ['pdf'],
      type: FileType.custom,
      fileName: 'Hardware_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  /// Writes and opens the PDF file
  static Future<void> _writeAndOpenPdf(
    String filePath,
    pw.Document pdf,
  ) async {
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(filePath);
  }

  /// Shows notification message
  static void _showNotification(
    BuildContext context,
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}