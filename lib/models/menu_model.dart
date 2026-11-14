class MenuModel {
  final String id;
  final String name;
  final String category; // 'Makanan', 'Minuman', 'Snack'
  final double price;
  final String imageUrl;
  final String? description;
  final bool isAvailable;

  MenuModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    this.description,
    this.isAvailable = true,
  });

  MenuModel copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    String? imageUrl,
    String? description,
    bool? isAvailable,
  }) {
    return MenuModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  factory MenuModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return MenuModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? 'Makanan',
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'],
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'isAvailable': isAvailable,
    };
  }
}
