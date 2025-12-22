import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'dart:convert';
import '../models/recipe.dart';
import '../models/ingredient_item.dart';

class RecipeService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    // Lưu database trong thư mục dự án
    // final dbPath = 'database';
    // final pathDB = '$dbPath/recipes.db';
    final dbPath = await getDatabasesPath();
    final pathDB = '$dbPath/recipes.db';
    // Tạo thư mục nếu chưa có
    final directory = Directory(dbPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return await openDatabase(
      pathDB,
      version: 1,
      onCreate: (db, version) async {
        // Recipe table - giống DatabaseHelper
        await db.execute('''
          CREATE TABLE recipes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            imageUrl TEXT NOT NULL,
            description TEXT NOT NULL,
            steps TEXT NOT NULL,
            durationInMinutes INTEGER NOT NULL,
            type TEXT NOT NULL
          )
        ''');

        // Ingredients table - giống DatabaseHelper
        await db.execute('''
          CREATE TABLE ingredients(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            recipeId INTEGER NOT NULL,
            name TEXT NOT NULL,
            isChecked INTEGER NOT NULL,
            FOREIGN KEY(recipeId) REFERENCES recipes(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  /// Recipe methods
  static Future<Recipe> createRecipe(Recipe recipe) async {
    final db = await database;

    // Lưu Recipe chính với steps dạng JSON
    final id = await db.insert('recipes', {
      'title': recipe.title,
      'imageUrl': recipe.imageUrl,
      'description': recipe.description,
      'steps': jsonEncode(recipe.steps),
      'durationInMinutes': recipe.durationInMinutes,
      'type': recipe.type,
    });

    final newRecipe = recipe.copyWith(id: id);

    // Lưu Ingredients
    for (var ingredient in recipe.ingredients) {
      await db.insert('ingredients', {
        'recipeId': id,
        'name': ingredient.name,
        'isChecked': ingredient.isChecked ? 1 : 0,
      });
    }

    return newRecipe;
  }

  static Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final recipeMaps = await db.query('recipes', orderBy: 'id ASC');

    List<Recipe> recipes = [];

    for (var map in recipeMaps) {
      // Lấy ingredients
      final ingredientMaps = await db.query(
        'ingredients',
        where: 'recipeId = ?',
        whereArgs: [map['id']],
      );

      final ingredients = ingredientMaps
          .map((i) => IngredientItem(
                id: i['id'] as int?,
                name: i['name'] as String,
                isChecked: (i['isChecked'] as int) == 1,
                recipeId: i['recipeId'] as int?,
              ))
          .toList();

      // Parse steps từ JSON
      final stepsJson = map['steps'] as String;
      final stepsList =
          (jsonDecode(stepsJson) as List<dynamic>).map((e) => e.toString()).toList();

      recipes.add(Recipe(
        id: map['id'] as int?,
        title: map['title'] as String,
        imageUrl: map['imageUrl'] as String,
        description: map['description'] as String,
        steps: stepsList,
        durationInMinutes: map['durationInMinutes'] as int,
        type: map['type'] as String,
        ingredients: ingredients,
      ));
    }

    return recipes;
  }

  static Future<int> updateRecipe(Recipe recipe) async {
    final db = await database;
    return await db.update('recipes', recipe.toMap(),
        where: 'id = ?', whereArgs: [recipe.id]);
  }

  static Future<int> deleteRecipe(int id) async {
    final db = await database;
    return await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
  }

  /// Ingredient methods
  static Future<int> insertIngredient(IngredientItem item) async {
    final db = await database;
    return await db.insert('ingredients', {
      'recipeId': item.recipeId,
      'name': item.name,
      'isChecked': item.isChecked ? 1 : 0,
    });
  }

  static Future<List<IngredientItem>> getIngredients(int recipeId) async {
    final db = await database;
    final data = await db.query('ingredients', where: 'recipeId = ?', whereArgs: [recipeId]);
    return data
        .map((i) => IngredientItem(
              id: i['id'] as int?,
              name: i['name'] as String,
              isChecked: (i['isChecked'] as int) == 1,
              recipeId: i['recipeId'] as int?,
            ))
        .toList();
  }

  static Future<int> updateIngredient(IngredientItem item) async {
    final db = await database;
    return await db.update(
      'ingredients',
      {
        'name': item.name,
        'isChecked': item.isChecked ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }
}
