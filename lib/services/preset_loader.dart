import '../models/recipe.dart';
import '../models/ingredient_item.dart';
import 'supabase_service.dart';

class PresetLoader {
  static Future<List<Recipe>> load() async {
    try {
      print('Loading preset recipes from Supabase...');
      final recipes = await SupabaseService().getPresetRecipes();
      print('Successfully loaded ${recipes.length} recipes from Supabase');
      return recipes;
    } catch (e) {
      print('Failed to load from server: $e');
      // Fallback: trả về local recipes hoặc empty list
      return _getLocalFallback();
    }
  }

  static List<Recipe> _getLocalFallback() {
    // Fallback recipes nếu server không hoạt động
    return [
      Recipe(
        title: 'Phở Bò',
        description: 'Phở bò truyền thống Việt Nam',
        imageUrl: '',
        durationInMinutes: 120,
        type: 'Thức ăn',
        ingredients: [
          IngredientItem(name: '500g thịt bò'),
          IngredientItem(name: '200g bánh phở'),
          IngredientItem(name: '2 quả hành'),
          IngredientItem(name: '1 miếng gừng'),
        ],
        steps: [
          'Luộc thịt bò',
          'Nấu nước dùng',
          'Xếp bánh phở vào tô',
          'Đổ nước dùng vào',
          'Thêm rau thơm',
        ],
      ),
      Recipe(
        title: 'Cơm Tấm',
        description: 'Cơm tấm sườn nướng',
        imageUrl: '',
        durationInMinutes: 45,
        type: 'Thức ăn',
        ingredients: [
          IngredientItem(name: '300g cơm tấm'),
          IngredientItem(name: '200g sườn lợn'),
          IngredientItem(name: '1 quả trứng'),
          IngredientItem(name: '100g dưa leo'),
        ],
        steps: [
          'Nướng sườn',
          'Chiên trứng',
          'Cắt dưa leo',
          'Xếp cơm lên đĩa',
          'Xếp topping',
        ],
      ),
    ];
  }
}
