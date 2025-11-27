class IngredientItem {
  int? id;        // Primary Key
  String name;
  bool isChecked;
  int? recipeId;  // Foreign Key có thể null lúc tạo

  IngredientItem({
    this.id,
    required this.name,
    this.isChecked = false,
    this.recipeId,
  });

  IngredientItem copyWith({
    int? id,
    String? name,
    bool? isChecked,
    int? recipeId,
  }) {
    return IngredientItem(
      id: id ?? this.id,
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
      recipeId: recipeId ?? this.recipeId,
    );
  }

  Map<String, dynamic> toMap({int? recipeIdOverride}) {
    return {
      if (id != null) 'id': id,
      'name': name,
      'isChecked': isChecked ? 1 : 0,
      'recipeId': recipeIdOverride ?? recipeId,
    };
  }

  factory IngredientItem.fromMap(Map<String, dynamic> map) {
    return IngredientItem(
      id: map['id'],
      name: map['name'],
      isChecked: map['isChecked'] == 1,
      recipeId: map['recipeId'],
    );
  }
}
