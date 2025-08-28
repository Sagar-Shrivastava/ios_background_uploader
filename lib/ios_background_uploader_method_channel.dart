import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ios_background_uploader_platform_interface.dart';

/// An implementation of [IosBackgroundUploaderPlatform] that uses method channels.
class MethodChannelIosBackgroundUploader extends IosBackgroundUploaderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ios_background_uploader');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
