// lib/models/recipe.dart

// lib/models/recipe.dart (Cập nhật)

// *** KHAI BÁO MỚI ***
class IngredientItem {
  final String name;
  bool isChecked;

  IngredientItem({required this.name, this.isChecked = false});
}
// *** END KHAI BÁO MỚI ***

class Recipe {
  final String title;
  final String imageUrl;
  final String description;
  // *** THAY ĐỔI Ở ĐÂY ***
  // Ingredients bây giờ là một List<IngredientItem>
  final List<IngredientItem> ingredients;
  // *** END THAY ĐỔI ***
  final List<String> steps;
  final int durationInMinutes;

  Recipe({
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.durationInMinutes,
  });
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
      //...
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
      'Trộn đều bơ mềm...',
      //...
    ],
    durationInMinutes: 20,
  ),
];

// class Recipe {
//   final String title;
//   final String imageUrl;
//   final String description;
//   final List<String> ingredients;
//   final List<String> steps;
//   final int durationInMinutes;

//   Recipe({
//     required this.title,
//     required this.imageUrl,
//     required this.description,
//     required this.ingredients,
//     required this.steps,
//     required this.durationInMinutes,
//   });
// }

// // Dữ liệu giả định
// final List<Recipe> mockRecipes = [
//   Recipe(
//     title: 'Gà Sốt Cam',
//     imageUrl: 'assets/images/cach-lam-ga-sot-cam.jpg',
//     description: 'Một món ăn ngon tuyệt vời, kết hợp giữa vị chua ngọt của cam và thịt gà mềm. Hoàn hảo cho bữa tối cuối tuần.',
//     ingredients: [
//       '500g ức gà',
//       '2 quả cam (lấy nước và vỏ)',
//       '2 muỗng canh mật ong',
//       '1 muỗng canh xì dầu',
//       'Gia vị (muối, tiêu)',
//     ],
//     steps: [
//       'Cắt gà thành miếng vừa ăn và ướp với muối, tiêu.',
//       'Chiên gà đến khi vàng đều.',
//       'Trong chảo khác, đun sôi nước cam, mật ong, xì dầu và vỏ cam.',
//       'Cho gà đã chiên vào sốt và nấu nhỏ lửa đến khi sốt sánh lại.',
//       'Thưởng thức với cơm nóng.',
//     ],
//     durationInMinutes: 45,
//   ),
//   Recipe(
//     title: 'Bánh Mì Bơ Tỏi',
//     imageUrl: 'assets/images/banh-mi-bo-toi-1-600x400.jpg',
//     description: 'Món ăn kèm siêu đơn giản và thơm ngon, với vị béo của bơ và hương thơm nồng của tỏi.',
//     ingredients: [
//       '1 ổ bánh mì baguette',
//       '100g bơ lạt',
//       '3 tép tỏi băm',
//       'Rau mùi tây băm nhỏ',
//     ],
//     steps: [
//       'Trộn đều bơ mềm, tỏi băm, và rau mùi tây.',
//       'Phết hỗn hợp bơ tỏi lên bánh mì đã cắt lát.',
//       'Nướng trong lò ở 180°C khoảng 10-15 phút đến khi vàng giòn.',
//       'Cắt ra và dùng nóng.',
//     ],
//     durationInMinutes: 20,
//   ),
//   // Bạn có thể thêm nhiều công thức giả khác tại đây
// ];