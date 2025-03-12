import 'package:flutter/material.dart';
import 'package:warehouse_phase_1/presentation/pages/view_details.dart';
import 'package:warehouse_phase_1/src/helpers/api_services.dart';
import 'package:warehouse_phase_1/src/helpers/log_cat.dart';
import 'package:warehouse_phase_1/src/helpers/sql_helper.dart';
//import 'package:warehouse_phase_1/services/api_services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';

class DeviceRow extends StatefulWidget {
  final int index;
  final String phone;
  final String imagePath;
  final String? date;
  final Map<String, dynamic> details;
  final Function refreshListCallback;
  final String? userId;
  final bool isSelected;
  final Function(bool) onSelectionChanged;

  const DeviceRow({
    required this.index,
    required this.phone,
    required this.imagePath,
    required this.date,
    required this.details,
    required this.refreshListCallback,
    required this.userId,
    required this.isSelected,
    required this.onSelectionChanged,
    super.key,
  });

  @override
  _DeviceRowState createState() => _DeviceRowState();
}

class _DeviceRowState extends State<DeviceRow> {
  bool _isLoading = false;
  bool _isHistoryExpanded = false;
  late bool _isSelected;
  List<Map<String, dynamic>> _historyItems = [];
  ApiServices apiServices = ApiServices();

  @override
  void initState() {
    super.initState();
    _isSelected = widget.isSelected;
  }

  Future<void> viewHistory(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiServices.viewHistory(widget.details['iemi']);
      if (response['status'] == true && response['msg'] is List) {
        setState(() {
          _historyItems = List<Map<String, dynamic>>.from(response['msg']);
          _isHistoryExpanded = true;
        });
      } else {
        Fluttertoast.showToast(
          msg: "No history found",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to fetch history. Error: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadHardwareChecks(BuildContext context, String deviceId) async {
    final fileName = 'logcat_results_$deviceId.json';
    final file = File(fileName);

    final fileName2 = '${deviceId}pq.json';
    final file2 = File(fileName2);

    try {
      if (await file.exists() && await file2.exists()) {
        final jsonContent = await file.readAsString();
        final jsonContent2 = await file2.readAsString();
        List<Map<String, dynamic>> hardwareChecks =
            List<Map<String, dynamic>>.from(jsonDecode(jsonContent));
        List<Map<String, dynamic>> pqchecks =
            [Map<String, dynamic>.from(jsonDecode(jsonContent2))];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceDetails(
                details: widget.details,
                hardwareChecks: hardwareChecks,
                pqchecks: pqchecks),
          ),
        );
      } else {
        Fluttertoast.showToast(
          msg: "No hardware checks found.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to load hardware checks. Error: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> viewDetails(BuildContext context, String id, String date) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await LogCat.fetchDiagnosisAndUpdateFile(
          id ?? 'n/a', widget.details['serialNumber']);
      widget.details['createdAt'] = date;
      await _loadHardwareChecks(context, widget.details['serialNumber']);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to fetch details. Error: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final ThemeData theme = Theme.of(context);
    final Color darkGrey = theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(left: 70, top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              widget.phone,
              style: TextStyle(fontSize: 13, color: darkGrey),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              item['createdDate'] ?? 'N/A',
              style: TextStyle(fontSize: 13, color: darkGrey),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              widget.details['iemi'] ?? 'N/A',
              style: TextStyle(fontSize: 13, color: darkGrey),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextButton(
              child: const Text('View Details'),
              onPressed: () {
                viewDetails(context, item['id'], item['createdDate']);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color darkGrey = theme.colorScheme.onSurface;
    final Color rowColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surface
        : Colors.white;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(bottom: _isHistoryExpanded ? 0 : 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: rowColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: darkGrey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Checkbox(
                value: _isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    _isSelected = value ?? false;
                  });
                  widget.onSelectionChanged(_isSelected);
                },
              ),
              SizedBox(
                width: 30,
                child: Text(
                  '${widget.index + 1}.',
                  style: TextStyle(
                    fontSize: 14,
                    color: darkGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  widget.imagePath,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  widget.phone,
                  style: TextStyle(fontSize: 14, color: darkGrey),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  widget.date ?? 'N/A',
                  style: TextStyle(fontSize: 14, color: darkGrey),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  widget.details['iemi'] ?? 'N/A',
                  style: TextStyle(fontSize: 14, color: darkGrey),
                ),
              ),
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            child: Text(_isHistoryExpanded
                                ? 'Hide History'
                                : 'View History'),
                            onPressed: () async {
                              if (_isHistoryExpanded) {
                                setState(() {
                                  _isHistoryExpanded = false;
                                });
                              } else {
                                await viewHistory(context);
                              }
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isHistoryExpanded && _historyItems.isNotEmpty)
          Column(
            children: _historyItems.map((item) => _buildHistoryItem(item)).toList(),
          ),
      ],
    );
  }
}