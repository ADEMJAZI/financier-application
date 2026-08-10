class RecipeIngredient {
  final String rawMaterialId;
  final String rawMaterialName;
  final String unit;
  final double quantityRequired;
  final double currentStock;

  RecipeIngredient({
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.unit,
    required this.quantityRequired,
    required this.currentStock,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      rawMaterialId: json['rawMaterial'] is String 
          ? json['rawMaterial'] as String
          : (json['rawMaterial'] as Map<String, dynamic>)['_id'] as String,
      rawMaterialName: json['rawMaterial'] is String
          ? json['rawMaterialName'] as String? ?? 'Unknown'
          : (json['rawMaterial'] as Map<String, dynamic>)['name'] as String,
      unit: json['rawMaterial'] is String
          ? json['unit'] as String? ?? 'unit'
          : (json['rawMaterial'] as Map<String, dynamic>)['unit'] as String,
      quantityRequired: (json['quantityRequired'] as num).toDouble(),
      currentStock: json['rawMaterial'] is String
          ? json['currentStock'] as double? ?? 0
          : (json['rawMaterial'] as Map<String, dynamic>)['quantity'] as double? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rawMaterial': rawMaterialId,
      'quantityRequired': quantityRequired,
    };
  }

  @override
  String toString() {
    return 'RecipeIngredient(id: $rawMaterialId, name: $rawMaterialName, required: $quantityRequired $unit)';
  }
}

class MenuItem {
  final String id;
  final String business;
  final String name;
  final double sellingPrice;
  final List<RecipeIngredient> recipe;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem({
    required this.id,
    required this.business,
    required this.name,
    required this.sellingPrice,
    this.recipe = const [],
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final recipeJson = json['recipe'] as List<dynamic>? ?? [];
    
    return MenuItem(
      id: json['_id'] as String,
      business: json['business'] as String,
      name: json['name'] as String,
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      recipe: recipeJson.map((item) => RecipeIngredient.fromJson(item as Map<String, dynamic>)).toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'business': business,
      'name': name,
      'sellingPrice': sellingPrice,
      'recipe': recipe.map((ingredient) => ingredient.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MenuItem copyWith({
    String? id,
    String? business,
    String? name,
    double? sellingPrice,
    List<RecipeIngredient>? recipe,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      business: business ?? this.business,
      name: name ?? this.name,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      recipe: recipe ?? this.recipe,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'MenuItem(id: $id, name: $name, sellingPrice: $sellingPrice, recipe: ${recipe.length} ingredients, isActive: $isActive)';
  }
}