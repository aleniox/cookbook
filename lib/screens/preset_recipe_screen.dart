import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/ingredient_item.dart';
import '../helpers/database_helper.dart';

class PresetRecipeScreen extends StatelessWidget {
  final Function(Recipe)
  onAddToRecipeList; // callback để thêm vào danh sách công thức

  PresetRecipeScreen({super.key, required this.onAddToRecipeList});

  // 🌟 Danh sách công thức mẫu
  final List<Recipe> presetRecipes = [
    Recipe(
      title: 'Spaghetti Bolognese',
      imageUrl: 'https://i.imgur.com/1R0V1Oi.jpg',
      description: 'Món mì Ý với sốt thịt bò và cà chua thơm ngon.',
      ingredients: [
        IngredientItem(name: '400g mì spaghetti', recipeId: 0),
        IngredientItem(name: '200g thịt bò băm', recipeId: 0),
        IngredientItem(name: '100g sốt cà chua', recipeId: 0),
      ],
      steps: ['Luộc mì', 'Xào thịt bò', 'Trộn sốt với mì'],
      durationInMinutes: 30,
      type: 'Thức ăn',
    ),
    Recipe(
      title: 'Salad Trái Cây',
      imageUrl: 'https://i.imgur.com/2Yb9pZb.jpg',
      description: 'Salad tươi mát từ táo, chuối và nho.',
      ingredients: [
        IngredientItem(name: '1 quả táo', recipeId: 0),
        IngredientItem(name: '1 quả chuối', recipeId: 0),
        IngredientItem(name: '100g nho', recipeId: 0),
      ],
      steps: ['Cắt trái cây', 'Trộn đều', 'Thêm nước sốt'],
      durationInMinutes: 10,
      type: 'Thức ăn',
    ),
    Recipe(
      title: 'Trứng Chiên',
      imageUrl: 'https://i.imgur.com/KzL8Y9E.jpg',
      description: 'Trứng chiên vàng ươm, thơm ngon, nhanh chóng.',
      ingredients: [
        IngredientItem(name: '3 quả trứng', recipeId: 0),
        IngredientItem(name: '1 muỗng dầu ăn', recipeId: 0),
        IngredientItem(name: '1 nhúm muối', recipeId: 0),
      ],
      steps: ['Đập trứng', 'Chiên trên chảo', 'Thêm gia vị'],
      durationInMinutes: 5,
      type: 'Thức ăn',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: presetRecipes.length,
      itemBuilder: (context, index) {
        final recipe = presetRecipes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          elevation: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recipe.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                  child: Image.network(
                    recipe.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.description,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thời gian: ${recipe.durationInMinutes} phút',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Lưu recipe vào DB để có id
                        final newRecipe = await DatabaseHelper.instance
                            .createRecipe(recipe);
                        // Gọi callback
                        onAddToRecipeList(newRecipe);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm vào danh sách công thức'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
