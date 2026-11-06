class AppSettingsModel {
  final String appName;
  final String logo;
  final String welcomeMessage;
  final double subscriptionPrice;
  final String subscriptionDuration;
  final String paymentInstructions;
  final bool aiEnabled;
  final String contactInformation;
  final bool maintenanceMode;

  AppSettingsModel({
    required this.appName,
    required this.logo,
    required this.welcomeMessage,
    required this.subscriptionPrice,
    required this.subscriptionDuration,
    required this.paymentInstructions,
    required this.aiEnabled,
    required this.contactInformation,
    required this.maintenanceMode,
  });

  factory AppSettingsModel.fromMap(Map<String, dynamic> data) {
    return AppSettingsModel(
      appName: data['appName'] ?? 'Engineering Drawing City',
      logo: data['logo'] ?? '',
      welcomeMessage: data['welcomeMessage'] ?? 'Welcome to Engineering Drawing City',
      subscriptionPrice: ((data['subscriptionPrice'] ?? 50.0).toDouble() == 10.0 ? 50.0 : (data['subscriptionPrice'] ?? 50.0).toDouble()),
      subscriptionDuration: data['subscriptionDuration'] ?? '30 days',
      paymentInstructions: data['paymentInstructions'] ?? '',
      aiEnabled: data['aiEnabled'] ?? true,
      contactInformation: data['contactInformation'] == 'support@drawingcity.com | Phone: +260 772 184445'
          ? 'Official support contact details pending confirmation.'
          : (data['contactInformation'] ?? 'Official support contact details pending confirmation.'),
      maintenanceMode: data['maintenanceMode'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'logo': logo,
      'welcomeMessage': welcomeMessage,
      'subscriptionPrice': subscriptionPrice,
      'subscriptionDuration': subscriptionDuration,
      'paymentInstructions': paymentInstructions,
      'aiEnabled': aiEnabled,
      'contactInformation': contactInformation,
      'maintenanceMode': maintenanceMode,
    };
  }
}