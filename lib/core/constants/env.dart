class Env {
  /// Base URL REST API.
  /// Default mengarah ke server produksi (VPS). Aplikasi terhubung ke
  /// database lewat REST API ini (Next.js + PostgreSQL).
  ///
  /// Override saat build/run, contoh:
  ///   - Produksi (VPS)        : (default) http://43.133.134.10/api
  ///   - Emulator Android lokal: --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
  ///   - HP fisik (Wi-Fi sama) : --dart-define=API_BASE_URL=http://IP-LAPTOP:3000/api
  ///   - Domain + HTTPS        : --dart-define=API_BASE_URL=https://domainmu/api
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://43.133.134.10/api',
  );

  /// URL asal (origin) server, untuk memuat aset seperti logo sekolah.
  static const apiOrigin = String.fromEnvironment(
    'API_ORIGIN',
    defaultValue: 'http://43.133.134.10',
  );
}
