import 'package:flutter/services.dart';

class IosBackgroundUploader {
  static const MethodChannel _channel = MethodChannel("ios_background_uploader");
  static const EventChannel _eventChannel = EventChannel("ios_background_uploader/events");

  static Stream<Map<String, dynamic>> get uploadEvents {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    });
  }

  static Future<String?> uploadFiles({
    required String url,
    required List<String> files,
    String method = "POST",
    Map<String, String>? headers,
    Map<String, String>? fields,
    String? tag,
  }) async {
    final args = {
      "url": url,
      "files": files,
      "method": method,
      "headers": headers ?? {},
      "fields": fields ?? {},
      "tag": tag ?? DateTime.now().millisecondsSinceEpoch.toString(),
    };
    return await _channel.invokeMethod<String>("uploadFiles", args);
  }
}
