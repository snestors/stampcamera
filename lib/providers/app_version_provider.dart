import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_version_status.dart';
import '../services/http_service.dart';

final appVersionProvider = FutureProvider<AppVersionStatus>((ref) async {
  final http = HttpService();
  final info = await PackageInfo.fromPlatform();
  final currentVersion = info.version;

  final response = await http.dio.get(
    '/api/v1/app/version/?plataforma=android',
  );

  return AppVersionStatus.fromJson(currentVersion, response.data);
});
