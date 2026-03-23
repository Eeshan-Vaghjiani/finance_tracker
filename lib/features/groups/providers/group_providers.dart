import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../services/group_service.dart';
import '../models/group.dart';
import '../models/group_expense.dart';
import '../models/settlement.dart';

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService();
});

final userGroupsProvider = StreamProvider<List<Group>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null || user.email == null || user.email!.isEmpty) {
    return const Stream.empty();
  }
  
  final groupService = ref.watch(groupServiceProvider);
  return groupService.getUserGroups(user.email!);
});

final groupDetailsProvider = Provider.family<AsyncValue<Group?>, String>((ref, groupId) {
  final groupsAsync = ref.watch(userGroupsProvider);
  return groupsAsync.whenData((groups) {
    try {
      return groups.firstWhere((g) => g.id == groupId);
    } catch (_) {
      return null;
    }
  });
});

final groupExpensesProvider = StreamProvider.family<List<GroupExpense>, String>((ref, groupId) {
  final groupService = ref.watch(groupServiceProvider);
  return groupService.getGroupExpenses(groupId);
});

final groupSettlementsProvider = Provider.family<AsyncValue<List<Settlement>>, String>((ref, groupId) {
  final groupAsync = ref.watch(groupDetailsProvider(groupId));
  final expensesAsync = ref.watch(groupExpensesProvider(groupId));

  if (groupAsync.isLoading || expensesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (groupAsync.hasError) return AsyncValue.error(groupAsync.error!, groupAsync.stackTrace!);
  if (expensesAsync.hasError) return AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);

  final group = groupAsync.value;
  final expenses = expensesAsync.value;

  if (group == null || expenses == null) {
    return const AsyncValue.data([]);
  }

  final groupService = ref.watch(groupServiceProvider);
  final settlements = groupService.calculateSettlements(expenses, group.members);
  
  return AsyncValue.data(settlements);
});
