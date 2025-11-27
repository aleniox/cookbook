import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/recipe.dart';
import '../models/ingredient_item.dart';

class PresetLoader {
  static Future<List<Recipe>> load() async {
    // Load JSON text
    final String jsonText =
        await rootBundle.loadString('assets/data/preset_recipes.json');

    // Decode JSON
    final List<dynamic> data = json.decode(jsonText);

    // Parse thành List<Recipe>
    return data.map((item) {
      return Recipe(
        title: item['title'],
        imageUrl: item['imageUrl'],
        description: item['description'],
        ingredients: (item['ingredients'] as List<dynamic>)
            .map((ing) => IngredientItem(name: ing['name'], recipeId: 0))
            .toList(),
        steps: List<String>.from(item['steps']),
        durationInMinutes: item['durationInMinutes'],
        type: item['type'],
      );
    }).toList();
  }
}
