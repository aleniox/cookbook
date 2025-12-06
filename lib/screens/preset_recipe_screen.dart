import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../helpers/database_helper.dart';
import '../services/preset_loader.dart';

class PresetRecipeScreen extends StatefulWidget {
  final Function(Recipe) onAddToRecipeList;

  const PresetRecipeScreen({super.key, required this.onAddToRecipeList});

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

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: presetRecipes.length,
          itemBuilder: (context, index) {
            final recipe = presetRecipes[index];

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  // Optional: Preview recipe details
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image area
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Recipe image
                          recipe.imageUrl.isNotEmpty
                              ? (recipe.imageUrl.startsWith('http')
                                    ? Image.network(
                                        recipe.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceVariant,
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 48,
                                          ),
                                        ),
                                      )
                                    : Image.asset(
                                        recipe.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surfaceVariant,
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 48,
                                          ),
                                        ),
                                      ))
                              : Container(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceVariant,
                                  child: const Icon(Icons.fastfood, size: 48),
                                ),

                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),

                          // Recipe title
                          Positioned(
                            left: 8,
                            right: 8,
                            bottom: 8,
                            child: Text(
                              recipe.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Recipe details
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${recipe.ingredients.length} nguyên liệu',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe.durationInMinutes}m',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Add button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final newRecipe = await DatabaseHelper.instance
                              .createRecipe(recipe);
                          widget.onAddToRecipeList(newRecipe);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã thêm: ${recipe.title}'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Thêm'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
