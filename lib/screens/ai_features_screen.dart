import 'package:flutter/material.dart';
import '../services/ai_backend_service.dart';
import '../models/recipe.dart';

class AIFeaturesScreen extends StatefulWidget {
  const AIFeaturesScreen({super.key});

  @override
  State<AIFeaturesScreen> createState() => _AIFeaturesScreenState();
}

class _AIFeaturesScreenState extends State<AIFeaturesScreen> {
  bool _isConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final connected = await AIBackendService.checkHealth();
    setState(() => _isConnected = connected);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tính Năng AI'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _checkConnection,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status card - cleaner layout using ListTile style
                  Card(
                    color: _isConnected ? Colors.green.withOpacity(0.06) : Colors.red.withOpacity(0.06),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: _isConnected ? Colors.green.withOpacity(0.14) : Colors.red.withOpacity(0.14),
                            child: Icon(
                              _isConnected ? Icons.check_circle : Icons.cloud_off,
                              color: _isConnected ? Colors.green : Colors.red,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isConnected ? 'Backend AI: Đã kết nối' : 'Backend AI: Chưa kết nối',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isConnected
                                      ? 'Dịch vụ AI sẵn sàng để sử dụng các tính năng.'
                                      : 'Chạy backend Python trong `python_backend/` để bật các tính năng AI.',
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _checkConnection,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Kiểm tra'),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Hướng dẫn chạy Backend'),
                                      content: const Text('Mở terminal và chạy:\n\npython -m flask run\n\nTrong thư mục `python_backend/`.'),
                                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
                                    ),
                                  );
                                },
                                child: const Text('Hướng dẫn'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Features
                  if (_isConnected) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.0),
                      child: Text('Tính năng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const double tileWidth = 360.0;
                        const double tileHeight = 110.0;
                        int columns = (constraints.maxWidth / tileWidth).floor();
                        if (columns < 1) columns = 1;

                        final features = [
                          {'icon': Icons.lightbulb, 'title': 'Gợi ý công thức', 'subtitle': 'Gợi ý từ nguyên liệu có sẵn', 'tap': _showSuggestRecipeDialog},
                          {'icon': Icons.calendar_today, 'title': 'Kế hoạch ăn uống', 'subtitle': 'Tạo kế hoạch 7 ngày', 'tap': _showMealPlanDialog},
                          {'icon': Icons.restaurant_menu, 'title': 'Phân tích dinh dưỡng', 'subtitle': 'Ước tính dinh dưỡng', 'tap': _showAnalyzeRecipeDialog},
                          {'icon': Icons.local_fire_department, 'title': 'Mẹo nấu nướng', 'subtitle': 'Lời khuyên và khắc phục sự cố', 'tap': _showCookingTipsDialog},
                        ];

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: tileHeight,
                          ),
                          itemCount: features.length,
                          itemBuilder: (ctx, i) {
                            final f = features[i];
                            return SizedBox(
                              width: tileWidth,
                              height: tileHeight,
                              child: _buildFeatureCard(
                                icon: f['icon'] as IconData,
                                title: f['title'] as String,
                                subtitle: f['subtitle'] as String,
                                onTap: f['tap'] as VoidCallback,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_off, size: 72, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('Backend chưa kết nối', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          const Text('Vui lòng chạy backend để sử dụng các tính năng AI.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _checkConnection, child: const Text('Kiểm tra lại')),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _isLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuggestRecipeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gợi ý công thức'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhập các nguyên liệu (cách nhau bằng dấu phẩy):'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'VD: cà chua, dưa chuột, hành',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ingredients = controller.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              if (ingredients.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập nguyên liệu')),
                );
                return;
              }

              await _suggestRecipe(ingredients);
            },
            child: const Text('Tìm'),
          ),
        ],
      ),
    );
  }

  Future<void> _suggestRecipe(List<String> ingredients) async {
    setState(() => _isLoading = true);

    try {
      final result = await AIBackendService.suggestRecipe(
        ingredients: ingredients,
        cuisine: 'Việt Nam',
        difficulty: 'trung bình',
      );

      if (!mounted) return;

      if (result != null && !result.containsKey('error')) {
        _showResultDialog(
          title: 'Công thức gợi ý',
          content: result,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['error'] ?? 'Lỗi không xác định'),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMealPlanDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kế hoạch ăn uống'),
        content: const Text('Tạo kế hoạch ăn uống 7 ngày?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _generateMealPlan();
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateMealPlan() async {
    setState(() => _isLoading = true);

    try {
      final result = await AIBackendService.generateMealPlan(
        days: 7,
        dietary: 'normal',
        preferences: ['không cay', 'có cá'],
      );

      if (!mounted) return;

      if (result != null && !result.containsKey('error')) {
        _showResultDialog(
          title: 'Kế hoạch ăn uống',
          content: result,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['error'] ?? 'Lỗi không xác định'),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAnalyzeRecipeDialog() {
    final titleController = TextEditingController();
    final ingredientsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Phân tích công thức'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Tên công thức',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ingredientsController,
              decoration: const InputDecoration(
                hintText: 'Nguyên liệu (cách nhau bằng dấu phẩy)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final ingredients = ingredientsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              _analyzeRecipe(titleController.text, ingredients);
            },
            child: const Text('Phân tích'),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeRecipe(String title, List<String> ingredients) async {
    if (title.isEmpty || ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AIBackendService.analyzeRecipe(
        title: title,
        ingredients: ingredients,
      );

      if (!mounted) return;

      if (result != null && !result.containsKey('error')) {
        _showResultDialog(
          title: 'Phân tích dinh dưỡng',
          content: result,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['error'] ?? 'Lỗi không xác định'),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCookingTipsDialog() {
    final dishController = TextEditingController();
    final problemController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mẹo nấu nướng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dishController,
              decoration: const InputDecoration(
                hintText: 'Tên món ăn',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: problemController,
              decoration: const InputDecoration(
                hintText: 'Vấn đề cần giải quyết',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _getCookingTips(dishController.text, problemController.text);
            },
            child: const Text('Lấy mẹo'),
          ),
        ],
      ),
    );
  }

  Future<void> _getCookingTips(String dish, String problem) async {
    if (dish.isEmpty || problem.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AIBackendService.getCookingTips(
        dish: dish,
        problem: problem,
      );

      if (!mounted) return;

      if (result != null && !result.containsKey('error')) {
        _showResultDialog(
          title: 'Mẹo nấu nướng',
          content: result,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['error'] ?? 'Lỗi không xác định'),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showResultDialog({
    required String title,
    required Map<String, dynamic> content,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._buildContentWidgets(content),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentWidgets(Map<String, dynamic> content) {
    final widgets = <Widget>[];

    content.forEach((key, value) {
      if (value is String) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
            ],
          ),
        );
      } else if (value is List) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              ...(value as List).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text('• $item', style: const TextStyle(fontSize: 13)),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      } else if (value is Map) {
        widgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              ..._buildContentWidgets(value as Map<String, dynamic>),
            ],
          ),
        );
      }
    });

    return widgets;
  }
}
