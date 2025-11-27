import 'ingredient_item.dart';
class Recipe {
  int? id;
  String title;
  String imageUrl;
  String description;
  int durationInMinutes;
  String type;

  List<IngredientItem> ingredients = [];
  List<String> steps = [];

  Recipe({
    this.id,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.durationInMinutes,
    required this.type,
    List<IngredientItem>? ingredients,
    List<String>? steps,
  }) {
    this.ingredients = ingredients ?? [];
    this.steps = steps ?? [];
  }

  Recipe copyWith({
    int? id,
    String? title,
    String? imageUrl,
    String? description,
    int? durationInMinutes,
    String? type,
    List<IngredientItem>? ingredients,
    List<String>? steps,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      durationInMinutes: durationInMinutes ?? this.durationInMinutes,
      type: type ?? this.type,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
    );
  }

  /// map dành cho SQLite (không chứa ingredients và steps)
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

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'],
      title: map['title'],
      imageUrl: map['imageUrl'],
      description: map['description'],
      durationInMinutes: map['durationInMinutes'],
      type: map['type'] ?? 'Khác',
      ingredients: [], // load riêng
      steps: [],       // load riêng
    );
  }
}
