// lib/helpers/database_helper.dart
import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/recipe.dart';
import '../models/ingredient_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Tên bảng
  static const String tableRecipes = 'recipes';
  static const String tableIngredients = 'ingredients';

  // Cột bảng recipes
  static const String columnRecipeId = 'id';
  static const String columnTitle = 'title';
  static const String columnImageUrl = 'imageUrl';
  static const String columnDescription = 'description';
  static const String columnSteps = 'steps'; // sẽ lưu JSON list
  static const String columnDuration = 'durationInMinutes';
  static const String columnType = 'type';

  // Cột bảng ingredients
  static const String columnIngredientId = 'id';
  static const String columnRecipeFk = 'recipeId';
  static const String columnIngredientName = 'name';
  static const String columnIsChecked = 'isChecked';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recipes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Bảng Recipes
    await db.execute('''
      CREATE TABLE $tableRecipes (
        $columnRecipeId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT NOT NULL,
        $columnImageUrl TEXT NOT NULL,
        $columnDescription TEXT NOT NULL,
        $columnSteps TEXT NOT NULL,
        $columnDuration INTEGER NOT NULL,
        $columnType TEXT NOT NULL
      )
    ''');

    // Bảng Ingredients
    await db.execute('''
      CREATE TABLE $tableIngredients (
        $columnIngredientId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnRecipeFk INTEGER NOT NULL,
        $columnIngredientName TEXT NOT NULL,
        $columnIsChecked INTEGER NOT NULL,
        FOREIGN KEY ($columnRecipeFk) REFERENCES $tableRecipes ($columnRecipeId) ON DELETE CASCADE
      )
    ''');
  }

  // CREATE Recipe
  Future<Recipe> createRecipe(Recipe recipe) async {
    final db = await instance.database;

    // Lưu Recipe chính
    final id = await db.insert(tableRecipes, {
      columnTitle: recipe.title,
      columnImageUrl: recipe.imageUrl,
      columnDescription: recipe.description,
      columnSteps: jsonEncode(recipe.steps),
      columnDuration: recipe.durationInMinutes,
      columnType: recipe.type,
    });

    final newRecipe = recipe.copyWith(id: id);

    // Lưu Ingredients
    for (var ingredient in recipe.ingredients) {
      await db.insert(tableIngredients, {
        columnRecipeFk: id,
        columnIngredientName: ingredient.name,
        columnIsChecked: ingredient.isChecked ? 1 : 0,
      });
    }

    return newRecipe;
  }

  // READ tất cả Recipes
  Future<List<Recipe>> readAllRecipes() async {
    final db = await instance.database;
    final recipeMaps = await db.query(tableRecipes, orderBy: '$columnRecipeId ASC');

    List<Recipe> recipes = [];

    for (var map in recipeMaps) {
      // Lấy ingredients
      final ingredientMaps = await db.query(
        tableIngredients,
        where: '$columnRecipeFk = ?',
        whereArgs: [map[columnRecipeId]],
      );

      final ingredients = ingredientMaps.map((i) => IngredientItem(
        id: i[columnIngredientId] as int?,
        name: i[columnIngredientName] as String,
        isChecked: (i[columnIsChecked] as int) == 1,
      )).toList();

      // Parse steps từ JSON
      final stepsJson = map[columnSteps] as String;
      final stepsList = (jsonDecode(stepsJson) as List<dynamic>).map((e) => e.toString()).toList();

      recipes.add(Recipe(
        id: map[columnRecipeId] as int?,
        title: map[columnTitle] as String,
        imageUrl: map[columnImageUrl] as String,
        description: map[columnDescription] as String,
        steps: stepsList,
        durationInMinutes: map[columnDuration] as int,
        type: map[columnType] as String,
        ingredients: ingredients,
      ));
    }

    return recipes;
  }

  // UPDATE ingredient
  Future<int> updateIngredient(IngredientItem ingredient) async {
    final db = await instance.database;
    return db.update(
      tableIngredients,
      {
        columnIngredientName: ingredient.name,
        columnIsChecked: ingredient.isChecked ? 1 : 0,
        // columnRecipeFk: recipeId,
      },
      where: '$columnIngredientId = ?',
      whereArgs: [ingredient.id],
    );
  }

  // DELETE Recipe
  Future<int> deleteRecipe(int id) async {
    final db = await instance.database;
    return db.delete(tableRecipes, where: '$columnRecipeId = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    _database = null;
    await db.close();
  }
}
