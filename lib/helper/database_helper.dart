// lib/helpers/database_helper.dart

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/recipe.dart'; // Đảm bảo import mô hình

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Tên bảng
  static const String tableRecipes = 'recipes';
  static const String tableIngredients = 'ingredients';

  // Tên cột bảng recipes
  static const String columnRecipeId = 'id';
  static const String columnTitle = 'title';
  static const String columnImageUrl = 'imageUrl';
  static const String columnDescription = 'description';
  static const String columnSteps = 'steps';
  static const String columnDuration = 'durationInMinutes';

  // Tên cột bảng ingredients
  static const String columnIngredientId = 'id';
  static const String columnRecipeFk = 'recipeId'; // Foreign Key
  static const String columnIngredientName = 'name';
  static const String columnIsChecked = 'isChecked';
  
  // Mở hoặc khởi tạo database
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

  // Tạo bảng (chạy một lần khi khởi tạo DB)
  Future _createDB(Database db, int version) async {
    // Bảng Công thức (RECIPES)
    await db.execute('''
      CREATE TABLE $tableRecipes (
        $columnRecipeId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTitle TEXT NOT NULL,
        $columnImageUrl TEXT NOT NULL,
        $columnDescription TEXT NOT NULL,
        $columnSteps TEXT NOT NULL,
        $columnDuration INTEGER NOT NULL
      )
    ''');
    
    // Bảng Nguyên liệu (INGREDIENTS): Cần khóa ngoại (Foreign Key)
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

  // --- CÁC HÀM CRUD CƠ BẢN ---

  // 1. LƯU (CREATE) Công thức mới
  Future<Recipe> createRecipe(Recipe recipe) async {
    final db = await instance.database;
    
    // 1. Lưu Recipe chính
    final id = await db.insert(tableRecipes, recipe.toMap());
    final newRecipe = recipe.copyWith(id: id);

    // 2. Lưu Ingredients (Liên kết bằng id của Recipe)
    for (var ingredient in recipe.ingredients) {
      // *** SỬ DỤNG THAM SỐ MỚI VÀ KHÓA NGOẠI ***
      await db.insert(tableIngredients, ingredient.toMap(recipeId: id)); 
    }

    return newRecipe;
  }

  // 2. ĐỌC (READ) Tất cả Công thức
  Future<List<Recipe>> readAllRecipes() async {
    final db = await instance.database;
    
    // Đọc tất cả Recipe
    final resultMaps = await db.query(tableRecipes, orderBy: '$columnRecipeId ASC');
    
    // Chuyển Map thành Recipe Object
    final recipes = resultMaps.map((map) => Recipe.fromMap(map)).toList();
    
    // Đọc Ingredients cho từng Recipe
    for (var recipe in recipes) {
      final ingredientMaps = await db.query(
        tableIngredients,
        where: '$columnRecipeFk = ?',
        whereArgs: [recipe.id],
      );
      
      recipe.ingredients.addAll(ingredientMaps.map((map) => IngredientItem(
        id: map[columnIngredientId] as int?,
        name: map[columnIngredientName] as String,
        isChecked: (map[columnIsChecked] as int) == 1,
      )));
    }
    
    return recipes;
  }

  // 3. CẬP NHẬT (UPDATE) Trạng thái Ingredient (Gạch bỏ)
  Future<int> updateIngredient(IngredientItem ingredient) async {
    final db = await instance.database;
    
    return db.update(
      tableIngredients,
      ingredient.toMap(),
      where: '$columnIngredientId = ?',
      whereArgs: [ingredient.id],
    );
  }

  // 4. XÓA (DELETE) Công thức
  Future<int> deleteRecipe(int id) async {
    final db = await instance.database;

    // Khi xóa Recipe, các Ingredients liên quan cũng sẽ bị xóa
    // nhờ 'ON DELETE CASCADE' đã đặt trong _createDB
    return await db.delete(
      tableRecipes,
      where: '$columnRecipeId = ?',
      whereArgs: [id],
    );
  }
  
  // Đóng database khi ứng dụng kết thúc
  Future close() async {
    final db = await instance.database;
    _database = null; // Đặt lại null để nó có thể được mở lại
    db.close();
  }
}