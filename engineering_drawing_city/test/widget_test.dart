import 'package:flutter_test/flutter_test.dart';
import 'package:engineering_drawing_city/models/app_settings_model.dart';

void main() {
  test('legacy dollar subscription price migrates to K50', () {
    final settings = AppSettingsModel.fromMap({
      'subscriptionPrice': 10.0,
    });

    expect(settings.subscriptionPrice, 50.0);
  });

  test('new settings default to K50 and do not invent support contacts', () {
    final settings = AppSettingsModel.fromMap({});

    expect(settings.subscriptionPrice, 50.0);
    expect(
      settings.contactInformation,
      'Official support contact details pending confirmation.',
    );
  });
}
