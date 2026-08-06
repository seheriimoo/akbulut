import 'package:shared_preferences/shared_preferences.dart';

/// Persists SHIP-01 compliance consent on-device.
///
/// Not part of HCOS. Stores only consent flags, not conversation content.
class ConsentStore {
  ConsentStore._();

  static const String _baselineKey = 'nocta_compliance_baseline_v1';
  static const String _llmKey = 'nocta_llm_cloud_consent_v1';
  static const String _disclaimerKey = 'nocta_nonclinical_disclaimer_v1';

  static Future<bool> hasAcceptedBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_baselineKey) == true &&
        prefs.getBool(_llmKey) == true &&
        prefs.getBool(_disclaimerKey) == true;
  }

  static Future<void> acceptBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_baselineKey, true);
    await prefs.setBool(_llmKey, true);
    await prefs.setBool(_disclaimerKey, true);
  }
}
