import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../providers/group_providers.dart';
import '../../models/group_expense.dart';

import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/providers/transaction_provider.dart';

class AddGroupExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? initialTitle;
  final String? initialAmount;
  final String? initialCategory;

  const AddGroupExpenseScreen({
    super.key,
    required this.groupId,
    this.initialTitle,
    this.initialAmount,
    this.initialCategory,
  });

  @override
  ConsumerState<AddGroupExpenseScreen> createState() => _AddGroupExpenseScreenState();
}

class _AddGroupExpenseScreenState extends ConsumerState<AddGroupExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedPayer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTitle != null) _titleController.text = widget.initialTitle!;
    if (widget.initialAmount != null) _amountController.text = widget.initialAmount!;
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submit(List<String> members, String groupName) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_selectedPayer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select who paid')));
      return;
    }

    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null || currentUser.email == null) return;

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      final title = _titleController.text.trim();
      final expenseId = const Uuid().v4();

      final expense = GroupExpense(
        id: expenseId,
        groupId: widget.groupId,
        title: title,
        amount: amount,
        category: _selectedCategory!,
        paidBy: _selectedPayer!,
        participants: members,
        createdAt: DateTime.now(),
      );

      await ref.read(groupServiceProvider).addExpense(widget.groupId, expense);

      // Add to personal transactions if current user paid
      if (_selectedPayer == currentUser.email) {
        // We use dynamic access here to safely access generic user id fields
        final dynamic dynUser = currentUser;
        final personalTx = TransactionEntity(
          id: expenseId,
          userId: dynUser.id,
          amount: amount,
          type: TransactionType.expense,
          category: _selectedCategory!,
          note: '$title - $groupName',
          date: DateTime.now(),
          createdAt: DateTime.now(),
        );

        await ref.read(transactionControllerProvider.notifier).addTransaction(personalTx);
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupDetailsProvider(widget.groupId));
    final categories = ref.watch(expenseCategoriesProvider);
    final currentUser = ref.watch(authStateProvider).value?.email;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Group Expense')),
      body: groupAsync.when(
        data: (group) {
          if (group == null) return const Center(child: Text('Group not found'));

          if (_selectedPayer == null && currentUser != null && group.members.contains(currentUser)) {
            _selectedPayer = currentUser;
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Expense Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (KES)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Enter amount';
                    if (double.tryParse(val) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: categories.contains(_selectedCategory) ? _selectedCategory : null,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedPayer,
                  decoration: const InputDecoration(
                    labelText: 'Paid By',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: group.members.map((member) {
                    return DropdownMenuItem(
                      value: member,
                      child: Text(member == currentUser ? 'You ($member)' : member),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedPayer = val),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Expense will be split equally among all ${group.members.length} members.',
                          style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _submit(group.members, group.name),
                    child: _isLoading 
                      ? const CircularProgressIndicator() 
                      : const Text('Save Expense', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
