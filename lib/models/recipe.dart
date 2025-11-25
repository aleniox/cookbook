// lib/models/recipe.dart (Cập nhật)

// *** KHAI BÁO MỚI ***
class IngredientItem {
  final int? id; // ID DB cho Ingredient (nếu bạn muốn lưu riêng)
  final String name;
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
// *** END KHAI BÁO MỚI ***

class Recipe {
  final int? id; // ID DB cho Recipe (Primary Key)
  final String title;
  final String imageUrl;
  final String description;
  // Ingredients sẽ được lưu vào bảng riêng (hoặc dưới dạng JSON/Text, 
  // nhưng ta sẽ dùng bảng riêng để dễ quản lý hơn)
  final List<IngredientItem> ingredients; 
  final List<String> steps;
  final int durationInMinutes;

  Recipe({
    this.id, // Cho phép null khi tạo mới
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.durationInMinutes,
  });
  Recipe copyWith({
    int? id,
    String? title,
    String? imageUrl,
    String? description,
    List<IngredientItem>? ingredients,
    List<String>? steps,
    int? durationInMinutes,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      durationInMinutes: durationInMinutes ?? this.durationInMinutes,
    );
  }
  // Chuyển đổi Recipe sang Map (không bao gồm ingredients/steps)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'description': description,
      // Lưu steps dưới dạng chuỗi JSON hoặc nối chuỗi (ví dụ: bằng dấu phẩy)
      'steps': steps.join('|||'), 
      'durationInMinutes': durationInMinutes,
    };
  }
factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] as int?,
      title: map['title'] as String,
      imageUrl: map['imageUrl'] as String,
      description: map['description'] as String,
      // Tách chuỗi steps thành List<String>
      steps: (map['steps'] as String).split('|||'), 
      durationInMinutes: map['durationInMinutes'] as int,
      ingredients: [], // Sẽ được load riêng biệt từ DB
    );
  }
}
// Dữ liệu giả định (Cần cập nhật cách tạo List<IngredientItem>)
// Thay vì List<String>, bây giờ chúng ta dùng List<IngredientItem>
final List<Recipe> mockRecipes = [
  Recipe(
    title: 'Gà Sốt Cam',
    imageUrl: 'assets/images/cach-lam-ga-sot-cam.jpg', // Dùng assets theo hướng dẫn trước
    description: 'Một món ăn ngon tuyệt vời...',
    // *** CẬP NHẬT CÁCH TẠO DANH SÁCH ***
    ingredients: [
      IngredientItem(name: '500g ức gà'),
      IngredientItem(name: '2 quả cam (lấy nước và vỏ)'),
      IngredientItem(name: '2 muỗng canh mật ong'),
      IngredientItem(name: '1 muỗng canh xì dầu'),
      IngredientItem(name: 'Gia vị (muối, tiêu)'),
    ],
    // *** END CẬP NHẬT ***
    steps: [
      'Cắt gà thành miếng vừa ăn và ướp với muối, tiêu.',
      'Chiên gà đến khi vàng đều.',
      'Trong chảo khác, đun sôi nước cam, mật ong, xì dầu và vỏ cam.',
      'Cho gà đã chiên vào sốt và nấu nhỏ lửa đến khi sốt sánh lại.',
      'Thưởng thức với cơm nóng.',
    ],
    durationInMinutes: 45,
  ),
  // Cập nhật công thức Bánh Mì Bơ Tỏi tương tự
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
      'Trộn đều bơ mềm, tỏi băm, và rau mùi tây.',
      'Phết hỗn hợp bơ tỏi lên bánh mì đã cắt lát.',
      'Nướng trong lò ở 180°C khoảng 10-15 phút đến khi vàng giòn.',
      'Cắt ra và dùng nóng.',
    ],
    durationInMinutes: 20,
  ),
];