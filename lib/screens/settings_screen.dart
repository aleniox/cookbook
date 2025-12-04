import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final bool initialUseGrid;
  final int initialGridCrossAxisCount;
  const SettingsScreen({
    super.key,
    required this.initialUseGrid,
    required this.initialGridCrossAxisCount,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _useGrid;
  late int _gridCrossAxisCount;

  @override
  void initState() {
    super.initState();
    _useGrid = widget.initialUseGrid;
    _gridCrossAxisCount = widget.initialGridCrossAxisCount;
  }

  Future<void> _saveUseGrid(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useGrid', value);
  }

  Future<void> _saveGridCount(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('gridCrossAxisCount', value);
  }

  void _closeWithResult() {
    Navigator.of(
      context,
    ).pop({'useGrid': _useGrid, 'gridCrossAxisCount': _gridCrossAxisCount});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _closeWithResult,
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Hiển thị dạng lưới'),
            subtitle: const Text('Hiển thị các công thức theo dạng lưới'),
            value: _useGrid,
            onChanged: (v) {
              setState(() => _useGrid = v);
              _saveUseGrid(v);
            },
          ),
          ListTile(
            title: const Text('Số cột lưới'),
            subtitle: const Text('Chọn số lượng cột khi hiển thị dạng lưới'),
            trailing: Wrap(
              spacing: 8,
              children: [1, 2, 3, 4].map((count) {
                final selected = _gridCrossAxisCount == count;
                return ChoiceChip(
                  label: Text('$count'),
                  selected: selected,
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                  onSelected: (isSelected) {
                    if (!isSelected) return;
                    setState(() => _gridCrossAxisCount = count);
                    _saveGridCount(count);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _closeWithResult,
        icon: const Icon(Icons.check),
        label: const Text('Lưu & Đóng'),
      ),
    );
  }
}
