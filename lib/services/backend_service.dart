import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service khởi động backend Flask (Chỉ cho Desktop Development)
class BackendService {
  static Process? _backendProcess;
  static bool _isBackendRunning = false;

  /// Khởi động backend Flask (Chỉ hoạt động trên Desktop)
  static Future<bool> startBackend() async {
    // Chỉ chạy backend trên Desktop (Windows, macOS, Linux)
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      if (_isBackendRunning) {
        debugPrint('⚠️ Backend đã chạy');
        return true;
      }

      try {
        debugPrint('🚀 Khởi động backend Flask...');

        // Đường dẫn script backend
        final pythonBackendDir = 'python_backend';
        
        // Windows
        if (Platform.isWindows) {
          _backendProcess = await Process.start(
            'python',
            ['-m', 'flask', 'run'],
            workingDirectory: pythonBackendDir,
          );
        }
        // macOS/Linux
        else {
          _backendProcess = await Process.start(
            'python3',
            ['-m', 'flask', 'run'],
            workingDirectory: pythonBackendDir,
          );
        }

        // Lắng nghe output
        _backendProcess?.stdout.listen((data) {
          debugPrint('🔷 Backend: ${String.fromCharCodes(data)}');
        });

        _backendProcess?.stderr.listen((data) {
          debugPrint('🔴 Backend Error: ${String.fromCharCodes(data)}');
        });

        _isBackendRunning = true;
        debugPrint('✅ Backend Flask đã khởi động thành công');
        return true;
      } catch (e) {
        debugPrint('❌ Lỗi khởi động backend: $e');
        return false;
      }
    } else {
      debugPrint('ℹ️ Backend không thể chạy trên nền tảng này');
      debugPrint('   → Mobile: Cần backend chạy trên server');
      debugPrint('   → Web: Cần backend chạy trên server');
      return false;
    }
  }

  /// Dừng backend
  static Future<void> stopBackend() async {
    if (_backendProcess != null) {
      debugPrint('⛔ Dừng backend Flask...');
      _backendProcess?.kill();
      _backendProcess = null;
      _isBackendRunning = false;
      debugPrint('✅ Backend đã dừng');
    }
  }

  /// Kiểm tra backend đang chạy
  static bool get isBackendRunning => _isBackendRunning;
}
