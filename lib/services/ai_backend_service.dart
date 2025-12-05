import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Service để giao tiếp với Python AI Backend
/// Gọi API trực tiếp tới server
class AIBackendService {
  static const String _baseUrl = AppConfig.backendUrl;
  static const Duration _timeout = Duration(seconds: 30);

  /// Kiểm tra server có hoạt động
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/health'),
          )
          .timeout(_timeout);

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Lỗi kiểm tra health: $e');
      return false;
    }
  }

  /// Gợi ý công thức từ nguyên liệu
  /// [ingredients]: Danh sách nguyên liệu
  /// [cuisine]: Loại ẩm thực (VD: "Việt Nam", "Ý")
  /// [difficulty]: Mức độ khó (VD: "dễ", "trung bình", "khó")
  static Future<Map<String, dynamic>?> suggestRecipe({
    required List<String> ingredients,
    String cuisine = '',
    String difficulty = 'trung bình',
  }) async {
    try {
      final payload = {
        'ingredients': ingredients,
        'cuisine': cuisine,
        'difficulty': difficulty,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/suggest-recipe'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('❌ Lỗi gợi ý công thức: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Lỗi kết nối: $e');
      return null;
    }
  }

  /// Tạo kế hoạch ăn uống hàng tuần
  /// [days]: Số ngày trong kế hoạch
  /// [dietary]: Chế độ ăn (VD: "vegetarian", "normal")
  /// [preferences]: Danh sách sở thích
  static Future<Map<String, dynamic>?> generateMealPlan({
    required int days,
    String dietary = 'normal',
    List<String> preferences = const [],
  }) async {
    try {
      final payload = {
        'days': days,
        'dietary': dietary,
        'preferences': preferences,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/meal-plan'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('❌ Lỗi tạo kế hoạch: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Lỗi kết nối: $e');
      return null;
    }
  }

  /// Phân tích thông tin dinh dưỡng của công thức
  /// [title]: Tên công thức
  /// [ingredients]: Danh sách nguyên liệu với số lượng
  static Future<Map<String, dynamic>?> analyzeRecipe({
    required String title,
    required List<String> ingredients,
  }) async {
    try {
      final payload = {
        'title': title,
        'ingredients': ingredients,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/analyze-recipe'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('❌ Lỗi phân tích: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Lỗi kết nối: $e');
      return null;
    }
  }

  /// Lấy mẹo nấu nướng
  /// [dish]: Tên món ăn
  /// [problem]: Vấn đề cần giải quyết
  static Future<Map<String, dynamic>?> getCookingTips({
    required String dish,
    required String problem,
  }) async {
    try {
      final payload = {
        'dish': dish,
        'problem': problem,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/cooking-tips'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('❌ Lỗi lấy mẹo: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Lỗi kết nối: $e');
      return null;
    }
  }
}
