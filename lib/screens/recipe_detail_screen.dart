// lib/screens/recipe_detail_screen.dart
import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../widgets/widget_image.dart';
// Ví dụ về cách kiểm tra và hiển thị ảnh



class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  final Function(Recipe) onPlanAdded;

  const RecipeDetailScreen({
      super.key, 
      required this.recipe,
      required this.onPlanAdded, // THÊM TRƯỜNG NÀY
    });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          // AppBar dạng Sliver để chứa ảnh lớn
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(offset: Offset(1, 1), blurRadius: 3.0, color: Colors.black54)
                  ]
                ),
              ),
              // background: Image.network(
              //   recipe.imageUrl,
              //   fit: BoxFit.cover,
              // ),
              background: loadImage(
                recipe.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Mô tả
                      Text(
                        recipe.description,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 20),

                      // Thời gian chuẩn bị
                      Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.orange, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Thời gian chuẩn bị: ${recipe.durationInMinutes} phút',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const Divider(height: 30),

                      // Nguyên liệu
                      const Text(
                        '✨ Nguyên liệu',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      ...recipe.ingredients.map((ingredient) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('•  ', style: TextStyle(fontSize: 18, color: Colors.orange)),
                                Expanded(
                                  child: Text(ingredient.name, style: const TextStyle(fontSize: 16)),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 30),

                      // Các bước thực hiện
                      const Text(
                        '📝 Các bước thực hiện',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      ...recipe.steps.asMap().entries.map((entry) {
                        int index = entry.key;
                        String step = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(step, style: const TextStyle(fontSize: 16, height: 1.5)),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // 1. Thực thi callback để thông báo cho MainAppLayout
            onPlanAdded(recipe); 
            // 2. Hiện thông báo và quay lại màn hình trước
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã thêm ${recipe.title} vào kế hoạch!')),
            );
            Navigator.pop(context); // Quay lại màn hình danh sách
          },
          label: const Text('Thêm vào Kế hoạch', style: TextStyle(fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add_shopping_cart),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
      ),
    );
  }
}