import 'dart:io';
import 'package:flutter/material.dart';

class IpAddressDialog extends StatefulWidget {
  final String? connectedFullAddress;  // To check if there's already a connected device
 // final String? connectedPort;

  const IpAddressDialog({Key? key, this.connectedFullAddress}) : super(key: key);

  @override
  _IpAddressDialogState createState() => _IpAddressDialogState();
}

class _IpAddressDialogState extends State<IpAddressDialog> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  String _connectionStatus = '';
  String fullAddress='';
  @override
  void initState() {
    super.initState();
    // If a device is already connected, populate the text fields with its IP and port
    if (widget.connectedFullAddress != null ) {
      _ipController.text = widget.connectedFullAddress!;
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.connectedFullAddress == null
          ? const Text('Enter IP Address ')
          : const Text('Connected Device'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ipController,
            decoration: const InputDecoration(labelText: 'IP Address'),
            readOnly: widget.connectedFullAddress != null, // Make it non-editable if connected
          ),
         
          if (_connectionStatus.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _connectionStatus,
                style: const TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Cancel'),
        ),
        if (widget.connectedFullAddress == null) // Show "Connect" button if not connected
          TextButton(
            onPressed: _connectDevice,
            child: const Text('Connect'),
          )
        else // Show "Disconnect" button if already connected
          TextButton(
            onPressed: _disconnectDevice,
            child: const Text('Disconnect'),
          ),
      ],
    );
  }

  // Function to execute the 'adb connect' command
  Future<void> _connectDevice() async {
    String ipAddress = _ipController.text;
    

    if (ipAddress.isEmpty) {
      setState(() {
        _connectionStatus = 'Please enter both IP address and port.';
      });
      return;
    }

     fullAddress = '$ipAddress';
    try {
      ProcessResult result = await Process.run('adb', ['connect', fullAddress]);

      if (result.exitCode == 0) {
        setState(() {
          _connectionStatus = 'Connected successfully to $fullAddress';
          //_ipController=fullAddress;
        });
        Navigator.of(context).pop(fullAddress); // Return the connected IP and port
      } else {
        setState(() {
          _connectionStatus = 'Failed to connect: ${result.stderr}';
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error: $e';
      });
    }
  }

  // Function to execute the 'adb disconnect' command
  Future<void> _disconnectDevice() async {
    //String fullAddress = '${_ipController.text}';

    try {
      ProcessResult result = await Process.run('adb', ['disconnect', fullAddress]);

      if (result.exitCode == 0) {
        setState(() {
          _connectionStatus = 'Disconnected successfully from $fullAddress';
        });
        Navigator.of(context).pop(null); // Return null to clear the connected state
      } else {
        setState(() {
          _connectionStatus = 'Failed to disconnect: ${result.stderr}';
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error: $e';
      });
    }
  }
}
