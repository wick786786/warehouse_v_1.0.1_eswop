import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:warehouse_phase_1/presentation/DeviceCard/model/sharedpref.dart';
import 'package:warehouse_phase_1/presentation/pages/DeviceListPage/widgets/device_row.dart';
import 'package:warehouse_phase_1/service_class/current_internet_status.dart';
import 'package:warehouse_phase_1/src/helpers/api_services.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';


class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  _DeviceListPageState createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  List<Map<String, dynamic>> displayedDevices = [];
  String? userId = "";
  bool isLoading = true;
  bool sortOrder = true; // true = descending, false = ascending
  int currentPage = 1;
  final int itemsPerPage = 8;
  bool hasNextPage = true;
  bool hasInternet = true;
  String? errorMessage;
  InternetStatusChecker internetStatus = InternetStatusChecker();
  TextEditingController searchController = TextEditingController();
  Set<int> selectedDevices = {};
  int diagnosisCount = 0;
  bool isLoadingCount = true;
  ApiServices apiServices = ApiServices();
  DateTime? fromDate;
  DateTime? toDate;
  String? reportUrl;
  bool isGeneratingReport = false;
  @override
  void initState() {
    super.initState();
    checkInternetAndRefresh();
    fetchDiagnosisCount();
    //refreshList();
  }

  Future<void> fetchDiagnosisCount() async {
    try {
      final count = await apiServices.fetchCount();
      print('count in the result :$count');
      setState(() {
        diagnosisCount = count;
        isLoadingCount = false;
      });
    } catch (e) {
      print('Error fetching diagnosis count: $e');
      setState(() {
        diagnosisCount = 0;
        isLoadingCount = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  Future<void> checkInternetAndRefresh() async {
    bool isConnected = await internetStatus.checkInternetStatus();
    setState(() {
      hasInternet = isConnected;
    });
    if (hasInternet) {
      refreshList();
    }
  }

  // Add function to handle report generation
  void _showLinkDialog(BuildContext context, String url) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Report Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //const Text('Your report has been generated. Click the link below to view:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    url,
                    style: const TextStyle(
                      color: Colors.blue,
                     // decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied to clipboard')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    _downloadFile(context, url);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

Future<void> _downloadFile(BuildContext context, String url) async {
  try {
    Dio dio = Dio();
    Directory? downloadsDir = await getDownloadsDirectory();

    if (downloadsDir == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to find downloads directory")),
        );
      }
      return;
    }

    String savePath = "${downloadsDir.path}/report.xlsx";

    await dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          debugPrint("Download Progress: ${(received / total * 100).toStringAsFixed(0)}%");
        }
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File downloaded successfully: $savePath")),
      );
      OpenFilex.open(savePath);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }
}

  // Modify the _generateReport function
  Future<void> _generateReport() async {
    setState(() {
      isGeneratingReport = true;
    });

    try {
      if (fromDate != null && toDate != null) {
        // Date-based download
        final startDate =
            "${fromDate!.year}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}";
        final endDate =
            "${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}";

        final result = await apiServices.downloadReport(
          userId ?? "",
          "date",
          startDate,
          endDate,
          [],
        );
        print('result in date based download :$result');

        if (result.startsWith('http')) {
          _showLinkDialog(context, result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result)),
          );
        }
      } else if (selectedDevices.isNotEmpty) {
        // ID-based download
        final result = await apiServices.downloadReport(
          userId ?? "",
          "ids",
          "",
          "",
          selectedDevices.map((id) => id.toString()).toList(),
        );

        if (result.startsWith('http')) {
          _showLinkDialog(context, result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result)),
          );
        }
      } else {
        // Show error if no date range or devices selected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please select a date range or devices to generate report'),
          ),
        );
      }
    } finally {
      setState(() {
        isGeneratingReport = false;
      });
    }
  }

  Future<bool> checkNextPageHasData(
      String? userId, int nextPage, int limit) async {
    final url = Uri.parse(
        'https://getinstacash.in/warehouse/v1/public/getDData');
    final headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    final body = {
      'userName': 'whtest',
      'apiKey': '202cb962ac59075b964b07152d234b70',
      'userId': userId,
      'page': nextPage.toString(),
      'limit': limit.toString(),
    };

    try {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data['status'] == true;
      }
      return false;
    } catch (e) {
      print('Error checking next page: $e');
      return false;
    }
  }

  Future<void> fetchData(String? userId, int page, int limit) async {
    final url = Uri.parse(
        'https://getinstacash.in/warehouse/v1/public/getDData');
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final body = {
      'userName': 'whtest',
      'apiKey': '202cb962ac59075b964b07152d234b70',
      'userId': userId,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    try {
      // Setting a timeout for the HTTP POST request
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        // This block executes if the request times out
        throw TimeoutException("Post request timed out");
      });

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("response to pagination : $data");
        if (data['status'] == false) {
          print('No data present');
        }
        if (data['status'] == true) {
          print('data in details page : ${data}');
          final List<dynamic> devices = data['msg'];

          List<Map<String, dynamic>> fetchedDevices = [];
          for (var device in devices) {
            fetchedDevices.add({
              'manufacturer': device['brand'],
              'model': device['model'],
              'iemi': device['IMEINumber'],
              'serialNumber': device['serialNumber'],
              'ram': device['ram'],
              'mdmStatus': device['mdmStatus'],
              'oem': device['oem'],
              'rom': device['rom'],
              'simLock': device['simLock'],
              'androidVersion': device['androidVersion'],
              'createdAt': device['createdDate'],
              'id': device['id'],
            });
            await SqlHelper.createItem(
              device['brand'],
              device['model'],
              device['IMEINumber'],
              device['serialNumber'],
              device['ram'],
              device['mdmStatus'],
              device['oem'],
              device['rom'],
              device['simLock'],
              device['androidVersion'],
              "1",
            );
          }
          int number = await SqlHelper.getTotalItems();
          print("number in database $number");
          setState(() {
            displayedDevices = fetchedDevices;
            print("displayed devices $displayedDevices");
            hasNextPage = fetchedDevices.length == limit;
          });
          // Check if next page has data
          bool nextPageHasData =
              await checkNextPageHasData(userId, page + 1, limit);

          setState(() {
            displayedDevices = fetchedDevices;
            hasNextPage = nextPageHasData; // Set based on next page check
          });
        }
      } else {
        throw Exception('Failed to load data');
      }
    } on TimeoutException catch (_) {
      print("Post request failed due to timeout.");
      // Display error message for timeout
      if (mounted) {
        setState(() {
          errorMessage = "Post request failed due to timeout.";
        });
      }
    } catch (e) {
      print('Error: $e');
      // Display a general error message
      if (mounted) {
        setState(() {
          errorMessage = "Failed to fetch data: $e";
        });
      }
    }
  }

  void refreshList() async {
    setState(() => isLoading = true);
    userId = await PreferencesHelper.getUserId();
    await fetchData(userId, currentPage, itemsPerPage);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      // If the search query is empty, reset to the original list (fetched data)
      refreshList();
    } else {
      setState(() {
        // Filter the displayedDevices based on the query
        displayedDevices = displayedDevices.where((device) {
          // Check if any device attribute matches the query
          return device['manufacturer']
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              device['model'].toLowerCase().contains(query.toLowerCase()) ||
              device['iemi'].toLowerCase().contains(query.toLowerCase()) ||
              device['serialNumber']
                  .toLowerCase()
                  .contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  void sortByDate() async {
    setState(() => isLoading = true);
    sortOrder = !sortOrder;
    // You might need to add a sort parameter to your API call
    await fetchData(userId, currentPage, itemsPerPage);
    setState(() => isLoading = false);
  }

  void goToNextPage() async {
    if (hasNextPage) {
      setState(() => isLoading = true);
      currentPage++;
      await fetchData(userId, currentPage, itemsPerPage);
      // Check if there are devices on the new page
      if (displayedDevices.isEmpty) {
        setState(() {
          hasNextPage =
              false; // No devices on next page, disable further navigation
          currentPage--; // Revert to previous page
        });
      }
      setState(() => isLoading = false);
    }
  }

  void goToPreviousPage() async {
    if (currentPage > 1) {
      setState(() => isLoading = true);
      currentPage--;
      await fetchData(userId, currentPage, itemsPerPage);
      // Ensure there's no issue with navigating to previous pages
      setState(() => isLoading = false);
    }
  }

  void onSelectionChanged(int id, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedDevices.add(id);
        print("selected devices $selectedDevices");
      } else {
        selectedDevices.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primaryColor = theme.colorScheme.primary;

    if (!hasInternet) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.signal_wifi_off,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please connect to the internet to view the list',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: checkInternetAndRefresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Check if there is an error to display it
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error', style: theme.textTheme.titleLarge),
          backgroundColor: primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Retry logic, clear the error and fetch data again
                  setState(() {
                    errorMessage = null;
                    isLoading = true;
                  });
                  fetchData(userId, currentPage, itemsPerPage);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'List of diagnosed Devices',
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(width: 120),
            // Add date selection buttons
            TextButton(
              onPressed: () => _selectDate(context, true),
              child: Text(
                fromDate == null
                    ? 'From Date'
                    : '${fromDate!.year}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => _selectDate(context, false),
              child: Text(
                toDate == null
                    ? 'To Date'
                    : '${toDate!.year}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            if (isGeneratingReport)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              ElevatedButton(
                onPressed: _generateReport,
                child: const Text('Generate Report'),
              ),
          ],
        ),
        backgroundColor: primaryColor,
        actions: [
          if (!isLoading)
            Container(
              width: 200,
              height: 40,
              margin: const EdgeInsets.only(right: 16),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search by IMEI',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  suffixIcon: Icon(Icons.search, color: primaryColor),
                ),
                onChanged: filterSearchResults,
              ),
            ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          'No.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Phone',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Date',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'IMEI',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Text(
                              'Action',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 25),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.analytics_outlined,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  if (isLoadingCount)
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: theme.colorScheme.primary,
                                      ),
                                    )
                                  else
                                    Text(
                                      '$diagnosisCount Diagnoses',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Row(
                  //   children: [
                  //     Checkbox(
                  //       value:
                  //           selectedDevices.length == displayedDevices.length,
                  //       onChanged: (bool? value) {
                  //         setState(() {
                  //           if (value == true) {
                  //             selectedDevices = displayedDevices
                  //                 .map((device) => int.parse(device['id']))
                  //                 .toSet();
                  //           } else {
                  //             selectedDevices.clear();
                  //           }
                  //         });
                  //         print("Selected devices: $selectedDevices");
                  //       },
                  //     ),
                  //     const Text('Select All'),
                  //   ],
                  // ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: displayedDevices.length,
                      itemBuilder: (context, index) {
                        final device = displayedDevices[index];
                        return DeviceRow(
                          index: index + (currentPage - 1) * itemsPerPage,
                          phone: "${device['manufacturer']} ${device['model']}",
                          imagePath: 'assets/device2.jpg',
                          date: device["createdAt"],
                          details: device,
                          refreshListCallback: refreshList,
                          userId: userId,
                          isSelected: selectedDevices.contains(device['id']),
                          onSelectionChanged: (isSelected) =>
                              onSelectionChanged(
                                  int.parse(device['id']), isSelected),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: currentPage > 1 ? goToPreviousPage : null,
                        child: const Text('Previous Page'),
                      ),
                      Text('Page $currentPage'),
                      ElevatedButton(
                        onPressed: hasNextPage ? goToNextPage : null,
                        child: const Text('Next Page'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
              child: Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 48,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        Text(
                          'Please wait while we load the data...',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
