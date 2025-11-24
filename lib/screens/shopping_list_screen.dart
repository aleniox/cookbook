// lib/screens/shopping_list_screen.dart
import 'package:flutter/material.dart';
import '../models/recipe.dart';

class ShoppingListScreen extends StatefulWidget {
  final List<Recipe> recipes;

  const ShoppingListScreen({super.key, required this.recipes});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // Danh sách này sẽ chứa tất cả các nguyên liệu từ các công thức
  late List<IngredientItem> shoppingItems;

  final RegExp _quantityRegex = RegExp(r'(\d*\.?\d+)\s*([a-zA-Z]+)?\s*(.*)');
  @override
  void initState() {
    super.initState();
    shoppingItems = _extractIngredients(widget.recipes);
  }

  // Hàm trích xuất và kết hợp tất cả nguyên liệu
  List<IngredientItem> _extractIngredients(List<Recipe> recipes) {
    List<IngredientItem> combinedList = [];

    // Lặp qua tất cả công thức và thêm các nguyên liệu vào danh sách chung
    for (var recipe in recipes) {
      combinedList.addAll(
        recipe.ingredients.map(
          (item) => IngredientItem(name: item.name, isChecked: item.isChecked),
        ),
      );
    }
    return combinedList;
  }

  void _toggleChecked(IngredientItem item) {
    setState(() {
      item.isChecked = !item.isChecked;
      // Tùy chọn: Sắp xếp lại danh sách để các mục đã gạch bỏ xuống cuối
      shoppingItems.sort(
        (a, b) => (a.isChecked ? 1 : 0).compareTo(b.isChecked ? 1 : 0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Bỏ Scaffold và chỉ trả về nội dung
    return Column(
      // <<< Thay vì trả về Scaffold, trả về Column
      children: [
        AppBar(
          // <<< THÊM APP BAR ĐỂ HIỂN THỊ NÚT MENU (DRAWER)
          title: Text(
            '🛒 Kế hoạch Nấu nướng (${widget.recipes.length} món)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: true, // Đảm bảo nút menu xuất hiện
        ),
        Expanded(
          // Wrap nội dung còn lại trong Expanded
          child: shoppingItems.isEmpty
              ? const Center(
                  child: Text('Chưa có nguyên liệu nào trong danh sách.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: shoppingItems.length,
                  itemBuilder: (context, index) {
                    return null;
                  
                    // ... (phần CheckboxListTile giữ nguyên)
                  },
                ),
        ),
      ],
    );
  }
}
