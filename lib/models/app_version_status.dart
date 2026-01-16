class AppVersionStatus {
  final String currentVersion;
  final String minRequiredVersion;
  final String latestVersion;
  final String? apkUrl;

  AppVersionStatus({
    required this.currentVersion,
    required this.minRequiredVersion,
    required this.latestVersion,
    required this.apkUrl,
  });

  bool get mustUpdate => _compare(currentVersion, minRequiredVersion) < 0;
  bool get shouldUpdate => _compare(currentVersion, latestVersion) < 0;

  static int _compare(String a, String b) {
    final av = a.split('.').map(int.parse).toList();
    final bv = b.split('.').map(int.parse).toList();
    for (var i = 0; i < 3; i++) {
      if (av[i] != bv[i]) return av[i].compareTo(bv[i]);
    }
    return 0;
  }

  factory AppVersionStatus.fromJson(String currentVersion, Map<String, dynamic> json) {
    return AppVersionStatus(
      currentVersion: currentVersion,
      minRequiredVersion: json['min_required_version'],
      latestVersion: json['latest_version'],
      apkUrl: json['apk_url'],
    );
  }
}
