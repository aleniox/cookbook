// lib/screens/recipe_list_screen.dart
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'recipe_detail_screen.dart';
import '../widgets/widget_image.dart';

// lib/screens/recipe_list_screen.dart (Chỉ sửa class RecipeListScreen)
class RecipeListScreen extends StatelessWidget {
  // const RecipeListScreen({super.key});
  final Function(Recipe) onPlanAdded;
  
  const RecipeListScreen({super.key, required this.onPlanAdded}); // CẬP NHẬT CONSTRUCTOR
  @override
  Widget build(BuildContext context) {
    // Bỏ Scaffold và chỉ trả về nội dung Body
    return Column(
      children: [
        // Thêm AppBar thủ công nếu muốn
        AppBar(
          title: const Text('Danh sách Công thức', style: TextStyle(fontWeight: FontWeight.bold)),
          // elevation: 0, // Đã được set trong theme
          automaticallyImplyLeading: true, // Hiển thị icon menu
        ),
        Expanded(
          child: ListView.builder(
            itemCount: mockRecipes.length,
            itemBuilder: (context, index) {
              final recipe = mockRecipes[index];
              return RecipeCard(
                recipe: recipe, 
                onPlanAdded: onPlanAdded,
              );
            },
          ),
        ),
      ],
    );
  }
}
// lib/screens/recipe_list_screen.dart (Thay thế RecipeCard bằng StatefulWidget)

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final Function(Recipe) onPlanAdded;

  const RecipeCard({
    super.key, 
    required this.recipe, 
    required this.onPlanAdded,
  });

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  // Trạng thái để quản lý việc mở rộng/thu gọn danh sách nguyên liệu
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần chính của thẻ (Ảnh và Mô tả)
          InkWell(
            borderRadius: BorderRadius.circular(15.0),
            onTap: () {
              // Khi nhấn vào phần chính, chuyển sang màn hình chi tiết
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailScreen(
                    recipe: widget.recipe,
                    onPlanAdded: widget.onPlanAdded,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Ảnh công thức
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: loadImage(
                      widget.recipe.imageUrl,
                      height: 100.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  // 2. Thông tin công thức
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.recipe.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333)
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          widget.recipe.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Color(0xFF6D9886)),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.recipe.durationInMinutes} phút', 
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Thanh gạch ngang (Divider)
          const Divider(height: 0), 

          // Nút để mở/đóng danh sách nguyên liệu
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isExpanded ? 'Thu gọn Nguyên liệu' : 'Xem Nguyên liệu (Checklist)',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),

          // Phần mở rộng: Danh sách Checklist
          if (_isExpanded)
            IngredientChecklist(ingredients: widget.recipe.ingredients),
        ],
      ),
    );
  }
}
// lib/screens/recipe_list_screen.dart (Thêm vào cuối file)

// Widget mới để hiển thị và quản lý trạng thái checklist của nguyên liệu
class IngredientChecklist extends StatefulWidget {
  final List<IngredientItem> ingredients;

  const IngredientChecklist({super.key, required this.ingredients});

  @override
  State<IngredientChecklist> createState() => _IngredientChecklistState();
}

class _IngredientChecklistState extends State<IngredientChecklist> {
  // Hàm này sẽ cập nhật trạng thái của IngredientItem và gọi setState
  void _toggleChecked(IngredientItem item) {
    setState(() {
      item.isChecked = !item.isChecked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 10.0, bottom: 5.0),
          child: Text(
            'Nguyên liệu cần thiết:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
        // Sử dụng ListView.builder để hiển thị danh sách các CheckboxListTile
        ListView.builder(
          shrinkWrap: true, // Quan trọng: Đảm bảo nó chỉ chiếm không gian cần thiết
          physics: const NeverScrollableScrollPhysics(), // Ngăn cuộn để không xung đột với cuộn của màn hình cha
          itemCount: widget.ingredients.length,
          itemBuilder: (context, index) {
            final item = widget.ingredients[index];
            return CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading, // Checkbox nằm bên trái
              dense: true,
              value: item.isChecked,
              onChanged: (bool? newValue) {
                _toggleChecked(item);
              },
              title: Text(
                item.name,
                style: TextStyle(
                  fontSize: 14,
                  // Gạch ngang nếu đã được chọn (checked)
                  decoration: item.isChecked ? TextDecoration.lineThrough : null,
                  color: item.isChecked ? Colors.grey : Colors.black87,
                ),
              ),
              activeColor: Theme.of(context).primaryColor,
            );
          },
        ),
      ],
    );
  }
}