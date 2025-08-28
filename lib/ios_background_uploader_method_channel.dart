import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ios_background_uploader_platform_interface.dart';

class MethodChannelIosBackgroundUploader extends IosBackgroundUploaderPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('ios_background_uploader');
  final eventChannel = const EventChannel('ios_background_uploader/events');

  @override
  Future<void> uploadFiles({
    required String url,
    required List<String> files,
    Map<String, String>? headers,
    Map<String, String>? fields,
    String? tag,
  }) async {
    final args = {
      'url': url,
      'files': files,
      'headers': headers ?? {},
      'fields': fields ?? {},
      'tag': tag ?? '',
    };
    await methodChannel.invokeMethod('uploadFiles', args);
  }

  @override
  Stream<Map<String, dynamic>> get uploadEvents {
    return eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event);
    });
  }
}
