// lib/main.dart (Cập nhật Theme)
import 'package:flutter/material.dart';
import 'screens/recipe_list_screen.dart'; 
import 'screens/shopping_list_screen.dart'; // Đảm bảo đã import
import 'models/recipe.dart';
import 'helper/database_helper.dart';

void main() {
  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sách Nấu Ăn Flutter',
      theme: ThemeData(
        // Dùng màu sắc nhã nhặn hơn (Ví dụ: Màu Xanh Rêu/Xám ấm)
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF6D9886), // Màu Xanh Rêu
        scaffoldBackgroundColor: const Color(0xFFF6F6F6), // Nền màu xám nhạt
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6D9886),
          foregroundColor: Colors.white,
          elevation: 0,
        )
      ),
      home: const MainAppLayout(), // Dùng layout mới
      debugShowCheckedModeBanner: false,
    );
  }
}

// *** LAYOUT CHÍNH (Bước 2) ***
class MainAppLayout extends StatefulWidget {
  const MainAppLayout({super.key});

  @override
  State<MainAppLayout> createState() => _MainAppLayoutState();
}

class _MainAppLayoutState extends State<MainAppLayout> {
  int _selectedIndex = 0;

  final List<Recipe> _plannedRecipes = [];

  // Danh sách các màn hình
  // final List<Widget> _widgetOptions = <Widget>[
  //   const RecipeListScreen(), // Index 0
  //   ShoppingListScreen(recipes: mockRecipes), // Index 1
  // ];
  List<Recipe> _recipes = []; 
  bool _isLoading = true; // Thêm trạng thái loading

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    // Thay thế dữ liệu giả bằng dữ liệu từ DB
    final loadedRecipes = await DatabaseHelper.instance.readAllRecipes();
  if (loadedRecipes.isEmpty) {
      print('Database trống. Đang thêm dữ liệu mẫu...');
      await _seedDatabase();
      // Tải lại sau khi thêm mẫu
      final seededRecipes = await DatabaseHelper.instance.readAllRecipes();
      setState(() {
        _recipes = seededRecipes;
        _isLoading = false;
      });
    } else {
      // Dữ liệu đã có, chỉ cần cập nhật trạng thái
      setState(() {
        _recipes = loadedRecipes;
        _isLoading = false;
      });
    }
  }
  Future<void> _seedDatabase() async {
    // Sử dụng mockRecipes (từ lib/models/recipe.dart)
    for (var recipe in mockRecipes) {
      // Lưu từng công thức vào DB
      await DatabaseHelper.instance.createRecipe(recipe);
    }
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Đóng drawer sau khi chọn (chỉ đóng trên mobile)
    Navigator.of(context).pop(); 
  }

  void _addRecipeToPlan(Recipe recipe) {
    // Kiểm tra trùng lặp trước khi thêm
    if (!_plannedRecipes.contains(recipe)) {
      setState(() {
        _plannedRecipes.add(recipe);
      });
    }
  }

  void _reloadRecipes() {
    setState(() {
      _isLoading = true; // Set loading để hiển thị chỉ báo
      // Cần xóa các công thức đã lên kế hoạch để tránh lỗi ID khi reload
      _plannedRecipes.clear(); 
    });
    // Gọi lại hàm load chính
    _loadRecipes(); 
  }

// void _removeRecipeFromPlan(Recipe recipe) {
//     setState(() {
//       _plannedRecipes.remove(recipe);
//     });
//   }

  @override
  Widget build(BuildContext context) {
    // Scaffold sẽ bao bọc toàn bộ
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF6D9886)),
              SizedBox(height: 16),
              Text('Đang tải công thức từ Database...', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }
    final List<Widget> _widgetOptions = <Widget>[
      // Truyền hàm callback xuống RecipeListScreen để nó tiếp tục truyền xuống màn hình chi tiết
      RecipeListScreen(
        recipes: _recipes, 
        onPlanAdded: _addRecipeToPlan,
        onRecipeAdded: _reloadRecipes, // TRUYỀN CALLBACK RELOAD
      ),
      ShoppingListScreen(
        recipes: _plannedRecipes,
        // onPlanRemoved: _removeRecipeFromPlan,
      ),
    ];
    return Scaffold(
      // Thanh bar trái (Drawer)
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // Header của Drawer
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF6D9886),
              ),
              child: Text(
                'Menu Nấu Ăn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Các mục điều hướng
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFF6D9886)),
              title: const Text('Danh sách Công thức'),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Color(0xFF6D9886)),
              title: const Text('Kế hoạch Mua sắm'),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text('Cài đặt'),
              onTap: () {
                 Navigator.of(context).pop(); // Đóng Drawer
                 // Logic chuyển sang màn hình Cài đặt (nếu có)
              },
            ),
          ],
        ),
      ),
      
      // Nội dung màn hình chính
      // Sử dụng `_widgetOptions` để hiển thị màn hình đã chọn
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }
}