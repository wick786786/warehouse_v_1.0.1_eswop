import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:process_run/shell.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Add this import
import 'package:connectivity_plus/connectivity_plus.dart';

class HttpRequests{
// Function to check if there is an internet connection
Future<bool> isConnected() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

// Function to perform a GET request
Future<List<dynamic>> fetchData(String url) async {
  if (await isConnected()) {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  } else {
    throw Exception('No internet connection');
  }
}

// Function to perform a POST request
Future<http.Response> post(String url, String key, String value, String data) async {
  if (await isConnected()) {
    return http.post(
      Uri.parse(url),
      headers: <String, String>{
        key: value,
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'title': data,
      }),
    );
  } else {
    throw Exception('No internet connection');
  }
}
 // post by parts 
 Future<void> postVideo() async
  {
    //replace with cloud url or desktop/ warehouse/ iemi/videos
    
     final videoFolderPath = Directory(r'D:\flutter_project\demo_app\videos');

  if (!videoFolderPath.existsSync()) {
    throw Exception('Video folder does not exist.');
  }

  final videoFiles = videoFolderPath.listSync().where((file) {
    final extname = path.extension(file.path).toLowerCase();
    return extname == '.mp4' || extname == '.avi' || extname == '.mov';
  }).toList();

  if (videoFiles.isEmpty) {
    throw Exception('No video files found in the folder.');
  }

  final filePath = videoFiles.first.path;
  print('file path: $filePath');
  final filename = path.basename(filePath);

  try {
    const url = 'https://crackapi.getinstacash.in/video-crack/upload';
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['Authorization'] =
        'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTY3ODQ0NDcxNywianRpIjoiYmRmMTFmZjgtMjIzMS00ODE3LTlhMjItMDkxOWNjNGVhZGI4IiwidHlwZSI6ImFjY2VzcyIsInN1YiI6InByYXRlZWtnb2VsIiwibmJmIjoxNjc4NDQ0NzE3LCJleHAiOjE3NDE1MTY3MTd9.ZOuYfpVwYZZ_jxnwzppNOfnWznpHQiOVsD8u5i1zoIM'; // Your token here

    // Determine the MIME type based on file extension
    String ext = path.extension(filePath).toLowerCase().substring(1);
    String mimeType;
    switch (ext) {
      case 'mp4':
        mimeType = 'video/mp4';
        break;
      case 'avi':
        mimeType = 'video/x-msvideo';
        break;
      case 'mov':
        mimeType = 'video/quicktime';
        break;
      default:
        mimeType = 'application/octet-stream';
    }

    // Add the file with the appropriate content type
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      filePath,
      contentType: MediaType.parse(mimeType),
    ));

    print(request.headers);
    print(request.files);

    final response = await request.send();
    final streamResponse = await http.Response.fromStream(response);
    if (streamResponse.statusCode == 200) {
      print('Upload Success');
      // Add your deleteVideo(filename) function here if needed
      print('Video uploaded successfully!');
    } else {
      print("post request response: ${streamResponse.body}");
      throw Exception('Failed to upload video.');
    }
  } catch (e) {
    print('Error uploading video: $e');
    throw Exception('Failed to upload video.');
  }

  
}

Future<void> getImage() async {
    // Define your URL
    const String url = 'https://getinstacash.in/instaCash/api/v5/public/getProductIdCurrentDevice';

    // Create the body of the POST request
    final Map<String, String> body = {
      'userName': 'yourUserName',
      'apiKey': 'yourApiKey',
      'deviceBrand': 'yourDeviceBrand',
      'modelBrand': 'yourModelBrand',
      'device': 'yourDevice',
      'model': 'yourModel',
      'memory': 'yourMemory',
      'ram': 'yourRam',
      'deviceType': 'yourDeviceType',
    };

    try {
      // Make the POST request
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: body,
      );

      // Check if the request was successful
      if (response.statusCode == 200) {
        // Parse the JSON response
        final jsonData = json.decode(response.body);
        print('Response data: $jsonData');
      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
}

 
}