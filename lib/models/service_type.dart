/// نوع سرویس — برای گسترش آینده (مثلاً بردگیم)
enum ServiceType {
  gaming('بازی ویدیویی', 'gaming'),
  cafe('کافه', 'cafe'),
  boardGame('بردگیم', 'board_game');

  const ServiceType(this.label, this.id);

  final String label;
  final String id;

  static ServiceType fromId(String id) {
    return ServiceType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => ServiceType.gaming,
    );
  }
}
