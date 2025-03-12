import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:warehouse_phase_1/src/helpers/pdf_repotr.dart';

class HardwareDetailsPage extends StatefulWidget {
  final String deviceId;

  const HardwareDetailsPage({Key? key, required this.deviceId}) : super(key: key);

  @override
  _HardwareDetailsPageState createState() => _HardwareDetailsPageState();
}

class _HardwareDetailsPageState extends State<HardwareDetailsPage> {
  Map<String, dynamic> _hardwareInfo = {};
  bool _isLoading = true;
  String? _savedFilePath;

  @override
  void initState() {
    super.initState();
    fetchHardwareDetails();
  }

  Future<String> _executeAdbCommand(List<String> command) async {
    try {
      final result = await Process.run('adb', ['-s', widget.deviceId, ...command]);
      if (result.exitCode == 0) {
        return result.stdout.toString();
      }
      print('Error executing ${command.join(' ')}: ${result.stderr}');
      return 'Error executing command';
    } catch (e) {
      print('Exception executing ${command.join(' ')}: $e');
      return 'Error: $e';
    }
  }

  Future<void> fetchHardwareDetails() async {
    try {
      // Fetch CPU Info
      String processorInfo = await _executeAdbCommand([
        'shell',
        'cat /proc/cpuinfo'
      ]);

      // Fetch ABI
      String abi = await _executeAdbCommand([
        'shell',
        'getprop ro.product.cpu.abi'
      ]);

      // Fetch Supported ABI
      String supportedAbi = await _executeAdbCommand([
        'shell',
        'getprop ro.product.cpu.abilist'
      ]);

      // Battery Info
      String batteryInfo = await _executeAdbCommand([
        'shell',
        'dumpsys battery'
      ]);

      // Display Info
      String displayInfo = await _executeAdbCommand([
        'shell',
        'dumpsys display'
      ]);

      // Refresh Rate Info
      String refreshRateInfo = await _executeAdbCommand([
        'shell',
        'dumpsys display | grep -E "DisplayDeviceInfo|refreshRate"'
      ]);

      // GPU Info
      String gpuInfo = await _executeAdbCommand([
        'shell',
        'getprop ro.hardware.vulkan && getprop ro.opengles.version'
      ]);

      setState(() {
        _hardwareInfo = {
          'Processor': _formatProcessorInfo(processorInfo, abi.trim(), supportedAbi.trim()),
          'Battery': _formatBatteryInfo(batteryInfo),
          'Display': _formatDisplayInfo(displayInfo),
          'GPU': _formatGpuInfo(gpuInfo),
        };
        _isLoading = false;
      });
      // Save the JSON file after fetching
      await _saveHardwareInfoToJson();
    } catch (e) {
      print('Error fetching hardware details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveHardwareInfoToJson() async {
    try {
      // Create a formatted timestamp for the filename
      String timestamp = DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '');
      String fileName = 'hardware_details_${widget.deviceId}_$timestamp.json';

      // Get the application documents directory
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String filePath = '${appDocDir.path}/hardware_details';

      // Create the directory if it doesn't exist
      Directory(filePath).createSync(recursive: true);

      // Create the full file path
      String fullPath = '$filePath/$fileName';

      // Convert the hardware info to JSON with proper formatting
      String jsonContent = JsonEncoder.withIndent('  ').convert(_hardwareInfo);

      // Write the JSON to file
      File file = File(fullPath);
      await file.writeAsString(jsonContent);

      setState(() {
        _savedFilePath = fullPath;
      });

      print('Hardware details saved to: $fullPath');
    } catch (e) {
      print('Error saving hardware details to JSON: $e');
    }
  }

  Future<void> _downloadPdfReport() async {
    await PdfReportGenerator.downloadPdfReport(context, _hardwareInfo.map((key, value) => MapEntry(key, value.toString())));
  }

  // Optional: Method to retrieve the saved JSON file
  Future<Map<String, dynamic>?> _loadHardwareInfoFromJson() async {
    try {
      if (_savedFilePath != null) {
        File file = File(_savedFilePath!);
        if (await file.exists()) {
          String jsonContent = await file.readAsString();
          return json.decode(jsonContent);
        }
      }
      return null;
    } catch (e) {
      print('Error loading hardware details from JSON: $e');
      return null;
    }
  }

  String _formatProcessorInfo(String raw, String abi, String supportedAbi) {
    List<String> parts = raw.trim().split('\n');

    // Variables to store extracted data
    String hardware = 'Unknown';
    int cores = 0;
    String cpuDetails = '';
    String process = 'Unknown';

    // Loop through each line of the raw string
    for (String line in parts) {
      if (line.startsWith('Hardware')) {
        hardware = line.split(':').last.trim();
      } else if (line.startsWith('processor')) {
        cores++; // Count the number of processors to determine the number of cores
      } else if (line.startsWith('CPU part')) {
        // For simplicity, assuming part represents a portion of the CPU details
        cpuDetails += ' ${line.split(':').last.trim()}';
      }
    }

    return '''
Hardware: $hardware
Cores: $cores
ABI: $abi
Supported ABI: $supportedAbi
''';
  }

  String _formatBatteryInfo(String raw) {
    Map<String, String> batteryStats = {};

    // Splitting the input and parsing key-value pairs
    for (String line in raw.split('\n')) {
      if (line.contains(':')) {
        List<String> parts = line.split(':');
        if (parts.length == 2) {
          batteryStats[parts[0].trim()] = parts[1].trim();
        }
      }
    }

    // Convert health status into human-readable format
    String healthStatus;
    switch (batteryStats['health']) {
      case '1':
        healthStatus = 'Good';
        break;
      case '2':
        healthStatus = 'Overheat';
        break;
      case '3':
        healthStatus = 'Dead';
        break;
      case '4':
        healthStatus = 'Over Voltage';
        break;
      case '5':
        healthStatus = 'Unspecified Failure';
        break;
      case '6':
        healthStatus = 'Cold';
        break;
      default:
        healthStatus = 'Unknown';
    }

    // Convert charging status into human-readable format
    String chargingStatus;
    switch (batteryStats['status']) {
      case '1':
        chargingStatus = 'Charging';
        break;
      case '2':
        chargingStatus = 'Discharging';
        break;
      case '3':
        chargingStatus = 'Not charging';
        break;
      case '4':
        chargingStatus = 'Full';
        break;
      case '5':
        chargingStatus = 'Charging (completed)';
        break;
      default:
        chargingStatus = 'Unknown';
    }

    return '''
Level: ${batteryStats['level'] ?? 'Unknown'}%
Status: $chargingStatus
Health: $healthStatus
Temperature: ${batteryStats['temperature'] != null ? '${int.parse(batteryStats['temperature']!) / 10}°C' : 'Unknown'}
Voltage: ${batteryStats['voltage'] != null ? '${int.parse(batteryStats['voltage']!)} mV' : 'Unknown'}
Technology: ${batteryStats['technology'] ?? 'Unknown'}
''';
  }

  String _formatDisplayInfo(String raw) {
    // Extract the relevant details using regex or string manipulation.
    RegExp resolutionPattern = RegExp(r'\d+ x \d+');
    RegExp densityPattern = RegExp(r'density (\d+)');
    RegExp refreshRatePattern = RegExp(r'renderFrameRate ([\d.]+)');
    RegExp supportedFpsPattern = RegExp(r'fps=([\d.]+), alternativeRefreshRates=\[([\d.]+)\]');
    RegExp hdrPattern = RegExp(r'supportedHdrTypes=\[([\d, ]+)\]');
    RegExp brightnessPattern = RegExp(r'brightnessMinimum ([\d.]+), brightnessMaximum ([\d.]+), brightnessDefault ([\d.]+)');
    RegExp roundedCornersPattern = RegExp(r'RoundedCorner\{position=TopLeft, radius=(\d+)');

    String resolution = resolutionPattern.firstMatch(raw)?.group(0) ?? 'Unknown';
    String density = densityPattern.firstMatch(raw)?.group(1) ?? 'Unknown';
    String renderFrameRate = refreshRatePattern.firstMatch(raw)?.group(1) ?? 'Unknown';
    String fps = supportedFpsPattern.firstMatch(raw)?.group(1) ?? 'Unknown';
    String alternativeFps = supportedFpsPattern.firstMatch(raw)?.group(2) ?? 'Unknown';
    String hdrCapabilities = hdrPattern.firstMatch(raw)?.group(1) ?? 'Unknown';
    String brightnessMin = brightnessPattern.firstMatch(raw)?.group(1) ?? 'Unknown';
    String brightnessMax = brightnessPattern.firstMatch(raw)?.group(2) ?? 'Unknown';
    String brightnessDefault = brightnessPattern.firstMatch(raw)?.group(3) ?? 'Unknown';
    String roundedCorners = roundedCornersPattern.firstMatch(raw)?.group(1) ?? 'Unknown';

    // Calculate the aspect ratio based on resolution
    List<String> resolutionParts = resolution.split('x');
    String aspectRatio = (int.parse(resolutionParts[0]) / int.parse(resolutionParts[1])).toStringAsFixed(2);

    return '''
Resolution: $resolution
Density (DPI): $density
Aspect Ratio: $aspectRatio:1
Frame Rate: $renderFrameRate Hz
Supported FPS: $fps fps (Alternative: $alternativeFps fps)
HDR Capabilities: $hdrCapabilities
Brightness: Min $brightnessMin, Max $brightnessMax, Default $brightnessDefault
Rounded Corners Radius: $roundedCorners px
''';
  }

  String _formatGpuInfo(String raw) {
    List<String> parts = raw.trim().split('\n');
    return '''
Vulkan: ${parts.isNotEmpty ? parts[0] : 'Unknown'}
OpenGL ES: ${parts.length > 1 ? parts[1] : 'Unknown'}
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add FloatingActionButton for download
      floatingActionButton: !_isLoading
          ? FloatingActionButton.extended(
              onPressed: _downloadPdfReport,
              label: const Text('Download Report'),
              icon: const Icon(Icons.download),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
      // Position the FAB at the bottom center
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Custom App Bar
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Hardware Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.developer_board,
                      size: 80,
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ),

            // Main Content
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      // Add bottom padding to prevent FAB from overlapping content
                      vertical: 16.0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Hardware Info Cards
                        ..._hardwareInfo.entries.map((entry) {
                          return _buildHardwareCard(entry.key, entry.value);
                        }).toList(),
                        // Add extra padding at the bottom to ensure content isn't hidden behind FAB
                        const SizedBox(height: 80),
                      ]),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareCard(String title, String details) {
    final IconData icon = _getIconForTitle(title);
    final Color iconColor = _getColorForTitle(title);

    // Function to format details text
    Widget _buildFormattedDetails(String details) {
      final lines = details.split('\n');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          if (line.trim().isEmpty) return const SizedBox(height: 8);

          final parts = line.split(':');
          if (parts.length < 2) return Text('• $line');

          final label = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                  ),
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 14.0,
                        height: 1.5,
                        letterSpacing: 0.2,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(
                          text: label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ': $value',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Semantics(
      button: true,
      label: '$title hardware information',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: iconColor.withOpacity(0.1),
            highlightColor: iconColor.withOpacity(0.05),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24.0,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16.0,
                letterSpacing: -0.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            childrenPadding: EdgeInsets.zero,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20.0),
                    bottomRight: Radius.circular(20.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      height: 1,
                    ),
                    const SizedBox(height: 16),
                    _buildFormattedDetails(details),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Processor':
        return Icons.memory;
      case 'Battery':
        return Icons.battery_full;
      case 'Display':
        return Icons.phone_android;
      case 'GPU':
        return Icons.games;
      default:
        return Icons.info;
    }
  }

  Color _getColorForTitle(String title) {
    switch (title) {
      case 'Processor':
        return Colors.blue;
      case 'Temperature':
        return Colors.orange;
      case 'Memory':
        return Colors.purple;
      case 'Battery':
        return Colors.green;
      case 'Camera':
        return Colors.indigo;
      case 'Display':
        return Colors.cyan;
      case 'Storage':
        return Colors.amber;
      case 'GPU':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
