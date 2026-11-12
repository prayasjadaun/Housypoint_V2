import 'package:url_launcher/url_launcher.dart';

/// Opens links outside the app (browser, maps, phone, WhatsApp, PDFs).
class Launcher {
  Launcher._();

  static Future<bool> url(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> call(String phone) => url('tel:$phone');

  /// [phone] with country code, digits only (e.g. 919876543210).
  static Future<bool> whatsApp(String phone, {String message = ''}) =>
      url('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
}
