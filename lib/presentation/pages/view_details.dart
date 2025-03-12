import 'package:intl/intl.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/src/core/constants.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:warehouse_phase_1/src/helpers/android_hardware_details.dart';
import 'package:warehouse_phase_1/src/helpers/api_services.dart';
import 'dart:io';

import 'package:warehouse_phase_1/src/helpers/iphone_device_info.dart';
import 'package:warehouse_phase_1/src/helpers/iphone_model.dart';
//import 'package:printing/printing.dart';

class DeviceDetails extends StatefulWidget {
  final Map<String, dynamic> details;
  final List<Map<String, dynamic>> hardwareChecks;
  final DeviceInfoManager _deviceInfoManager = DeviceInfoManager();
  bool jail_status = false;
  bool blacklistCheck = false;
  final List<Map<String, dynamic>> pqchecks;
 // DateTime formattedDate = DateTime.parse('YYYY-MM-DD HR:MN:SEC');
  DeviceDetails({
    super.key,
    required this.details,
    required this.hardwareChecks,
    required this.pqchecks,
    
  });

  @override
  _DeviceDetailsState createState() => _DeviceDetailsState();
}

class _DeviceDetailsState extends State<DeviceDetails> {
  //final Map<String, dynamic> details;
  PreferencesHelper prefsHelper = PreferencesHelper();
  ApiServices apiServices = ApiServices();
  //AndroidHardwareDetails androidHardwareDetails = AndroidHardwareDetails();
  String? verdict;
  //final List<Map<String, dynamic>> hardwareChecks;
 final deviceInfo = DeviceInfoManager();
  final Map<String, String> status = {
    '1': 'success',
    '0': 'Fail',
    '-1': 'Skip',
    '-2': 'Not supported'
  };
  @override
  void initState(){
    print("details in view details page:${widget.details}");
    print("physical question checks in view details page:${widget.pqchecks}");
    print("hardware checks in view details page:${widget.hardwareChecks}");

    modifyHardwareChecks();
    blacklistcheck(widget.details['iemi']);
    if(widget.details['manufacturer']=='Apple')
    {
      JailBreak(widget.details['serialNumber']);
    }
   
    super.initState();
   // _loadVerdict();
  }

  void modifyHardwareChecks() {
    for (var check in widget.hardwareChecks) {
      if (check.containsKey('frontCamera_manual')) {
        check['front camera'] = check.remove('frontCamera_manual');
      }
      if (check.containsKey('backCamera_manual')) {
        check['back camera'] = check.remove('backCamera_manual');
      }
    }
  }

  void blacklistcheck(String imei)async
  {
    print('imei in view detail${imei}');
   widget.blacklistCheck = await apiServices.blacklistCheck(imei);
   // widget.blacklistCheck=status??false;
    print("blacklist status in view details: ${widget.blacklistCheck}"); // Output: Device123 status: true
  }
 
  void JailBreak(String deviceId)async{
    print('deviceId in vir=ew detail${deviceId}');
      bool? status = await PreferencesHelper.getJailBreak(deviceId);
      widget.jail_status=status??false;
      print("jailbreak status in view details: $status"); // Output: Device123 status: true
    
  }

  // Load the verdict from SharedPreferences
  // Future<void> _loadVerdict() async {
  //   String? fetchedVerdict = await _fetchVerdict();
  //   setState(() {
  //     verdict = fetchedVerdict;
  //   });
  // }

  //required this.hardwareChecks});
  String _formatToLocalTime(String? createdAt) {
    // Check if createdAt is null or not in a valid date format
    if (createdAt == null || createdAt == 'N/A') {
      return 'Invalid Date'; // Return a fallback value
    }

    try {
      // Parse the createdAt string to DateTime (assuming it's in ISO 8601 format)
      DateTime utcTime = DateTime.parse(createdAt).toLocal();
      print("utcTime:$utcTime");

      // Convert UTC time to Indian Standard Time (IST)
      DateTime istTime = utcTime.add(const Duration(
          hours: 5, minutes: 30)); // Corrected to 5 hours 30 minutes for IST

      // Format the IST time as a string
      String formattedTime =
          "${istTime.day}-${istTime.month}-${istTime.year} ${istTime.hour}:${istTime.minute}:${istTime.second}";
      print(formattedTime);

      return formattedTime;
    } catch (e) {
      // Handle any parsing errors
      return 'Invalid Date'; // Return a fallback value
    }
  }

  Future<String> executeShellCommand(String deviceId, String command) async {
    ProcessResult result =
        await Process.run('adb', ['-s', deviceId, 'shell', command]);
    if (result.exitCode != 0) {
      return '';
    }
    return result.stdout.toString().trim();
  }

  // Future<String?> _fetchVerdict() async {
  //   return await prefsHelper.getVerdict(widget.details['sno']);
  // }
Future<void> _printLabel(BuildContext context) async {
  final pdf = pw.Document();

  // Check if the device is blacklisted
  bool isBlacklisted = widget.hardwareChecks.any((check) =>
      check.containsKey('Blacklist') && check['Blacklist'] == '1');

  // Filter hardware checks by status
  final failedChecks = widget.hardwareChecks.where((check) => 
    check.values.any((value) => value == '0')).toList();
  final skippedChecks = widget.hardwareChecks.where((check) => 
    check.values.any((value) => value == '-1')).toList();
  final notSupportedChecks = widget.hardwareChecks.where((check) => 
    check.values.any((value) => value == '-2')).toList();

  print('failed check :$failedChecks');

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80.copyWith(
        marginTop: 0,
        marginBottom: 0,
        marginLeft: 0,
        marginRight: 0,
      ),
      build: (pw.Context context) {
        return pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              if (isBlacklisted)
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red, width: 2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                    color: PdfColors.red100,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'BLACKLISTED DEVICE',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red,
                      ),
                    ),
                  ),
                ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${widget.details['manufacturer']} ${widget.details['model']}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(),
              pw.SizedBox(height: 4),
              pw.Text(
                'RAM: ${widget.details['ram']??'N/A'}, ROM: ${widget.details['rom_gb'] ?? widget.details['rom']??'N/A'}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'IMEI: ${widget.details['iemi']}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'S/N: ${widget.details['sno'] ?? widget.details['serialNumber']}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Version: ${widget.details['ver'] ?? widget.details['androidVersion']}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Carrier Lock: ${widget.details['simLock']??widget.details['carrier_lock_status']}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              if (widget.details['manufacturer'] == 'Apple') ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  'Jailbreak Status: ${widget.jail_status ? 'Active' : 'Inactive'}',
                  style: pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
              pw.Divider(),
              
              // Failed Checks Section
              if (failedChecks.isNotEmpty) ...[
                pw.Text(
                  'Failed Checks:',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                ),
                ...failedChecks.map((check) => pw.Text(
                  '- ${check.keys.first}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.red),
                )),
                pw.SizedBox(height: 4),
              ],

              // Skipped Checks Section
              if (skippedChecks.isNotEmpty) ...[
                pw.Text(
                  'Skipped Checks:',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange),
                ),
                ...skippedChecks.map((check) => pw.Text(
                  '- ${check.keys.first}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.orange),
                )),
                pw.SizedBox(height: 4),
              ],

              // Not Supported Checks Section
              if (notSupportedChecks.isNotEmpty) ...[
                pw.Text(
                  'Not Supported Checks:',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey),
                ),
                ...notSupportedChecks.map((check) => pw.Text(
                  '- ${check.keys.first}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                )),
                pw.SizedBox(height: 4),
              ],

              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Device Diagnostic Label',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  // Let the user choose the location to save the file
  String? outputFile = await FilePicker.platform.saveFile(
    dialogTitle: 'Choose location to save',
    allowedExtensions: ['pdf'],
    type: FileType.custom,
    lockParentWindow: true,
    fileName: '${widget.details['iemi']}_label.pdf',
  );

  if (outputFile == null) {
    print('User canceled the save dialog');
    return;
  }

  // Save the PDF to the chosen location
  final file = File(outputFile);
  await file.writeAsBytes(await pdf.save());

  // Show success message on screen
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Label downloaded successfully. Opening PDF...'),
      duration: Duration(seconds: 3),
    ),
  );

  // Open the PDF file automatically
  await OpenFilex.open(outputFile);
}




Future<void> _downloadReport() async {
  try {
    bool isBlacklisted = widget.hardwareChecks.any((check) =>
        check.containsKey('Blacklist') && check['Blacklist'] == '1');
    final warehouseDir =
        Directory(path.join(Directory.current.path, 'warehouse'));
    if (!await warehouseDir.exists()) {
      await warehouseDir.create();
    }

    final imei = widget.details['iemi']?.toString() ?? 'unknown_device';
    final deviceDir = Directory(path.join(warehouseDir.path, imei));
    if (!await deviceDir.exists()) {
      await deviceDir.create();
    }

    final pdf = pw.Document();

    final headerStyle = pw.TextStyle(
      fontSize: 28,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey800,
    );

    final sectionHeaderStyle = pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey800,
    );

    final labelStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey600,
    );

    final valueStyle = pw.TextStyle(
      fontSize: 14,
      color: PdfColors.black,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 20),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(width: 1, color: PdfColors.grey300),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Device Diagnostic Report',
                style: headerStyle,
              ),
              pw.Text(
                'ID: $imei',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated on ${widget.details['createdAt']?.toString() ?? 'N/A'}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (pw.Context context) => [
          if (widget.blacklistCheck==true)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 20),
              padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: pw.BoxDecoration(
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                color: PdfColors.red50,
                border: pw.Border.all(color: PdfColors.red400, width: 2),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    ' BLACKLISTED DEVICE',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red700,
                    ),
                  ),
                ],
              ),
            ),

          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Hardware Details', style: sectionHeaderStyle),
                pw.SizedBox(height: 12),
                _buildInfoRow('Manufacturer', widget.details['manufacturer']?.toString() ?? 'N/A', labelStyle, valueStyle),
                _buildInfoRow('Type', 'Smartphone', labelStyle, valueStyle),
                _buildInfoRow('RAM', widget.details['ram']?.toString() ?? 'N/A', labelStyle, valueStyle),
                _buildInfoRow('ROM',widget.details['rom']??widget.details['rom_gb']?.toString() ?? 'N/A', labelStyle, valueStyle),
                _buildInfoRow('Model', widget.details['model']?.toString() ?? 'N/A', labelStyle, valueStyle),
                _buildInfoRow('IMEI', imei, labelStyle, valueStyle),
              ],
            ),
          ),
          
          pw.SizedBox(height: 40),

          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Software Information', style: sectionHeaderStyle),
                pw.SizedBox(height: 12),
                _buildInfoRow('OS Name', widget.details['manufacturer']=='Apple'?'IOS':'Android', labelStyle, valueStyle),
                _buildInfoRow('OS Version', widget.details['ver']==null?widget.details['androidVersion'].toString():'N/A', labelStyle, valueStyle),
                _buildInfoRow('MDM Status', 
                  widget.details['mdmStatus'] == 'true' ? 'Active' : widget.details['mdmStatus'] == 'false' ? 'Inactive' : 'N/A',
                  labelStyle,
                  valueStyle
                ),
                _buildInfoRow('OEM Status',
                  widget.details['oem'] == '0' ? 'Inactive' : widget.details['oem'] == '1' ? 'Active' : 'N/A',
                  labelStyle,
                  valueStyle
                ),
                _buildInfoRow('Carrier Lock Status',
                  widget.details['simLock']?.toString() ?? 'N/A',
                  labelStyle,
                  valueStyle
                ),
                  if (widget.details['manufacturer'] == 'Apple') ...[
                pw.SizedBox(height: 4),
                _buildInfoRow('Jail Break', widget.jail_status?'Active':'Inactive', labelStyle, valueStyle),

              ],
              ],
            ),
          ),

          pw.SizedBox(height: 20),
          pw.NewPage(),
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Diagnostics Result', style: sectionHeaderStyle),
                pw.SizedBox(height: 12),
                pw.Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: widget.hardwareChecks.map((check) {
                    final key = check.keys.first;
                    final value = check.values.first?.toString() ?? 'N/A';
                    
                    PdfColor bgColor;
                    PdfColor textColor;
                    String status;

                    switch (value) {
                      case '1':
                        bgColor = PdfColors.green50;
                        textColor = PdfColors.green700;
                        status = 'Passed';
                        break;
                      case '0':
                        bgColor = PdfColors.red50;
                        textColor = PdfColors.red700;
                        status = 'Failed';
                        break;
                      case '-1':
                        bgColor = PdfColors.orange50;
                        textColor = PdfColors.orange700;
                        status = 'Skipped';
                        break;
                      default:
                        bgColor = PdfColors.grey100;
                        textColor = PdfColors.grey700;
                        status = 'Not Supported';
                    }

                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: pw.BoxDecoration(
                        color: bgColor,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Text(
                        '$key: $status',
                        style: pw.TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              color: PdfColors.grey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Physical Questions', style: sectionHeaderStyle),
                pw.SizedBox(height: 12),
                pw.Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: widget.pqchecks.expand((checkMap) {
                    return checkMap.entries.map((entry) {
                      String key = entry.key;
                      String value = entry.value.toString();
                      
                      PdfColor bgColor = PdfColors.blue50;
                      PdfColor textColor = PdfColors.blue700;
                      
                      if (value.toLowerCase().contains('broken dead pixel liquid mark or does not work properly') || 
                          value.toLowerCase().contains('damaged or stripped screws') ||
                          value.toLowerCase().contains('cracked')||
                          value.toLowerCase().contains('broken')||
                          
                          value.toLowerCase().contains('dent') || 
                          value.toLowerCase().contains('swollen') ||
                          value.toLowerCase().contains('slow restart') 
                          ) {
                        bgColor = PdfColors.red50;
                        textColor = PdfColors.red700;
                      } else if (value.toLowerCase().contains('2-3 minor scratches') ||
                                 value.toLowerCase().contains('shaded/white dots')||
                                 value.toLowerCase().contains('missing screws')||
                                 value.toLowerCase().contains('loose screws')||
                                  value.toLowerCase().contains('scratches/dents')||
                                  value.toLowerCase().contains('discolored')||
                                  value.toLowerCase().contains('draining fast')
                                 ) {
                        bgColor = PdfColors.orange50;
                        textColor = PdfColors.orange700;
                      }
                      
                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: pw.BoxDecoration(
                          color: bgColor,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Text(
                          '$key: $value',
                          style: pw.TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList();
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  String? reportFile = await FilePicker.platform.saveFile(
    dialogTitle: 'Choose location to save',
    allowedExtensions: ['pdf'],
    type: FileType.custom,
    lockParentWindow: true,
    fileName: '${widget.details['iemi']}_report.pdf',
  );

  if (reportFile == null) {
    print('User canceled the save dialog');
    return;
  }

  final file = File(reportFile);
  await file.writeAsBytes(await pdf.save());

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Label downloaded successfully. Opening PDF...'),
      duration: Duration(seconds: 3),
    ),
  );

  await OpenFilex.open(reportFile);
  } catch (error) {
    print('Error generating report: $error');
  }
}

// Helper method to build consistent info rows
pw.Widget _buildInfoRow(String label, String value, pw.TextStyle labelStyle, pw.TextStyle valueStyle) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 140,
          child: pw.Text(label, style: labelStyle),
        ),
        pw.Expanded(
          child: pw.Text(value, style: valueStyle),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
  print('details of devices view details page :${widget.details}');
  bool isBlacklisted = widget.hardwareChecks
      .any((check) => check.containsKey('Blacklist') && check['Blacklist'] == '1');

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 24.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: valueColor ?? Theme.of(context).colorScheme.onSurface,
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

  Widget _buildHardwareCheckGrid() {
    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: widget.hardwareChecks.map((check) {
        String key = check.keys.first;
        String value = check.values.first.toString();
        
        Color backgroundColor;
        Color textColor;
        IconData icon;
        String status;

        switch (value) {
          case '1':
            backgroundColor = Colors.green.withOpacity(0.1);
            textColor = Colors.green;
            icon = Icons.check_circle;
            status = 'Passed';
            break;
          case '0':
            backgroundColor = Colors.red.withOpacity(0.1);
            textColor = Colors.red;
            icon = Icons.cancel;
            status = 'Failed';
            break;
          case '-1':
            backgroundColor = Colors.orange.withOpacity(0.1);
            textColor = Colors.orange;
            icon = Icons.warning;
            status = 'Skipped';
            break;
          default:
            backgroundColor = Colors.grey.withOpacity(0.1);
            textColor = Colors.grey;
            icon = Icons.block;
            status = 'Not Supported';
        }

        return Container(
          width: MediaQuery.of(context).size.width / 2 - 24,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: textColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: textColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      key,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhysicalQuestionGrid() {
  // Assuming widget.pqchecks is a List of Maps, with each Map containing multiple checks
  return widget.pqchecks.isEmpty
      ? const Center(child: Text("No physical checks available"))
      : Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: widget.pqchecks.expand((checkMap) {
            // For each map in the list, create a card for each key-value pair
            return checkMap.entries.map((entry) {
              String key = entry.key;
              String value = entry.value.toString();
              
              Color backgroundColor = Colors.blue.withOpacity(0.1);
              Color textColor = Colors.blue;
              IconData icon = Icons.check_circle;
              
              // Change colors and icons based on value
              if (value.toLowerCase().contains('broken dead pixel liquid mark or does not work properly') || 
                  value.toLowerCase().contains('damaged or stripped screws') ||
                  value.toLowerCase().contains('cracked')||
                  value.toLowerCase().contains('broken')||
                  value.toLowerCase().contains('swollen')||
                  value.toLowerCase().contains('dent')
                  ) {
                backgroundColor = Colors.red.withOpacity(0.1);
                textColor = Colors.red;
                icon = Icons.error;
              } else if (value.toLowerCase().contains('2-3 minor scratches') ||
                
                         value.toLowerCase().contains('shaded white dots')||
                         value.toLowerCase().contains('missing screws')||
                         value.toLowerCase().contains('scratches/dents')||
                         value.toLowerCase().contains('discolored')||
                         value.toLowerCase().contains('draining fast')||
                         value.toLowerCase().contains('overheat')||
                         value.toLowerCase().contains('slow restart')||
                          value.toLowerCase().contains('loose screws')
                         //value.toLowerCase().contains('draining fast')
                         ) {
                backgroundColor = Colors.amber.withOpacity(0.1);
                textColor = Colors.amber.shade800;
                icon = Icons.warning;
              }
              
              return Container(
                width: MediaQuery.of(context).size.width / 2 - 24,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: textColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 16, color: textColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            key,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          }).toList(),
        );
}

  return MaterialApp(
    theme: AppThemes.lightMode,
    home: Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Diagnostic Report', style: TextStyle(fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Container(
            //   color: Theme.of(context).colorScheme.primary,
            //   padding: const EdgeInsets.only(bottom: 32.0),
            //   child: Text(
            //     'Device Diagnostic Report',
            //     textAlign: TextAlign.center,
            //     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            //       color: Theme.of(context).colorScheme.onPrimary,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.blacklistCheck==true)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, 
                            color: Colors.red.shade700, 
                            size: 32
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BLACKLISTED DEVICE',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This device has been reported as blacklisted',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildInfoTile(
                    icon: Icons.info_outline,
                    title: 'Diagnose ID',
                    value: widget.details['iemi'],
                  ),
                  _buildInfoTile(
                    icon: Icons.calendar_today,
                    title: 'Diagnostic Date',
                    value: widget.details['createdAt'] ?? 'N/A',
                  ),

                  _buildSectionTitle('Hardware Details'),
                  _buildInfoTile(
                    icon: Icons.build_circle,
                    title: 'Manufacturer',
                    value: widget.details['manufacturer'],
                  ),
                  _buildInfoTile(
                    icon: Icons.device_unknown,
                    title: 'Device Type',
                    value: widget.details['manufacturer']=='Apple'?'Iphone':'Smartphone',
                  ),
                  _buildInfoTile(
                    icon: Icons.model_training,
                    title: 'Model',
                    value: widget.details['model'],
                  ),
                  _buildInfoTile(
                    icon: Icons.memory,
                    title: 'RAM',
                    value: widget.details['ram']??'N/A',
                  ),
                  _buildInfoTile(
                    icon: Icons.storage,
                    title: 'ROM',
                    value: widget.details['rom_gb'] ?? widget.details['rom']??'N/A',
                  ),
                    _buildInfoTile(
                    icon: Icons.security,
                    title: 'MDM Status',
                    value: widget.details['mdmStatus'] == 'true'
                      ? 'Active'
                      : widget.details['mdmStatus'] == 'false'
                        ? 'Inactive'
                        : 'N/A',
                    valueColor: widget.details['mdmStatus'] == 'false'
                      ? Colors.green
                      : widget.details['mdmStatus'] == 'true'
                        ? Colors.red
                        : Colors.grey,
                    ),
                    _buildInfoTile(
                    icon: Icons.lock,
                    title: 'OEM Status',
                    value: widget.details['oem'] == '0'
                      ? 'Inactive'
                      : widget.details['oem'] == '1'
                        ? 'Active'
                        : 'N/A',
                    valueColor: widget.details['oem'] == '0'
                      ? Colors.green
                      : widget.details['oem'] == '1'
                        ? Colors.red
                        : Colors.grey,
                    ),
                  if(widget.details['manufacturer']=='Apple')
                       _buildInfoTile(
                    icon: Icons.sim_card,
                    title: 'Jail Break',
                    value:widget.jail_status==true?'Active':'Inactive',
                    valueColor: widget.jail_status==true?Colors.red:Colors.green
                     ), 
                  _buildInfoTile(
                    icon: Icons.sim_card,
                    title: 'Carrier Lock Status',
                    value: widget.details['simLock'] ?? widget.details['carrier_lock_status'],
                    valueColor: widget.details['simLock']=='unlocked'?Colors.green:Colors.red
                  ),
                  _buildInfoTile(
                    icon: Icons.confirmation_number,
                    title: 'IMEI',
                    value: widget.details['iemi'],
                  ),

                  _buildSectionTitle('Software Information'),
                  _buildInfoTile(
                    icon: Icons.phone_android,
                    title: 'OS Name',
                    value: widget.details['manufacturer']=='Apple'?'IOS':'Android',
                  ),
                  _buildInfoTile(
                    icon: Icons.system_update_alt,
                    title: 'OS Version',
                    value: widget.details['ver']==null ? widget.details['androidVersion']:'N/A',
                  ),

                  if (!isBlacklisted) ...[
                    _buildSectionTitle('Diagnostics Result'),
                    _buildHardwareCheckGrid(),
                  ],

                  _buildSectionTitle('Physical Questions'),
                  _buildPhysicalQuestionGrid(),

                  _buildSectionTitle('Report Details'),
                  _buildInfoTile(
                    icon: Icons.calendar_today,
                    title: 'Diagnostic Date',
                    value: widget.details['createdAt'] ?? 'N/A',
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _downloadReport,
                          icon: const Icon(Icons.download),
                          label: const Text('Download Report'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _printLabel(context),
                          icon: const Icon(Icons.print),
                          label: const Text('Print Label'),
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
    ),
  );
}
}
