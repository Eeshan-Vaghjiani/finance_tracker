import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:finance_tracker/features/sms_parsing/presentation/providers/sms_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Builder(
                builder: (context) {
                  final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
                  return CircleAvatar(
                    radius: 48,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: photoUrl == null ? const Icon(Icons.person, size: 48) : null,
                  );
                }
              ),
              const SizedBox(height: 24),
              Text(
                user?.name ?? 'Unknown User',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'No email',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
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
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              
              Consumer(builder: (context, ref, child) {
                final syncState = ref.watch(syncMpesaProvider);

                ref.listen<AsyncValue<int>>(
                  syncMpesaProvider,
                  (_, state) {
                    state.whenOrNull(
                      data: (count) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Synced $count new transactions')),
                        );
                      },
                      error: (err, _) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sync Error: $err')),
                        );
                      },
                    );
                  },
                );

                return ElevatedButton.icon(
                  onPressed: syncState.isLoading
                      ? null
                      : () => ref.read(syncMpesaProvider.notifier).syncMessages(),
                  icon: syncState.isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync),
                  label: const Text('Sync M-Pesa SMS'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                );
              }),
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
}
