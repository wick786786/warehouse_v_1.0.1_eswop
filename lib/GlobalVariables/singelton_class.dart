class GlobalUser {
  static final GlobalUser _instance = GlobalUser._internal();

  String? userId;
  String? physicalQuestionResponse;
  String? testProfile;
  int? profileLength; // Added variable
  int? progressLength;
  factory GlobalUser() {
    return _instance;
  }

  GlobalUser._internal();
}
