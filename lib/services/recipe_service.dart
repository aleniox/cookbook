import 'package:hive/hive.dart';
import '../models/recipe.dart';

class RecipeService {
  static final _box = Hive.box<Recipe>('recipes');

  static List<Recipe> getAllRecipes() {
    return _box.values.toList();
  }

  static Future<void> addRecipe(Recipe recipe) async {
    await _box.add(recipe);
  }

  static Future<void> deleteRecipe(Recipe recipe) async {
    await recipe.delete();
  }

  static Future<void> updateRecipe(Recipe recipe) async {
    await recipe.save();
  }
}
