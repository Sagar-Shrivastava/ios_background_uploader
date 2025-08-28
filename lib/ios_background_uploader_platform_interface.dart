import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ios_background_uploader_method_channel.dart';

abstract class IosBackgroundUploaderPlatform extends PlatformInterface {
  /// Constructs a IosBackgroundUploaderPlatform.
  IosBackgroundUploaderPlatform() : super(token: _token);

  static final Object _token = Object();

  static IosBackgroundUploaderPlatform _instance = MethodChannelIosBackgroundUploader();

  /// The default instance of [IosBackgroundUploaderPlatform] to use.
  ///
  /// Defaults to [MethodChannelIosBackgroundUploader].
  static IosBackgroundUploaderPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IosBackgroundUploaderPlatform] when
  /// they register themselves.
  static set instance(IosBackgroundUploaderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
