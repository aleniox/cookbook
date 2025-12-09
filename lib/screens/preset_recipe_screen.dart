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
  String _searchQuery = '';
  final Set<String> _activeFilters = {}; // e.g. '≤30m','≤60m','4+'

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

        // Apply search and filters before pagination
        final filteredRecipes = allRecipes.where((recipe) {
          final q = _searchQuery.trim().toLowerCase();
          if (q.isNotEmpty) {
            final hay = '${recipe.title} ${recipe.description}'.toLowerCase();
            if (!hay.contains(q)) return false;
          }

          // Filters
          if (_activeFilters.contains('≤30m') && recipe.durationInMinutes > 30) return false;
          if (_activeFilters.contains('≤60m') && recipe.durationInMinutes > 60) return false;
          if (_activeFilters.contains('4+') && recipe.ingredients.length < 4) return false;

          return true;
        }).toList();

        final totalPages = (filteredRecipes.length / _itemsPerPage).ceil();
        final startIndex = _currentPage * _itemsPerPage;
        final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredRecipes.length);
        final currentPageRecipes = filteredRecipes.sublist(startIndex, endIndex);

        return Column(
          children: [
            // Search + filters
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm công thức, ví dụ: bánh mì, canh',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() {
                                _searchQuery = '';
                                _currentPage = 0;
                              }),
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (v) => setState(() {
                      _searchQuery = v;
                      _currentPage = 0;
                    }),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: const Text('≤30m'),
                          selected: _activeFilters.contains('≤30m'),
                          onSelected: (s) => setState(() {
                            if (s) _activeFilters.add('≤30m'); else _activeFilters.remove('≤30m');
                            _currentPage = 0;
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('≤60m'),
                          selected: _activeFilters.contains('≤60m'),
                          onSelected: (s) => setState(() {
                            if (s) _activeFilters.add('≤60m'); else _activeFilters.remove('≤60m');
                            _currentPage = 0;
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('4+ nguyên liệu'),
                          selected: _activeFilters.contains('4+'),
                          onSelected: (s) => setState(() {
                            if (s) _activeFilters.add('4+'); else _activeFilters.remove('4+');
                            _currentPage = 0;
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Recipe grid: fixed-size tiles that keep constant width/height
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double tileWidth = 400.0;
                  const double tileHeight = 320.0;
                  int columns = (constraints.maxWidth / tileWidth).floor();
                  if (columns < 1) columns = 1;

                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: tileHeight,
                    ),
                    itemCount: currentPageRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = currentPageRecipes[index];
                      return SizedBox(
                        width: tileWidth,
                        height: tileHeight,
                        child: _buildRecipeCard(recipe),
                      );
                    },
                  );
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Optional: Preview recipe details
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with title overlay (rounded top corners)
            SizedBox(
              height: 210,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (recipe.imageUrl.isNotEmpty) _buildRecipeImage(recipe),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.38)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Text(
                        recipe.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black38)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      recipe.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),

                    // Metadata chips + add button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.schedule, size: 13, color: Colors.grey[700]),
                              const SizedBox(width: 6),
                              Text('${recipe.durationInMinutes}m', style: TextStyle(fontSize: 12, color: Colors.grey[800])),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.restaurant, size: 13, color: Colors.grey[700]),
                              const SizedBox(width: 6),
                              Text('${recipe.ingredients.length}', style: TextStyle(fontSize: 12, color: Colors.grey[800])),
                            ],
                          ),
                        ),
                        const Spacer(),

                        // Add button (polished compact pill)
                        ElevatedButton(
                          onPressed: () => _addRecipe(recipe),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            minimumSize: const Size(72, 36),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(Icons.add, size: 16, color: Colors.teal[700]),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Thêm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
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
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
      );
    } else {
      return Image.asset(
        recipe.imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
      );
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey[600])),
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
