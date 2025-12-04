import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../helpers/database_helper.dart';
import '../services/preset_loader.dart';

class PresetRecipeScreen extends StatefulWidget {
  final Function(Recipe) onAddToRecipeList;

  const PresetRecipeScreen({
    super.key,
    required this.onAddToRecipeList,
  });

  @override
  State<PresetRecipeScreen> createState() => _PresetRecipeScreenState();
}

class _PresetRecipeScreenState extends State<PresetRecipeScreen> {
  late Future<List<Recipe>> _presetFuture;

  @override
  void initState() {
    super.initState();
    _presetFuture = PresetLoader.load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _presetFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final presetRecipes = snapshot.data!;

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
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
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
                            final newRecipe = await DatabaseHelper.instance
                                .createRecipe(recipe);

                            widget.onAddToRecipeList(newRecipe);
                          },
                          icon: const Icon(Icons.add),
                          label:
                              const Text('Thêm vào danh sách công thức'),
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
      },
    );
  }
}
