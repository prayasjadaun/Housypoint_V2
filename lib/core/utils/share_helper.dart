import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Copy / system share sheet in one place.
class ShareHelper {
  ShareHelper._();

  static Future<void> copy(String text) => Clipboard.setData(ClipboardData(text: text));

  static Future<void> share(String text, {String? subject}) =>
      SharePlus.instance.share(ShareParams(text: text, subject: subject));
}
