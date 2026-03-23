import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../providers/group_providers.dart';

class GroupDetailsScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailsProvider(groupId));
    final expensesAsync = ref.watch(groupExpensesProvider(groupId));
    final settlementsAsync = ref.watch(groupSettlementsProvider(groupId));
    final currentUser = ref.watch(authStateProvider).value?.email;

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          data: (group) => Text(group?.name ?? 'Group Details'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
      ),
      body: groupAsync.when(
        data: (group) {
          if (group == null) return const Center(child: Text('Group not found'));

          return RefreshIndicator(
            onRefresh: () async {
              // Riverpod streams update automatically 
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // MEMBERS SECTION
                Text(
                  'Members',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: group.members.length,
                    itemBuilder: (context, index) {
                      final memberEmail = group.members[index];
                      final isMe = memberEmail == currentUser;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Chip(
                          side: BorderSide.none,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          avatar: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              memberEmail[0].toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          label: Text(isMe ? 'You' : memberEmail),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // BALANCE SUMMARY
                Text(
                  'Balance Summary',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                settlementsAsync.when(
                  data: (settlements) {
                    if (settlements.isEmpty) {
                      return const Card(
                        elevation: 1,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Everyone is settled up!'),
                        ),
                      );
                    }

                    // Filter settlements involving the current user
                    final userSettlements = settlements.where(
                      (s) => s.fromUser == currentUser || s.toUser == currentUser
                    ).toList();

                    if (currentUser == null || userSettlements.isEmpty) {
                      return const Card(
                        elevation: 1,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('You are settled up!'),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: userSettlements.map((s) {
                        final isOwed = s.toUser == currentUser;
                        final otherPerson = isOwed ? s.fromUser : s.toUser;
                        final amount = s.amount.toStringAsFixed(2);
                        
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isOwed
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isOwed ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isOwed ? Colors.green : Colors.red,
                              ),
                            ),
                            title: Text(
                              isOwed 
                                ? '$otherPerson owes you KES $amount'
                                : 'You owe $otherPerson KES $amount'
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error calculating balances: $err'),
                ),
                const SizedBox(height: 24),

                // EXPENSE LIST
                Text(
                  'Expenses',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                expensesAsync.when(
                  data: (expenses) {
                    if (expenses.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No expenses yet. Tap "Add Expense" to start!'),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenses[index];
                        final isYouPaid = expense.paidBy == currentUser;
                        
                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.receipt_outlined,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            title: Text(
                              expense.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${DateFormat.yMMMd().format(expense.createdAt)} • ${expense.category}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'KES ${expense.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isYouPaid ? 'You paid' : '${expense.paidBy} paid',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isYouPaid ? FontWeight.bold : FontWeight.normal,
                                    color: isYouPaid ? theme.colorScheme.primary : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading expenses: $err'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading group: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/groups/$groupId/add-expense'),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}
