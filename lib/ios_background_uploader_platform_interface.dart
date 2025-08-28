import 'package:ios_background_uploader/ios_background_uploader_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class IosBackgroundUploaderPlatform extends PlatformInterface {
  IosBackgroundUploaderPlatform() : super(token: _token);

  static final Object _token = Object();

  static IosBackgroundUploaderPlatform _instance = MethodChannelIosBackgroundUploader();

  static IosBackgroundUploaderPlatform get instance => _instance;

  static set instance(IosBackgroundUploaderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> uploadFiles({
    required String url,
    required List<String> files,
    Map<String, String>? headers,
    Map<String, String>? fields,
    String? tag,
  }) {
    throw UnimplementedError('uploadFiles() has not been implemented.');
  }

  Stream<Map<String, dynamic>> get uploadEvents {
    throw UnimplementedError('uploadEvents has not been implemented.');
  }
}
