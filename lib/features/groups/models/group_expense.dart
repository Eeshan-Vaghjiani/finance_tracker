import 'package:cloud_firestore/cloud_firestore.dart';

class GroupExpense {
  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String category;
  final String paidBy; // user email
  final List<String> participants; // emails
  final DateTime createdAt;

  GroupExpense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.category,
    required this.paidBy,
    required this.participants,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'title': title,
      'amount': amount,
      'category': category,
      'paidBy': paidBy,
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory GroupExpense.fromMap(Map<String, dynamic> map, String id) {
    return GroupExpense(
      id: id,
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      paidBy: map['paidBy'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
