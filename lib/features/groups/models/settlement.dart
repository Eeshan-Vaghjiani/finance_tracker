class Settlement {
  final String fromUser; // email of the user who owes
  final String toUser;   // email of the user who is owed
  final double amount;

  Settlement({
    required this.fromUser,
    required this.toUser,
    required this.amount,
  });

  @override
  String toString() {
    return '$fromUser pays $toUser: $amount';
  }
}
