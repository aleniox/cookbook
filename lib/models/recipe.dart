import 'package:hive/hive.dart';

part 'recipe.g.dart';

/// =======================
/// IngredientItem
/// =======================
@HiveType(typeId: 1)
class IngredientItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  bool isChecked;

  IngredientItem({this.id, required this.name, this.isChecked = false});

  // Chuyển đổi IngredientItem sang Map để lưu vào DB
  Map<String, dynamic> toMap({int? recipeId}) {
    final map = {
      'name': name,
      'isChecked': isChecked ? 1 : 0, // Lưu bool dưới dạng số nguyên
    };
    // Nếu có recipeId, thêm nó vào Map
    if (recipeId != null) {
      map['recipeId'] = recipeId; 
    }
    return map;
  }
}

/// =======================
/// Recipe
/// =======================
@HiveType(typeId: 0)
class Recipe extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String imageUrl;

  @HiveField(2)
  String description;

  @HiveField(3)
  List<IngredientItem> ingredients;

  @HiveField(4)
  List<String> steps;

  @HiveField(5)
  int durationInMinutes;

  Recipe({
    this.id, // Cho phép null khi tạo mới
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.durationInMinutes,
  });
}

/// =======================
/// Mock Data (không lưu vào DB)
/// =======================
final List<Recipe> mockRecipes = [
  Recipe(
    title: 'Gà Sốt Cam',
    imageUrl: 'assets/images/cach-lam-ga-sot-cam.jpg',
    description: 'Một món ăn ngon tuyệt vời...',
    ingredients: [
      IngredientItem(name: '500g ức gà'),
      IngredientItem(name: '2 quả cam (lấy nước và vỏ)'),
      IngredientItem(name: '2 muỗng canh mật ong'),
      IngredientItem(name: '1 muỗng canh xì dầu'),
      IngredientItem(name: 'Gia vị (muối, tiêu)'),
    ],
    steps: [
      'Cắt gà thành miếng vừa ăn và ướp với muối, tiêu.',
    ],
    durationInMinutes: 45,
  ),
  Recipe(
    title: 'Bánh Mì Bơ Tỏi',
    imageUrl: 'assets/images/banh-mi-bo-toi-1-600x400.jpg',
    description: 'Món ăn kèm siêu đơn giản...',
    ingredients: [
      IngredientItem(name: '1 ổ bánh mì baguette'),
      IngredientItem(name: '100g bơ lạt'),
      IngredientItem(name: '3 tép tỏi băm'),
      IngredientItem(name: 'Rau mùi tây băm nhỏ'),
    ],
    steps: [
      'Trộn đều bơ mềm...',
    ],
    durationInMinutes: 20,
  ),
];
