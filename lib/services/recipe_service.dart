import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
    final dbPath = await getDatabasesPath();
    final pathDB = join(dbPath, 'recipes.db');

    return await openDatabase(
      pathDB,
      version: 1,
      onCreate: (db, version) async {
        // Recipe table
        await db.execute('''
          CREATE TABLE recipes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            imageUrl TEXT,
            durationInMinutes INTEGER,
            type TEXT
          )
        ''');

        // Ingredients table
        await db.execute('''
          CREATE TABLE ingredients(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            isChecked INTEGER,
            recipeId INTEGER,
            FOREIGN KEY(recipeId) REFERENCES recipes(id) ON DELETE CASCADE
          )
        ''');

        // Steps table
        await db.execute('''
          CREATE TABLE steps(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            description TEXT,
            recipeId INTEGER,
            FOREIGN KEY(recipeId) REFERENCES recipes(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  /// Recipe methods
  static Future<int> insertRecipe(Recipe recipe) async {
    final db = await database;
    return await db.insert('recipes', recipe.toMap());
  }

  static Future<List<Recipe>> getAllRecipes() async {
    final db = await database;
    final data = await db.query('recipes');
    return data.map((e) => Recipe.fromMap(e)).toList();
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
    return await db.insert('ingredients', item.toMap());
  }

  static Future<List<IngredientItem>> getIngredients(int recipeId) async {
    final db = await database;
    final data =
        await db.query('ingredients', where: 'recipeId = ?', whereArgs: [recipeId]);
    return data.map((e) => IngredientItem.fromMap(e)).toList();
  }

  /// Step methods
  static Future<int> insertStep(int recipeId, String description) async {
    final db = await database;
    return await db.insert('steps', {
      'description': description,
      'recipeId': recipeId,
    });
  }

  static Future<List<String>> getSteps(int recipeId) async {
    final db = await database;
    final data = await db.query('steps', where: 'recipeId = ?', whereArgs: [recipeId]);
    return data.map((e) => e['description'] as String).toList();
  }
}
