import 'package:flutter/material.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/presentation/DeviceCard/widgets/video_record.dart';
// Import the new VideoRecorderPage
import 'package:camera/camera.dart';

class DeviceProgressSection extends StatefulWidget {
  final double? progress;
  final bool isDevicePresent;
  final VoidCallback onViewDetailsPressed;
  final VoidCallback onResetPressed;
  final Future<void> Function()? onDataWipe;
  final String? manufacturer;
  final String? model;
  final String? imei;
  final String? deviceId;
  const DeviceProgressSection(
      {Key? key,
      required this.progress,
      required this.isDevicePresent,
      required this.onViewDetailsPressed,
      required this.onResetPressed,
      this.onDataWipe,
      required this.manufacturer,
      required this.model,
      required this.imei,
      required this.deviceId})
      : super(key: key);

  @override
  _DeviceProgressSectionState createState() => _DeviceProgressSectionState();
}

class _DeviceProgressSectionState extends State<DeviceProgressSection> {
  //CameraController? _cameraController;
  //Future<void>? _initializeControllerFuture;
  PreferencesHelper pfs = PreferencesHelper();
  bool _isUploaded = false;
  bool _isResultGenerated = false; // Track if result is generated
  bool _ispresent = false;
  @override
  void initState() {
    super.initState();
    // _initializeCamera();
  }

  // Future<void> _initializeCamera() async {
  //   final cameras = await availableCameras();
  //   if (cameras.isNotEmpty) {
  //     _cameraController = CameraController(
  //       cameras.first,
  //       ResolutionPreset.high,
  //     );
  //     _initializeControllerFuture = _cameraController!.initialize();
  //     bool result=await pfs.containsVerdict(widget.deviceId??'n/a');
  //     setState(() {
  //       _ispresent=result;
  //     });
  //     print("mera camera $cameras");
  //   }
  // }
  // void _handleUpload(bool success)
  // {
  //   setState(() {
  //     _isUploaded = success;
  //   });
  // }
  // void _handleGenerateResultComplete(bool success) {
  //   setState(() {
  //     _isResultGenerated = success;
  //   });
  // }
  @override
  void dispose() {
    //_cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return widget.progress! >= 1.0 
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  // Center(
                  //   child: TextButton(
                  //     onPressed: () async {
                  //       if (_initializeControllerFuture != null) {
                  //         await _initializeControllerFuture;
                  //         if (!mounted) return;
                  //         Navigator.of(context).push(
                  //           MaterialPageRoute(
                  //             builder: (context) => VideoRecorderPage(
                  //               cameraController: _cameraController!,
                  //               manufacturer: widget.manufacturer ?? '',
                  //               model: widget.model ?? '',
                  //               imei: widget.imei ?? '',
                  //               deviceId: widget.deviceId ?? '',
                  //                onResultGenerated: _handleGenerateResultComplete, // Pass the callback

                  //             ),
                  //           ),
                  //         );
                  //       } else {
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           const SnackBar(
                  //               content: Text('Camera not available')),
                  //         );
                  //       }
                  //       // String? val=await pfs.getVerdict(widget.deviceId??'n/a');
                  //       // print("crack check mai stored value :$val");
                  //     },
                  //     child: const Text('Start Crack Check'),
                  //   ),
                  // ),
                  //const SizedBox(height: 10),
                  Row(
                    children: [
                      // TextButton(
                      //   onPressed: widget.onViewDetailsPressed,
                      //   child: const Text('View Details'),
                      // ),
                      TextButton(
                        onPressed: () async {
                          bool? confirmDelete = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Confirm Data Wipe'),
                                content: const Text(
                                    'Are you sure you want to delete all files on your phone? This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete == true &&
                              widget.onDataWipe != null) {
                            await widget.onDataWipe!();
                          }
                        },
                        child: const Text('Data Wipe'),
                      ),
                    ],
                  )
                ],
              ),
            ],
          )
        : Column(
            children: [
              LinearProgressIndicator(
                backgroundColor: Colors.grey.shade300,
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                value: widget.progress,
              ),
              Text('${(widget.progress! * 100).toStringAsFixed(2)}% completed'),
              // TextButton(
              //   onPressed: () {
              //     throw Exception();
              //   },
              //   child: const Text("Throw Test Exception"),
              // ),
            ],
          );
  }
}
