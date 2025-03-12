import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:warehouse_phase_1/GlobalVariables/singelton_class.dart';
import 'package:warehouse_phase_1/src/helpers/api_services.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';

class DiagnosticForm extends StatefulWidget {
 // final Function(Map<String, dynamic>) savedbreport;
  //final ApiServices apiServices;

  const DiagnosticForm() : super();

  @override
  _DiagnosticFormState createState() => _DiagnosticFormState();
}

class _DiagnosticFormState extends State<DiagnosticForm> {
  // Form controllers
  int _currentPage = 0;
  final PageController _pageController = PageController();
  ApiServices apiServices=ApiServices();
  // Device details controllers
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _androidVersionController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();
  String _mdmStatus = 'Active';
  final TextEditingController _ramController = TextEditingController();
  final TextEditingController _romController = TextEditingController();
  String _oemStatus = 'Active';
  String _simLockStatus = 'locked';
  
  // Page 2: Diagnosis test results
  final Map<String, String> _testResults = {};

  @override
  void initState() {
    super.initState();
    _initializePhysicalQuestions();
    _initializeTestResults();
  }

  void _initializeTestResults() {
    String? testProfile = GlobalUser().testProfile;

    if (testProfile != null) {
      final response = jsonDecode(testProfile);
      final profile = jsonDecode(response['profile']) as List<dynamic>;

      for (var test in profile) {
        _testResults[test] = "-1";
      }
    }
  }
  // Page 3: Physical question answers
  final Map<String, String> _physicalQuestions = {};
  final Map<String, List<String>> _physicalOptions = {};

  // @override
  // void initState() {
  //   super.initState();
  //   _initializePhysicalQuestions();
  // }

  void _initializePhysicalQuestions() {
    String? physicalQuestionsResponse = GlobalUser().physicalQuestionResponse;

    if (physicalQuestionsResponse != null) {
      final response = jsonDecode(physicalQuestionsResponse);
      final questions = response['question'] as List<dynamic>;

      for (var question in questions) {
        final key = question['key'];
        final options = question['options'] as List<dynamic>;
        final optionValues = options.map((option) => option['optionValue'] as String).toList();

        _physicalQuestions[key] = optionValues.first;
        _physicalOptions[key] = optionValues;
      }
    }
  }
  bool _isLoading = false;
  bool _isSuccess = false;
  
  @override
  void dispose() {
    _pageController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _androidVersionController.dispose();
    _imeiController.dispose();
    _serialController.dispose();
    _ramController.dispose();
    _romController.dispose();
    super.dispose();
  }
  
  // Save test results to JSON file
  Future<void> _saveTestResults() async {
    final serialNumber = _serialController.text;
    if (serialNumber.isEmpty) return;

    final testResultsJsonData = _testResults.entries.map((entry) => {entry.key: entry.value}).toList();
    final testResultsJsonString = jsonEncode(testResultsJsonData);

    final physicalQuestionsJsonData = _physicalQuestions;
    final physicalQuestionsJsonString = jsonEncode(physicalQuestionsJsonData);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final testResultsFile = File('logcat_results_$serialNumber.json');
      await testResultsFile.writeAsString(testResultsJsonString);
      print('Saved test results to: ${testResultsFile.path}');

      final physicalQuestionsFile = File('${serialNumber}pq.json');
      await physicalQuestionsFile.writeAsString(physicalQuestionsJsonString);
      print('Saved physical questions to: ${physicalQuestionsFile.path}');
    } catch (e) {
      print('Error saving test results or physical questions: $e');
    }
  }

  // Get device details as map
  Map<String, dynamic> _getDeviceDetails() {
    return {
      'brand': _brandController.text,
      'model': _modelController.text,
      'androidVersion': _androidVersionController.text,
      'imeiNumber': _imeiController.text,
      'serialNumber': _serialController.text,
      'mdmStatus': _mdmStatus,
      'ram': _ramController.text,
      'rom': _romController.text,
      'oem': _oemStatus,
      'simlock': _simLockStatus,
    };
  }

  // Handle form submission
  Future<void> _submitForm() async {
    setState(() => _isLoading = true);

    try {
      // Call API service to save results
      await apiServices.saveResults();
      final result = true;
      setState(() {
        _isLoading = false;
        _isSuccess = result;
      });

      if (result) {
        // Show success message and close after 2 seconds
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form submitted successfully!')),
        );
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop(true);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit form. Please try again.')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void saveDbData() async {
    final deviceData = _getDeviceDetails();

    // Adjust values based on status
    deviceData['mdmStatus'] = deviceData['mdmStatus'] == 'Active' ? 'true' : (deviceData['mdmStatus'] == 'Inactive' ? 'false' : 'N/A');
    deviceData['oem'] = deviceData['oem'] == 'Active' ? '1' : (deviceData['oem'] == 'Inactive' ? '0' : 'N/A');

    // Save to local database
    await SqlHelper.createItem(
      deviceData['brand'] ?? '',
      deviceData['model'] ?? '',
      deviceData['imeiNumber'] ?? '',
      deviceData['serialNumber'] ?? '',
      deviceData['ram'] ?? '',
      deviceData['mdmStatus'] ?? '',
      deviceData['oem'] ?? '',
      deviceData['rom'] ?? '',
      deviceData['simlock'] ?? '',
      deviceData['androidVersion'] ?? '',
      '0',
    );
    List<Map<String, dynamic>> items = await SqlHelper.getItems();
    print('Device data saved to database in manual QC :$items');
  }
  // Handle page navigation
  void _nextPage() async {
    if (_currentPage == 0) {
      // Check if all device details are filled
      if (_brandController.text.isEmpty ||
          _modelController.text.isEmpty ||
          _androidVersionController.text.isEmpty ||
          _imeiController.text.isEmpty ||
          _serialController.text.isEmpty ||
          _ramController.text.isEmpty ||
          _romController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all device details')),
        );
        return;
      }

      // Save device details
      try {
        saveDbData();
        setState(() {
          _currentPage = 1;
          _pageController.animateToPage(
            1,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } else if (_currentPage == 1) {
      // Save test results and move to page 3
      await _saveTestResults();
      setState(() {
        _currentPage = 2;
        _pageController.animateToPage(
          2,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  // Handle test result selection
  void _updateTestResult(String test, String value) {
    setState(() {
      _testResults[test] = value;
    });
  }
  
 @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  return Dialog(
    insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    backgroundColor: Colors.transparent,
    elevation: 0,
    child: Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 15.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Modern curved header
              Container(
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -10,
                      right: -10,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: 20,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Title
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phonelink_setup_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Device Diagnostics',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Page indicator tabs
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    _buildPageTab(0, 'Device', Icons.smartphone_rounded),
                    _buildPageTab(1, 'Tests', Icons.build_circle_rounded),
                    _buildPageTab(2, 'Assessment', Icons.checklist_rounded),
                  ],
                ),
              ),
              
              // Form pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _buildDeviceDetailsPage(),
                    _buildDiagnosisDataPage(),
                    _buildPhysicalQuestionsPage(),
                  ],
                ),
              ),
              
              // Modern gradient footer with nav buttons
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade50, Colors.grey.shade100],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      _buildGradientButton(
                        label: 'Back',
                        icon: Icons.arrow_back_rounded,
                        isOutlined: true,
                        onPressed: () {
                          setState(() {
                            _currentPage--;
                            _pageController.animateToPage(
                              _currentPage,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          });
                        },
                      )
                    else
                      SizedBox(width: 90),
                    
                    _currentPage < 2
                      ? _buildGradientButton(
                          label: 'Next',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: _nextPage,
                        )
                      : _buildGradientButton(
                          label: 'Submit',
                          icon: Icons.check_circle_rounded,
                          onPressed: _isLoading ? null : _submitForm,
                        ),
                  ],
                ),
              ),
            ],
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing...',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
          // Success overlay
          if (_isSuccess)
            Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 60,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Successfully Submitted!',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// Page tab widget
Widget _buildPageTab(int index, String title, IconData icon) {
  final isActive = _currentPage == index;
  return Expanded(
    child: GestureDetector(
      onTap: () {
        setState(() {
          _currentPage = index;
          _pageController.animateToPage(
            index,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
          color: isActive ? Colors.white : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade600,
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade600,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Gradient button
Widget _buildGradientButton({
  required String label,
  required IconData icon,
  required VoidCallback? onPressed,
  bool isOutlined = false,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: isOutlined ? null : LinearGradient(
        colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: isOutlined ? Border.all(color: Theme.of(context).primaryColor, width: 1.5) : null,
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isOutlined ? Theme.of(context).primaryColor : Colors.white,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isOutlined ? Theme.of(context).primaryColor : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// Page 1: Device Details
Widget _buildDeviceDetailsPage() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Basic Information'),
          _buildFloatingTextField(
            controller: _brandController,
            labelText: 'Brand',
            prefixIcon: Icons.phone_android,
          ),
          _buildFloatingTextField(
            controller: _modelController,
            labelText: 'Model',
            prefixIcon: Icons.devices,
          ),
          _buildFloatingTextField(
            controller: _androidVersionController,
            labelText: 'Android Version',
            prefixIcon: Icons.android,
          ),
          _buildFloatingTextField(
            controller: _imeiController,
            labelText: 'IMEI Number',
            prefixIcon: Icons.confirmation_number,
            keyboardType: TextInputType.number,
          ),
          _buildFloatingTextField(
            controller: _serialController,
            labelText: 'Serial Number',
            prefixIcon: Icons.qr_code,
          ),
          SizedBox(height: 20),
          _buildSectionHeader('System Configuration'),
          SizedBox(height: 12),
          _buildRadioCard(
            title: 'MDM Status',
            icon: Icons.security,
            options: ['Active', 'Inactive', 'N/A'],
            groupValue: _mdmStatus,
            onChanged: (value) {
              setState(() => _mdmStatus = value);
            },
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFloatingTextField(
                  controller: _ramController,
                  labelText: 'RAM (GB)',
                  prefixIcon: Icons.memory,
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildFloatingTextField(
                  controller: _romController,
                  labelText: 'ROM (GB)',
                  prefixIcon: Icons.storage,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildRadioCard(
            title: 'OEM Status',
            icon: Icons.phonelink_lock,
            options: ['Active', 'Inactive', 'N/A'],
            groupValue: _oemStatus,
            onChanged: (value) {
              setState(() => _oemStatus = value);
            },
          ),
          SizedBox(height: 12),
          _buildRadioCard(
            title: 'SIM Lock Status',
            icon: Icons.sim_card_outlined,
            options: ['locked', 'unlocked', 'N/A'],
            groupValue: _simLockStatus,
            onChanged: (value) {
              setState(() => _simLockStatus = value);
            },
          ),
        ],
      ),
    ),
  );
}

// Section header widget
Widget _buildSectionHeader(String title) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
      SizedBox(height: 4),
      Container(
        width: 40,
        height: 3,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      SizedBox(height: 16),
    ],
  );
}

// Modern floating label text field
Widget _buildFloatingTextField({
  required TextEditingController controller,
  required String labelText,
  required IconData prefixIcon,
  TextInputType keyboardType = TextInputType.text,
}) {
  return Container(
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade200,
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: 18,
          color: Theme.of(context).primaryColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      style: TextStyle(fontSize: 14),
    ),
  );
}

// Radio card widget
Widget _buildRadioCard({
  required String title,
  required IconData icon,
  required List<String> options,
  required String groupValue,
  required Function(String) onChanged,
}) {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade200,
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: options.map((option) {
            final isSelected = groupValue == option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          )
                        : Icon(
                            Icons.circle_outlined,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                    SizedBox(width: 6),
                    Text(
                      option,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ),
  );
}

// Page 2: Diagnosis Data
Widget _buildDiagnosisDataPage() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Diagnosis Tests'),
        Expanded(
          child: ListView.builder(
            itemCount: _testResults.length,
            itemBuilder: (context, index) {
              final test = _testResults.keys.elementAt(index);
              final value = _testResults[test]!;
              return _buildModernTestItem(test, value);
            },
          ),
        ),
      ],
    ),
  );
}

// Modern test item widget
Widget _buildModernTestItem(String test, String value) {
  IconData getIcon() {
    switch (test) {
      case "WiFi": return Icons.wifi;
      case "Battery": return Icons.battery_full;
      case "Storage": return Icons.storage;
      case "GSM Network": return Icons.network_cell;
      case "Vibrator": return Icons.vibration;
      case "Finger Print": return Icons.fingerprint;
      case "Bluetooth": return Icons.bluetooth;
      case "GPS": return Icons.gps_fixed;
      case "Camera": return Icons.camera_alt;
      case "Autofocus": return Icons.camera;
      case "Earphone Jack": return Icons.headphones;
      case "Auto Rotation": return Icons.screen_rotation;
      case "Proximity": return Icons.sensors;
      case "Dead Pixel": return Icons.visibility;
      case "Touch Screen": return Icons.touch_app;
      case "USB Slot": return Icons.usb;
      case "Torch": return Icons.flashlight_on;
      case "Device Button": return Icons.touch_app;
      case "Top Speakers": return Icons.speaker;
      case "Bottom Speakers": return Icons.speaker_group;
      case "Top Microphone": return Icons.mic;
      case "Bottom Microphone": return Icons.mic_external_on;
      default: return Icons.check_circle_outline;
    }
  }
  
  Color getIconColor() {
    if (value == "1") return Colors.green;
    if (value == "0") return Colors.red;
    return Colors.grey;
  }
  
  return Container(
    margin: EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade200,
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          margin: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: getIconColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(getIcon(), color: getIconColor()),
        ),
        Expanded(
          child: Text(
            test,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.only(right: 10),
          child: Row(
            children: [
              _buildTestButton(
                "1", 
                value, 
                "Pass", 
                Colors.green, 
                test,
              ),
              SizedBox(width: 6),
              _buildTestButton(
                "0", 
                value, 
                "Fail", 
                Colors.red, 
                test,
              ),
              SizedBox(width: 6),
              _buildTestButton(
                "-1", 
                value, 
                "Skip", 
                Colors.grey, 
                test,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Modern test button
Widget _buildTestButton(
  String stateValue, 
  String currentValue, 
  String label, 
  Color color, 
  String test,
) {
  final isSelected = currentValue == stateValue;
  
  return GestureDetector(
    onTap: () => _updateTestResult(test, stateValue),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? color : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : color,
        ),
      ),
    ),
  );
}

// Page 3: Physical Questions
Widget _buildPhysicalQuestionsPage() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Physical Assessment'),
        Expanded(
          child: ListView.builder(
            itemCount: _physicalQuestions.length,
            itemBuilder: (context, index) {
              final question = _physicalQuestions.keys.elementAt(index);
              final value = _physicalQuestions[question]!;
              final options = _physicalOptions[question]!;
              
              return _buildModernPhysicalQuestionItem(question, value, options);
            },
          ),
        ),
      ],
    ),
  );
}

// Modern physical question item widget
Widget _buildModernPhysicalQuestionItem(String question, String value, List<String> options) {
  IconData getIcon() {
    switch (question) {
      case "Display Status": return Icons.smartphone;
      case "Screw Status": return Icons.build;
      case "Back Panel": return Icons.phone_android;
      case "Frame Status": return Icons.crop_din;
      case "Battery Status": return Icons.battery_full;
      case "Restart or Reboot Status": return Icons.refresh;
      default: return Icons.help_outline;
    }
  }
  
  return Container(
    margin: EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade200,
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                getIcon(),
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = value == option;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _physicalQuestions[question] = option;
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ] : [],
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected 
                          ? Colors.white
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}
}

// Empty ApiServices class with blank implementation
// class ApiServices {
//   Future<bool> saveResults({
//     required Map<String, dynamic> deviceDetails,
//     required Map<String, String> testResults,
//     required Map<String, String> physicalAssessment,
//   }) async {
//     // Blank implementation
//     await Future.delayed(Duration(seconds: 1)); // Simulate API call
//     return true; // Return success
//   }
// }