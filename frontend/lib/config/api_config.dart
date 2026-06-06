/// Central place for the backend base URL.
///
/// Host depends on how the app reaches your PC's Spring Boot on :8080:
/// - Real phone over USB: run `adb reverse tcp:8080 tcp:8080` once, then the
///   phone can use `localhost` (current setting).
/// - Android emulator: use `http://10.0.2.2:8080/api`.
/// - Real phone over Wi-Fi: use your PC's LAN IP, e.g. `http://192.168.1.64:8080/api`.
class ApiConfig {
  static const String baseUrl = 'http://localhost:8080/api';
}
