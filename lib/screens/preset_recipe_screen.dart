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
  int _currentPage = 0;
  static const int _itemsPerPage = 6; // 2 columns × 3 rows

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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Không có công thức nào',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        }

        final allRecipes = snapshot.data!;
        final totalPages = (allRecipes.length / _itemsPerPage).ceil();
        final startIndex = _currentPage * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(
          0,
          allRecipes.length,
        );
        final currentPageRecipes = allRecipes.sublist(startIndex, endIndex);

        return Column(
          children: [
            // Recipe grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemCount: currentPageRecipes.length,
                itemBuilder: (context, index) {
                  final recipe = currentPageRecipes[index];
                  return _buildRecipeCard(recipe);
                },
              ),
            ),

            // Pagination
            _buildPaginationBar(totalPages),
          ],
        );
      },
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Optional: Preview recipe details
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (recipe.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  children: [
                    _buildRecipeImage(recipe),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      recipe.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.durationInMinutes}m',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.restaurant,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.ingredients.length}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Add button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _addRecipe(recipe),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Thêm', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeImage(Recipe recipe) {
    if (recipe.imageUrl.startsWith('http')) {
      return Image.network(
        recipe.imageUrl,
        height: 100,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
      );
    } else {
      return Image.asset(
        recipe.imageUrl,
        height: 100,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
      );
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 100,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, size: 40),
    );
  }

  Future<void> _addRecipe(Recipe recipe) async {
    final newRecipe = await DatabaseHelper.instance.createRecipe(recipe);
    widget.onAddToRecipeList(newRecipe);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm: ${recipe.title}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildPaginationBar(int totalPages) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        spacing: 10,
        children: [
          // Page dots
          _buildPageDots(totalPages),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Trước', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
              Text(
                '${_currentPage + 1}/$totalPages',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.teal,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _currentPage < totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Tiếp', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageDots(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => GestureDetector(
          onTap: () => setState(() => _currentPage = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _currentPage == index ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: _currentPage == index ? Colors.teal : Colors.grey[400],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}
