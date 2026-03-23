import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:finance_tracker/features/sms_parsing/presentation/providers/sms_provider.dart';
import 'package:finance_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:finance_tracker/features/groups/providers/group_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Builder(
                  builder: (context) {
                    String? photoUrl =
                        FirebaseAuth.instance.currentUser?.photoURL;

                    // Google profile pictures default to 96x96. We bump it to 400x400 for sharpness.
                    if (photoUrl != null && photoUrl.contains('=s96-c')) {
                      photoUrl = photoUrl.replaceAll('=s96-c', '=s400-c');
                    }

                    if (photoUrl != null) {
                      return Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: Image.network(
                            photoUrl,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  child: const Icon(Icons.person, size: 48),
                                ),
                          ),
                        ),
                      );
                    }

                    return CircleAvatar(
                      radius: 48,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: const Icon(Icons.person, size: 48),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                user?.name ?? 'Unknown User',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'No email',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              ElevatedButton.icon(
                onPressed: () {
                  context.push('/settings');
                },
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),

              Consumer(
                builder: (context, ref, child) {
                  final syncState = ref.watch(syncMpesaProvider);

                  ref.listen<AsyncValue<List<TransactionEntity>>>(syncMpesaProvider, (_, state) {
                    state.whenOrNull(
                      data: (transactions) {
                        final count = transactions.length;
                        if (count == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No new transactions')),
                          );
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Synced $count new M-Pesa transactions'),
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'Add to Group',
                              onPressed: () {
                                final latestTx = transactions.first;
                                _showGroupSelectionSheet(context, ref, latestTx);
                              },
                            ),
                          ),
                        );
                      },
                      error: (err, _) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sync Error: $err')),
                        );
                      },
                    );
                  });

                  return ElevatedButton.icon(
                    onPressed: syncState.isLoading
                        ? null
                        : () => ref
                              .read(syncMpesaProvider.notifier)
                              .syncMessages(),
                    icon: syncState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: const Text('Sync M-Pesa SMS'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroupSelectionSheet(BuildContext context, WidgetRef ref, TransactionEntity tx) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final groupsAsync = ref.watch(userGroupsProvider);
            return groupsAsync.when(
              data: (groups) {
                if (groups.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('You have no groups yet.'),
                  );
                }

                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Select Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      ...groups.map((group) {
                        return ListTile(
                          title: Text(group.name),
                          onTap: () {
                            Navigator.pop(ctx);
                            context.push(
                              Uri(
                                path: '/groups/${group.id}/add-expense',
                                queryParameters: {
                                  'title': tx.category,
                                  'amount': tx.amount.toString(),
                                  'category': tx.category,
                                },
                              ).toString(),
                            );
                          },
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())),
              error: (err, _) => Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Error: $err'))),
            );
          },
        );
      },
    );
  }
}
