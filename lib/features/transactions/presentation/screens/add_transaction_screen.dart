import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/transaction_provider.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _customCategoryController = TextEditingController();
  
  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Food';

  @override
  void initState() {
    super.initState();
    // Default categories will be overwritten by provider on first build, but keep sensible defaults
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == 'Other' && _customCategoryController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a custom category name.')),
        );
        return;
      }

      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final finalCategory = _selectedCategory == 'Other' 
          ? _customCategoryController.text.trim() 
          : _selectedCategory;

      final transaction = TransactionEntity(
        id: const Uuid().v4(), // Temporary ID, Firestore will override
        userId: user.id,
        amount: double.parse(_amountController.text),
        type: _selectedType,
        category: finalCategory,
        note: _noteController.text.trim(),
        date: _selectedDate,
        createdAt: DateTime.now(),
      );

      ref.read(transactionControllerProvider.notifier).addTransaction(transaction).then((_) {
        // ignore: use_build_context_synchronously
        if (mounted) context.pop();
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionControllerProvider);
    final incomeCategories = ref.watch(incomeCategoriesProvider);
    final expenseCategories = ref.watch(expenseCategoriesProvider);

    final currentCategories = _selectedType == TransactionType.income ? incomeCategories : expenseCategories;
    
    // Safety check: Ensure the selected category exists in the list currently being shown
    if (!currentCategories.contains(_selectedCategory)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
               _selectedCategory = currentCategories.first;
            });
        });
    }

    ref.listen<AsyncValue<void>>(
      transactionControllerProvider,
      (_, state) {
        state.whenOrNull(
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.toString())),
            );
          },
        );
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = TransactionType.income;
                              _selectedCategory = incomeCategories.first;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedType == TransactionType.income ? AppColors.income : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Income',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedType == TransactionType.income ? Colors.white : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = TransactionType.expense;
                              _selectedCategory = expenseCategories.first;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedType == TransactionType.expense ? AppColors.expense : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Expense',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _selectedType == TransactionType.expense ? Colors.white : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Amount
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter amount';
                    if (double.tryParse(value) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Category
                DropdownButtonFormField<String>(
                  value: currentCategories.contains(_selectedCategory) ? _selectedCategory : currentCategories.first,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: currentCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCategory = val;
                        if (val != 'Other') {
                           _customCategoryController.clear();
                        }
                      });
                    }
                  },
                ),
                if (_selectedCategory == 'Other') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customCategoryController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Category Name',
                      hintText: 'e.g., Gym Membership',
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
                const SizedBox(height: 24),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(DateFormat.yMMMd().format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Note
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(labelText: 'Note (Optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 48),

                // Submit
                ElevatedButton(
                  onPressed: txState.isLoading ? null : _submit,
                  child: txState.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Transaction'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
