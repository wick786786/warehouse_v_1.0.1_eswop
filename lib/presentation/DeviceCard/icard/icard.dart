import 'package:flutter/material.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/icard/sync_result.dart';
import 'package:warehouse_phase_1/src/helpers/data_wipe_ios.dart';
import 'dart:io';
import 'package:process_run/shell.dart';

class Icard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget? content;
  final double? progress;
  final String udid;
  const Icard({
    super.key,
    required this.title,
    required this.subtitle,
    this.content,
    required this.udid,
    this.progress,
  });

  @override
  _IcardState createState() => _IcardState();
}

class _IcardState extends State<Icard> {
  String _installationStatus = '';
  bool _isInstalling = false;
  SyncResult syncResult = SyncResult();
  Future<void> _handleSync() async {
    // Use it
   bool response= await syncResult.syncResult(widget.udid);
    print("Response of sync result : $response");

// When you're done with the instance
    await syncResult.dispose();
  }

  Future<void> _handleInstallApp() async {
    setState(() {
      _isInstalling = true;
      _installationStatus = 'Fetching connected device UDID...';
    });

    try {
      // Step 1: Get the UDID of the connected device
      ProcessResult udidResult = await Process.run('idevice_id', ['-l']);
      if (udidResult.exitCode != 0 ||
          (udidResult.stdout as String).trim().isEmpty) {
        throw 'No connected device found. Please connect an iOS device.';
      }

      String udid = (udidResult.stdout as String)
          .trim()
          .split('\n')[0]; // First connected device
      print('Connected device UDID: $udid');

      // Step 2: Install the IPA using the fetched UDID
      setState(() {
        _installationStatus = 'Installing app on device: $udid...';
      });

      String executable = 'ideviceinstaller';
      List<String> arguments = [
        '-u',
        udid,
        '-i',
        'D:\\downloadsD\\InstaCashSDK (20).ipa'
      ];

      ProcessResult installResult = await Process.run(executable, arguments);
      if (installResult.exitCode == 0) {
        print('STDOUT: ${installResult.stdout}');
        setState(() {
          _isInstalling = false;
          _installationStatus = 'Installation Successful!';
        });
      } else {
        print('STDERR: ${installResult.stderr}');
        setState(() {
          _isInstalling = false;
          _installationStatus =
              'Installation Failed: ${installResult.stderr} (Exit Code: ${installResult.exitCode})';
        });
      }
    } catch (e, stackTrace) {
      print('Error: $e');
      print('StackTrace: $stackTrace');
      setState(() {
        _isInstalling = false;
        _installationStatus = 'Installation Failed: $e';
      });
    }
  }

  Future<void> handleSensitiveData() async {
    // Create a secure file
    final secureFile =
        await SecureDataWipeUtility.getSecureFilePath('user_secrets.txt');
    await secureFile.writeAsString('Confidential user data');

    // Securely wipe the file
    await SecureDataWipeUtility.wipeFile(secureFile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.all(10),
        constraints: const BoxConstraints(
          minHeight: 460,
          maxWidth: 170,
        ),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.08),
              width: 1,
            ),
          ),
          elevation: 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                                letterSpacing: -0.5,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (String value) {
                          if (value == 'install_app') {
                            _handleInstallApp();
                          } else if (value == 'sync_result') {
                            _handleSync();
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'install_app',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.download,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text('Install App'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'sync_result',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sync,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text('Sync Result'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Progress Section
                if (widget.progress != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getProgressColor(widget.progress!)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(widget.progress! * 100).toStringAsFixed(1)}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getProgressColor(widget.progress!),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: widget.progress!.clamp(0.0, 1.0),
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(widget.progress!),
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Content Section
                if (widget.content != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.surfaceVariant.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: DefaultTextStyle(
                        style: theme.textTheme.bodyMedium!.copyWith(
                          height: 1.3,
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        child: widget.content!,
                      ),
                    ),
                  ),
                ],

                // Installation Status
                if (_installationStatus.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _isInstalling
                            ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                            : (_installationStatus.contains('Successful')
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isInstalling)
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            )
                          else
                            Icon(
                              _installationStatus.contains('Successful')
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              size: 14,
                              color: _installationStatus.contains('Successful')
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _installationStatus,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _isInstalling
                                    ? theme.colorScheme.onSurfaceVariant
                                    : (_installationStatus
                                            .contains('Successful')
                                        ? Colors.green
                                        : Colors.red),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        width: 1,
                      ),
                      color: theme.colorScheme.surface,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Device Info',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red.shade400;
    if (progress < 0.7) return Colors.orange.shade400;
    return Colors.green.shade400;
  }
}
