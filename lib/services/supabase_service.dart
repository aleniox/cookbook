import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/recipe.dart';
import '../models/ingredient_item.dart';

class SupabaseService {
  static const String _supabaseUrl = 'https://vlaibcnhxubbhejdliqq.supabase.co';
  static const String _supabaseKey =
      'sb_publishable_1ox4f9wUB-qOJeyCh70lWw_6edarRdU';

  // Lấy URL và Key từ Supabase dashboard

  static final SupabaseService _instance = SupabaseService._init();

  SupabaseService._init();

  factory SupabaseService() {
    return _instance;
  }

  Future<List<Recipe>> getPresetRecipes() async {
    try {
      // Kiểm tra xem key có được cấu hình không
      if (_supabaseUrl.contains('YOUR_PROJECT') ||
          _supabaseKey.contains('YOUR_ANON_KEY')) {
        throw Exception(
          'Supabase not configured. Please set _supabaseUrl and _supabaseKey.',
        );
      }

      final recipesResponse = await http
          .get(
            Uri.parse('$_supabaseUrl/rest/v1/preset_recipes'),
            headers: {
              'Authorization': 'Bearer $_supabaseKey',
              'apikey': _supabaseKey,
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (recipesResponse.statusCode != 200) {
        throw Exception(
          'Failed to load recipes: ${recipesResponse.statusCode} - ${recipesResponse.body}',
        );
      }

      final recipesList = jsonDecode(recipesResponse.body) as List;
      List<Recipe> recipes = [];

      for (var recipeData in recipesList) {
        final recipeId = recipeData['id'];

        // Lấy nguyên liệu
        final ingredientsResponse = await http
            .get(
              Uri.parse(
                '$_supabaseUrl/rest/v1/preset_ingredients?recipe_id=eq.$recipeId',
              ),
              headers: {
                'Authorization': 'Bearer $_supabaseKey',
                'apikey': _supabaseKey,
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        List<IngredientItem> ingredients = [];
        if (ingredientsResponse.statusCode == 200) {
          final ingredientsList = jsonDecode(ingredientsResponse.body) as List;
          ingredients = ingredientsList
              .map(
                (ing) => IngredientItem(
                  name: ing['name'] as String? ?? '',
                  isChecked: false,
                ),
              )
              .toList();
        }

        // Lấy các bước
        final stepsResponse = await http
            .get(
              Uri.parse(
                '$_supabaseUrl/rest/v1/preset_steps?recipe_id=eq.$recipeId&order=step_order.asc',
              ),
              headers: {
                'Authorization': 'Bearer $_supabaseKey',
                'apikey': _supabaseKey,
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        List<String> steps = [];
        if (stepsResponse.statusCode == 200) {
          final stepsList = jsonDecode(stepsResponse.body) as List;
          steps = stepsList
              .map((step) => step['step_text'] as String? ?? '')
              .toList();
        }

        recipes.add(
          Recipe(
            id: recipeId,
            title: recipeData['title'] as String? ?? 'Untitled',
            description: recipeData['description'] as String? ?? '',
            imageUrl: recipeData['image_url'] as String? ?? '',
            durationInMinutes: recipeData['duration_minutes'] as int? ?? 0,
            type: recipeData['type'] as String? ?? 'Thức ăn',
            ingredients: ingredients,
            steps: steps,
          ),
        );
      }

      return recipes;
    } catch (e) {
      throw Exception('Error loading preset recipes: $e');
    }
  }
}
