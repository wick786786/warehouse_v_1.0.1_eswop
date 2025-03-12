// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
// import 'package:path/path.dart' as path;
// import 'dart:convert';

// import 'package:process_run/shell.dart';
// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
// import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';
// import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart'; // Add this import

// class VideoRecorderPage extends StatefulWidget {
//   final CameraController cameraController;
//   final String manufacturer;
//   final String model;
//   final String imei;
//   final String deviceId;
//     final void Function(bool) onResultGenerated; // Update the callback type
//   const VideoRecorderPage({
//     Key? key,
//     required this.cameraController,
//     required this.manufacturer,
//     required this.model,
//     required this.imei,
//     required this.deviceId,
//     required this.onResultGenerated,
//   }) : super(key: key);

//   @override
//   _VideoRecorderPageState createState() => _VideoRecorderPageState();
// }

// class _VideoRecorderPageState extends State<VideoRecorderPage>
//     with SingleTickerProviderStateMixin {
//   bool _isRecording = false;
//   XFile? _videoFile;
//   bool _isUploading = false;
//   bool _uploadSuccess = false;
//   String? _apiResponse;
//   bool _isGeneratingResult = false;

//   late AnimationController _controller;
//   late Animation<double> _animation;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 1),
//     )..repeat(reverse: true);

//     _animation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeInOut,
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   Future<void> _startRecording() async {
//     await _launchActivity();
//     if (!widget.cameraController.value.isRecordingVideo) {
//       try {
//         await widget.cameraController.startVideoRecording();
//         setState(() {
//           _isRecording = true;
//         });
//       } catch (e) {
//         print('Error starting video recording: $e');
//       }
//     }
//   }

//   Future<void> _launchActivity() async {
//     try {
//       final String packageName = 'com.getinstacash.warehouse';
//       final String activityName = '.ui.activity.CrackCheckActivity';
//       final command = 'adb shell am start -n $packageName/$activityName';
//       await Process.run('cmd', ['/c', command]);
//       print('Activity launched: $activityName');
//     } catch (e) {
//       print('Error launching activity: $e');
//     }
//   }

//   Future<void> _stopRecording() async {
//     if (widget.cameraController.value.isRecordingVideo) {
//       try {
//         final video = await widget.cameraController.stopVideoRecording();
//         setState(() {
//           _isRecording = false;
//           _videoFile = video;
//         });
//       } catch (e) {
//         print('Error stopping video recording: $e');
//       }
//     }
//   }

//   Future<void> _uploadVideo() async {
//     setState(() {
//       _isUploading = true;
//     });

//     final success = await _uploadVideoToServer(_videoFile!.path);
//     setState(() {
//       _isUploading = false;
//       _uploadSuccess = success;
//     });
//   }

//   Future<bool> _uploadVideoToServer(String videoPath) async {
//     final ext = path.extension(videoPath).toLowerCase();
//     final newFilename = '${widget.imei}$ext';

//     try {
//       const url = 'https://crackapi.getinstacash.in/video-crack/upload';
//       final request = http.MultipartRequest('POST', Uri.parse(url));
//       request.headers['Authorization'] =
//           'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTY3ODQ0NDcxNywianRpIjoiYmRmMTFmZjgtMjIzMS00ODE3LTlhMjItMDkxOWNjNGVhZGI4IiwidHlwZSI6ImFjY2VzcyIsInN1YiI6InByYXRlZWtnb2VsIiwibmJmIjoxNjc4NDQ0NzE3LCJleHAiOjE3NDE1MTY3MTd9.ZOuYfpVwYZZ_jxnwzppNOfnWznpHQiOVsD8u5i1zoIM'; // Your token here

//       request.files.add(await http.MultipartFile.fromPath(
//         'file',
//         videoPath,
//         filename: newFilename,
//         contentType: MediaType.parse('video/${ext.substring(1)}'),
//       ));

//       final response = await request.send();
//       final streamResponse = await http.Response.fromStream(response);
//       if (streamResponse.statusCode == 200) {
//         return true;
//       } else {
//         print("post request response: ${streamResponse.body}");
//         return false;
//       }
//     } catch (e) {
//       print('Error uploading video: $e');
//       return false;
//     }
//   }

//   Future<void> _fetchResult() async {
//     setState(() {
//       _isGeneratingResult = true;
//     });
//     PreferencesHelper prefsHelper = PreferencesHelper();
//     try {
//       final response = await http.get(
//         Uri.parse(
//             'https://crackapi.getinstacash.in/video-crack/test/${widget.imei}.mp4'),
//         headers: {
//           'Authorization':
//               'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTY3ODQ0NDcxNywianRpIjoiYmRmMTFmZjgtMjIzMS00ODE3LTlhMjItMDkxOWNjNGVhZGI4IiwidHlwZSI6ImFjY2VzcyIsInN1YiI6InByYXRlZWtnb2VsIiwibmJmIjoxNjc4NDQ0NzE3LCJleHAiOjE3NDE1MTY3MTd9.ZOuYfpVwYZZ_jxnwzppNOfnWznpHQiOVsD8u5i1zoIM',
//         },
//       );

//       if (response.statusCode == 200) {
//         final decodedResponse = jsonDecode(response.body);
//          // Save the Verdict in SharedPreferences
//          // String verdict = decodedResponse['Verdict'] ?? 'No verdict found';
//          //await prefsHelper.saveVerdict(widget.deviceId, verdict);
//          widget.onResultGenerated(true);
//         setState(() {
//           _apiResponse = verdict;

//         });
//       } else {
//         setState(() {
//           _apiResponse = 'Error: ${response.statusCode}';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _apiResponse = 'Error fetching result: $e';
//       });
//     } finally {
//       setState(() {
//         _isGeneratingResult = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
  
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Crack Check',
//           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.teal,
//         elevation: 4.0,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.0)),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               // Camera Preview and Device Info Row
//               Row(
//                 children: [
//                   // Camera Preview Section
//                   Expanded(
//                     flex: 2,
//                     child: Card(
//                       elevation: 6.0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16.0),
//                       ),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(16.0),
//                         child: Stack(
//                           children: [
//                             CameraPreview(widget.cameraController),
//                             if (_isRecording)
//                               Positioned(
//                                 top: 16,
//                                 right: 16,
//                                 child: Container(
//                                   padding: const EdgeInsets.all(8.0),
//                                   decoration: BoxDecoration(
//                                     color: Colors.redAccent,
//                                     borderRadius: BorderRadius.circular(8.0),
//                                   ),
//                                   child: const Text(
//                                     'REC',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(
//                       width: 16), // Spacing between Camera and Device Info
//                   // Device Info Section
//                   Expanded(
//                     flex: 1,
//                     child: Card(
//                       elevation: 6.0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16.0),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Device Info',
//                               style: TextStyle(
//                                   fontSize: 18, fontWeight: FontWeight.bold),
//                             ),
//                             const Divider(thickness: 1.5),
//                             _buildInfoRow('Manufacturer', widget.manufacturer),
//                             _buildInfoRow('Model', widget.model),
//                             _buildInfoRow('IMEI', widget.imei),
//                             const SizedBox(height: 16),
//                             if (_apiResponse != null)
//                               _buildInfoRow('Result', _apiResponse!),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               // Buttons and Recording/Upload Status
//               Column(
//                 children: [
//                   if (_isRecording)
//                     FadeTransition(
//                       opacity: _animation,
//                       child: const Text(
//                         'Recording...',
//                         style: TextStyle(
//                           color: Colors.redAccent,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ),
//                   const SizedBox(height: 10),
//                   if (!_isRecording && _videoFile != null)
//                     _buildActionButtons(),
//                   if (_isUploading)
//                     Column(
//                       children: const [
//                         CircularProgressIndicator(),
//                         SizedBox(height: 8),
//                         Text('Uploading video...'),
//                       ],
//                     ),
//                   // if (_uploadSuccess)
//                   //   ElevatedButton.icon(
//                   //     onPressed: _fetchResult,
//                   //     icon: const Icon(Icons.check_circle_outline),
//                   //     label: const Text('Generate Result'),
//                   //     style: ElevatedButton.styleFrom(
//                   //       padding: const EdgeInsets.symmetric(
//                   //           horizontal: 24, vertical: 16),
//                   //       shape: RoundedRectangleBorder(
//                   //         borderRadius: BorderRadius.circular(12),
//                   //       ),
//                   //       backgroundColor: Colors.green,
//                   //       elevation: 4.0,
//                   //     ),
//                   //   ),
//                   if (_isGeneratingResult)
//                     Column(
//                       children: const [
//                         CircularProgressIndicator(),
//                         SizedBox(height: 8),
//                         Text('Generating result...'),
//                       ],
//                     ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _isRecording ? _stopRecording : _startRecording,
//         label: Text(_isRecording ? 'Stop' : 'Record'),
//         icon: Icon(_isRecording ? Icons.stop : Icons.videocam),
//         backgroundColor: _isRecording ? Colors.redAccent : Colors.teal,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16.0),
//         ),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             '$label:',
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//           ),
//           const SizedBox(height: 4), // Adding space between label and value
//           Text(
//             value,
//             style: const TextStyle(fontSize: 16),
//             softWrap: true, // Allowing text to wrap to the next line
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         ElevatedButton.icon(
//           onPressed: _uploadVideo,
//           icon: const Icon(Icons.cloud_upload),
//           label: const Text('Upload Video'),
//           style: ElevatedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             backgroundColor: Colors.teal,
//             elevation: 4.0,
//           ),
//         ),
//         const SizedBox(width: 16), // Add spacing between buttons
//         if (_uploadSuccess)
//           ElevatedButton.icon(
//             onPressed: _fetchResult,
//             icon: const Icon(Icons.check_circle_outline),
//             label: const Text('Generate Result'),
//             style: ElevatedButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               backgroundColor: Colors.green,
//               elevation: 4.0,
//             ),
//           ),
//       ],
//     );
//   }
// }
