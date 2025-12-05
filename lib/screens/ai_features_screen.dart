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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status card
            Card(
              color: _isConnected
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.check_circle : Icons.error_outline,
                      color: _isConnected ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isConnected ? 'Kết nối thành công' : 'Chưa kết nối',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _isConnected
                                ? 'Backend AI sẵn sàng'
                                : 'Vui lòng chạy backend Python',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Feature tiles
            if (_isConnected) ...[
              _buildFeatureTile(
                icon: Icons.lightbulb,
                title: 'Gợi ý công thức',
                subtitle: 'AI gợi ý công thức từ nguyên liệu bạn có',
                onTap: () => _showSuggestRecipeDialog(),
              ),
              const SizedBox(height: 12),
              _buildFeatureTile(
                icon: Icons.calendar_today,
                title: 'Kế hoạch ăn uống',
                subtitle: 'Tạo kế hoạch ăn uống hàng tuần từ AI',
                onTap: () => _showMealPlanDialog(),
              ),
              const SizedBox(height: 12),
              _buildFeatureTile(
                icon: Icons.restaurant_menu,
                title: 'Phân tích dinh dưỡng',
                subtitle: 'AI phân tích thông tin dinh dưỡng công thức',
                onTap: () => _showAnalyzeRecipeDialog(),
              ),
              const SizedBox(height: 12),
              _buildFeatureTile(
                icon: Icons.local_fire_department,
                title: 'Mẹo nấu nướng',
                subtitle: 'Lấy mẹo nấu nướng từ AI',
                onTap: () => _showCookingTipsDialog(),
              ),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Backend chưa kết nối',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Vui lòng chạy:\npython -m flask run\ntrong thư mục python_backend/',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkConnection,
                        child: const Text('Kiểm tra lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
