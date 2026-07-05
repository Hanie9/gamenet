class CafeOrder {
  const CafeOrder({
    required this.id,
    required this.sessionId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String itemId;
  final String itemName;
  final int quantity;
  final int unitPrice;
  final DateTime createdAt;

  int get totalPrice => unitPrice * quantity;

  CafeOrder copyWith({int? quantity}) {
    return CafeOrder(
      id: id,
      sessionId: sessionId,
      itemId: itemId,
      itemName: itemName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'item_id': itemId,
        'item_name': itemName,
        'quantity': quantity,
        'unit_price': unitPrice,
        'created_at': createdAt.toIso8601String(),
      };

  factory CafeOrder.fromMap(Map<String, dynamic> map) => CafeOrder(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        itemId: map['item_id'] as String,
        itemName: map['item_name'] as String,
        quantity: map['quantity'] as int,
        unitPrice: map['unit_price'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
