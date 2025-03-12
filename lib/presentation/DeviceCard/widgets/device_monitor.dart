import 'package:rxdart/rxdart.dart';

class DeviceMonitor {
  final String deviceId;
  BehaviorSubject<int> progressSubject = BehaviorSubject<int>.seeded(0);
  List<Map<String, dynamic>> testResults = [];

  DeviceMonitor(this.deviceId);

  Stream<int> get progressStream => progressSubject.stream;

  void updateProgress(int value) {
    progressSubject.add(value);
  }

  void addTestResult(Map<String, dynamic> result) {
    testResults.add(result);
    updateProgress(testResults.length * 5); // Assuming 5% per result
  }

  void resetProgress() {
    progressSubject.add(0);
    testResults.clear();
  }

  void dispose() {
    progressSubject.close();
  }
}
