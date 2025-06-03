import 'package:url_launcher/url_launcher.dart';

class UrlLauncher {
  /// Class to access [UrlLauncher]

  // Launch water usage estimate website
  static Future<void> launchWaterUsageTool() async {
    const String url =
        'https://smartwatermark.org/watercalculator/NSW/#results';
    await _launchUrl(url);
  }

  // Launch water optimisation tips website
  static Future<void> launchOptimisationTips() async {
    const String url = 'https://www.yourhome.gov.au/water/reducing-water-use';
    await _launchUrl(url);
  }

  // Launch a URL
  static Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);

    try {
      if (!await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      )) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      // Final fallback: try with platform default
      if (!await launchUrl(url)) {
        throw 'Could not launch $url';
      }
    }
  }
}
