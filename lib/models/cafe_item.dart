class CafeItem {
  const CafeItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.isActive = true,
  });

  final String id;
  final String name;
  final int price;
  final String category;
  final bool isActive;

  CafeItem copyWith({
    String? name,
    int? price,
    String? category,
    bool? isActive,
  }) {
    return CafeItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'category': category,
        'is_active': isActive ? 1 : 0,
      };

  factory CafeItem.fromMap(Map<String, dynamic> map) => CafeItem(
        id: map['id'] as String,
        name: map['name'] as String,
        price: map['price'] as int,
        category: map['category'] as String,
        isActive: (map['is_active'] as int) == 1,
      );
}
