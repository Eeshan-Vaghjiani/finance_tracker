enum TransactionType { income, expense }

class TransactionEntity {
  final String id;
  final String userId;
  final double amount;
  final TransactionType type;
  final String category;
  final String note;
  final DateTime date;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    this.note = '',
    required this.date,
    required this.createdAt,
  });

  TransactionEntity copyWith({
    String? id,
    String? userId,
    double? amount,
    TransactionType? type,
    String? category,
    String? note,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
