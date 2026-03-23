import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';
import '../models/group_expense.dart';
import '../models/settlement.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createGroup(Group group) async {
    final docRef = await _firestore.collection('groups').add(group.toMap());
    return docRef.id;
  }

  Stream<List<Group>> getUserGroups(String userEmail) {
    return _firestore
        .collection('groups')
        .where('members', arrayContains: userEmail)
        .snapshots()
        .map((snapshot) {
      final groups = snapshot.docs.map((doc) => Group.fromMap(doc.data(), doc.id)).toList();
      groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return groups;
    });
  }

  Stream<List<GroupExpense>> getGroupExpenses(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GroupExpense.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> addExpense(String groupId, GroupExpense expense) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('expenses')
        .doc(expense.id) // Use the pre-generated ID
        .set(expense.toMap());
  }

  List<Settlement> calculateSettlements(List<GroupExpense> expenses, List<String> members) {
    Map<String, double> balances = {for (var member in members) member: 0.0};

    for (var expense in expenses) {
      if (expense.participants.isEmpty) continue;
      
      double splitAmount = expense.amount / expense.participants.length;

      balances[expense.paidBy] = (balances[expense.paidBy] ?? 0.0) + expense.amount;

      for (var participant in expense.participants) {
        balances[participant] = (balances[participant] ?? 0.0) - splitAmount;
      }
    }

    List<Settlement> settlements = [];
    
    List<MapEntry<String, double>> debtors = balances.entries.where((e) => e.value < -0.01).toList();
    List<MapEntry<String, double>> creditors = balances.entries.where((e) => e.value > 0.01).toList();

    debtors.sort((a, b) => a.value.compareTo(b.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    int d = 0;
    int c = 0;

    while (d < debtors.length && c < creditors.length) {
      String debtor = debtors[d].key;
      double debtAmount = -debtors[d].value;

      String creditor = creditors[c].key;
      double creditAmount = creditors[c].value;

      double settlementAmount = debtAmount < creditAmount ? debtAmount : creditAmount;

      settlements.add(Settlement(
        fromUser: debtor,
        toUser: creditor,
        amount: settlementAmount,
      ));

      debtors[d] = MapEntry(debtor, debtors[d].value + settlementAmount);
      creditors[c] = MapEntry(creditor, creditors[c].value - settlementAmount);

      if (debtors[d].value > -0.01) d++;
      if (creditors[c].value < 0.01) c++;
    }

    return settlements;
  }
}
