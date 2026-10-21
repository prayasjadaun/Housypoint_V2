import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Device fields the login API expects (`device_id`, `device_name`, `device_type`).
class DeviceDetails {
  const DeviceDetails({required this.id, required this.name, required this.type});

  final String id;
  final String name;
  final String type;

  static DeviceDetails? _cached;

  static Future<DeviceDetails> load() async {
    if (_cached != null) return _cached!;
    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return _cached = DeviceDetails(
          id: info.id,
          name: '${info.manufacturer} ${info.model}',
          type: 'Android ${info.version.release}',
        );
      }
      final info = await plugin.iosInfo;
      return _cached = DeviceDetails(
        id: info.identifierForVendor ?? 'unknown',
        name: info.name,
        type: 'iOS ${info.systemVersion}',
      );
    } catch (_) {
      return const DeviceDetails(id: 'unknown', name: 'Mobile', type: 'unknown');
    }
  }
}
