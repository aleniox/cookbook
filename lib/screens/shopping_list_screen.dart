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
    Map<String, IngredientItem> combinedMap = {};

    // Lặp qua tất cả công thức và thêm các nguyên liệu vào danh sách chung
    for (var recipe in recipes) {
      for (var item in recipe.ingredients) {
        
        // 1. Phân tích Nguyên liệu
        // Cố gắng tách số lượng và đơn vị
        final match = _quantityRegex.firstMatch(item.name.trim());
        
        String baseName; // Tên cơ bản (ví dụ: 'ức gà', 'bơ lạt')
        double quantity = 1.0; // Số lượng (Mặc định là 1)
        String unit = ''; // Đơn vị (g, muỗng, quả...)
        
        if (match != null) {
          // Lấy các nhóm đã tách: (1) Số, (2) Đơn vị, (3) Tên còn lại
          final quantityStr = match.group(1);
          final unitStr = match.group(2) ?? '';
          final nameStr = match.group(3)?.trim() ?? item.name.trim();

          // Cố gắng chuyển đổi số lượng
          quantity = double.tryParse(quantityStr ?? '1.0') ?? 1.0;
          unit = unitStr.toLowerCase();
          baseName = nameStr.toLowerCase();

        } else {
          // Không tìm thấy số lượng, coi nguyên tên là tên cơ bản và số lượng là 1
          baseName = item.name.toLowerCase().trim();
        }

        // Tạo khóa gộp (Key) bằng cách kết hợp Tên cơ bản và Đơn vị
        // Ví dụ: 'ức gà_g' hoặc 'chanh_quả'
        final groupingKey = baseName.isNotEmpty ? '$baseName-$unit' : item.name.toLowerCase();

        // 2. Logic Gộp
        if (combinedMap.containsKey(groupingKey)) {
          // Nếu đã tồn tại, cập nhật số lượng
          final existingItem = combinedMap[groupingKey]!;
          
          // Trích xuất số lượng hiện tại từ tên đã có
          final existingMatch = _quantityRegex.firstMatch(existingItem.name);
          double existingQuantity = 1.0;
          if (existingMatch != null && existingMatch.group(1) != null) {
            existingQuantity = double.tryParse(existingMatch.group(1)!) ?? 1.0;
          }

          // Tổng số lượng mới
          final newQuantity = existingQuantity + quantity;
          
          // Cập nhật lại tên (đảm bảo giữ nguyên trạng thái checked)
          String newName;
          if (unit.isNotEmpty) {
            // Định dạng lại tên: 'Số lượng' + 'Đơn vị' + 'Tên'
            newName = '$newQuantity $unit $baseName';
          } else {
             // Định dạng lại tên: 'Số lượng' + 'Tên' (Nếu không có đơn vị rõ ràng)
            newName = '$newQuantity $baseName';
          }
          
          combinedMap[groupingKey] = IngredientItem(
            name: newName,
            isChecked: existingItem.isChecked || item.isChecked, // Giữ trạng thái checked nếu 1 trong 2 đã checked
          );
          
        } else {
          // Nếu chưa tồn tại, thêm mới (chỉ lấy tên gốc nếu không cần gộp)
          // Tên mới chỉ bao gồm số lượng + đơn vị + tên cơ bản nếu đã tách được.
          final newName = (unit.isNotEmpty) 
            ? '$quantity $unit $baseName' 
            : item.name;

          combinedMap[groupingKey] = IngredientItem(
            name: newName,
            isChecked: item.isChecked,
          );
        }
      }
    }
    List<IngredientItem> combinedList = combinedMap.values.toList();
    combinedList.sort((a, b) => (a.isChecked ? 1 : 0).compareTo(b.isChecked ? 1 : 0));
    return combinedList;
  }
// Cần gọi lại hàm gộp khi setState được gọi.
  @override
  void didUpdateWidget(covariant ShoppingListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu danh sách công thức đã thay đổi, cần gộp lại
    if (widget.recipes != oldWidget.recipes) {
      shoppingItems = _extractIngredients(widget.recipes);
    }
  }

  void _toggleChecked(IngredientItem item) {
    // Tìm và cập nhật item trong danh sách hiện tại
    setState(() {
      final index = shoppingItems.indexWhere((e) => e == item);
      if (index != -1) {
         shoppingItems[index].isChecked = !shoppingItems[index].isChecked;
      }
      // Sắp xếp lại danh sách để các mục đã gạch bỏ xuống cuối
      shoppingItems.sort((a, b) => (a.isChecked ? 1 : 0).compareTo(b.isChecked ? 1 : 0));
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
              :ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: shoppingItems.length,
                  itemBuilder: (context, index) {
                    final item = shoppingItems[index];
                    return CheckboxListTile(
                      title: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 16,
                          decoration: item.isChecked ? TextDecoration.lineThrough : null,
                          color: item.isChecked ? Colors.grey : Colors.black,
                        ),
                      ),
                      value: item.isChecked,
                      onChanged: (bool? newValue) {
                        _toggleChecked(item);
                      },
                      activeColor: Colors.teal,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
