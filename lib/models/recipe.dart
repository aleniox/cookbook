import 'package:hive/hive.dart';
part 'recipe.g.dart';

/// =======================
/// IngredientItem
/// =======================
@HiveType(typeId: 1)
class IngredientItem extends HiveObject {
  @HiveField(0)
  int? id; // ID trong SQLite

  @HiveField(1)
  String name;

  @HiveField(2)
  bool isChecked;

  @HiveField(3)
  int? recipeId; // foreign key trong SQLite

  IngredientItem({
    this.id,
    required this.name,
    this.isChecked = false,
    this.recipeId,
  });

  IngredientItem copyWith({
    int? id,
    String? name,
    bool? isChecked,
    int? recipeId,
  }) {
    return IngredientItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
      recipeId: recipeId ?? this.recipeId,
    );
  }

  /// DÙNG CHO SQLite
  Map<String, dynamic> toMap({int? recipeId}) {
    return {
      if (id != null) 'id': id,
      'name': name,
      'isChecked': isChecked ? 1 : 0, // SQLite BOOL
      'recipeId': recipeId ?? this.recipeId,
    };
  }

  /// DÙNG CHO SQLite
  factory IngredientItem.fromMap(Map<String, dynamic> map) {
    return IngredientItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      isChecked: (map['isChecked'] ?? 0) == 1,
      recipeId: map['recipeId'] as int?,
    );
  }
}

/// =======================
/// Recipe
/// =======================
@HiveType(typeId: 0)
class Recipe extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String imageUrl;

  @HiveField(3)
  String description;

  @HiveField(4)
  List<IngredientItem> ingredients;

  @HiveField(5)
  List<String> steps;

  @HiveField(6)
  int durationInMinutes;

  @HiveField(7)
  String type; // thêm trường loại: 'Đồ uống', 'Thức ăn', ...

  Recipe({
    this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.durationInMinutes,
    required this.type,
  });

  Recipe copyWith({
    int? id,
    String? title,
    String? imageUrl,
    String? description,
    List<IngredientItem>? ingredients,
    List<String>? steps,
    int? durationInMinutes,
    String? type,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      durationInMinutes: durationInMinutes ?? this.durationInMinutes,
      type: type ?? this.type,
    );
  }

  /// DÙNG CHO SQLite (KHÔNG LƯU DANH SÁCH VÀO SQLite)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'description': description,
      'durationInMinutes': durationInMinutes,
      'type': type,
    };
  }

  /// DÙNG CHO SQLite
  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as int?,
      title: map['title'] as String,
      imageUrl: map['imageUrl'] as String,
      description: map['description'] as String,
      ingredients: [], // load riêng theo recipeId
      steps: [],       // load riêng nếu cần
      durationInMinutes: map['durationInMinutes'] as int,
      type: map['type'] as String? ?? 'Khác', // default nếu chưa có
    );
  }
}
