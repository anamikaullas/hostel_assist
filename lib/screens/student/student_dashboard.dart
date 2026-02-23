import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/index.dart';
import '../../providers/index.dart';
import '../../utils/index.dart';
import 'add_complaint_screen.dart';
import 'chatbot_screen.dart';
import 'complaint_detail_screen.dart';

/// Student dashboard with bottom navigation
class StudentDashboard extends ConsumerStatefulWidget {
  final UserModel user;

  const StudentDashboard({super.key, required this.user});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(loginProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(user: widget.user),
          _ComplaintsTab(user: widget.user),
          _FeesTab(user: widget.user),
          _MessTab(user: widget.user),
          _ChatTab(user: widget.user),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.report_problem),
            label: 'Complaints',
          ),
          NavigationDestination(icon: Icon(Icons.payment), label: 'Fees'),
          NavigationDestination(icon: Icon(Icons.restaurant), label: 'Mess'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
        ],
      ),
    );
  }
}

/// Home tab showing overview
class _HomeTab extends ConsumerWidget {
  final UserModel user;

  const _HomeTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomByStudentIdProvider(user.uid));
    final complaintsAsync = ref.watch(complaintsByStudentProvider(user.uid));
    final feesAsync = ref.watch(pendingFeesByStudentProvider(user.uid));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user.fullName}!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enrollment: ${user.enrollmentId}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Year: ${user.year}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick stats
          Text('Quick Stats', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),

          // Room info
          roomAsync.when(
            data: (room) {
              if (room == null) {
                return const Card(
                  child: ListTile(
                    leading: Icon(Icons.room, color: Colors.orange),
                    title: Text('Room Not Assigned'),
                    subtitle: Text('Contact admin for allocation'),
                  ),
                );
              }
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.room, color: Colors.green),
                  title: Text('Room: ${room.roomNumber}'),
                  subtitle: Text(
                    'Block ${room.blockName}, Floor ${room.floorNumber}',
                  ),
                ),
              );
            },
            loading: () => const Card(
              child: ListTile(
                leading: CircularProgressIndicator(),
                title: Text('Loading room info...'),
              ),
            ),
            error: (error, stack) => Card(
              child: ListTile(
                leading: const Icon(Icons.error, color: Colors.red),
                title: const Text('Error loading room'),
                subtitle: Text(error.toString()),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Complaints summary
          complaintsAsync.when(
            data: (complaints) {
              final pending = complaints.where((c) => c.isOpen).length;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.report_problem, color: Colors.blue),
                  title: Text('Complaints: ${complaints.length}'),
                  subtitle: Text('$pending pending'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Switch to complaints tab
                    // This would be handled by the parent widget
                  },
                ),
              );
            },
            loading: () => const Card(
              child: ListTile(
                leading: CircularProgressIndicator(),
                title: Text('Loading complaints...'),
              ),
            ),
            error: (error, stack) => const Card(
              child: ListTile(
                leading: Icon(Icons.error, color: Colors.red),
                title: Text('Error loading complaints'),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Fees summary
          feesAsync.when(
            data: (fees) {
              final total = fees.fold<double>(
                0,
                (sum, fee) => sum + fee.amount,
              );
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.payment, color: Colors.red),
                  title: Text('Pending Fees: ${fees.length}'),
                  subtitle: Text('Total: ${total.toCurrency}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                ),
              );
            },
            loading: () => const Card(
              child: ListTile(
                leading: CircularProgressIndicator(),
                title: Text('Loading fees...'),
              ),
            ),
            error: (error, stack) => const Card(
              child: ListTile(
                leading: Icon(Icons.error, color: Colors.red),
                title: Text('Error loading fees'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Complaints tab with add complaint functionality
class _ComplaintsTab extends ConsumerWidget {
  final UserModel user;

  const _ComplaintsTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(complaintsByStudentProvider(user.uid));

    return Scaffold(
      body: complaintsAsync.when(
        data: (complaints) {
          if (complaints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No complaints',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('You have not submitted any complaints yet'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddComplaintScreen(user: user),
                        ),
                      );
                      if (result == true) {
                        ref.invalidate(complaintsByStudentProvider(user.uid));
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Submit Complaint'),
                  ),
                ],
              ),
            );
          }

          // Sort complaints by date (newest first)
          final sortedComplaints = complaints.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedComplaints.length,
            itemBuilder: (context, index) {
              final complaint = sortedComplaints[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ComplaintDetailScreen(complaint: complaint),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: complaint.isHighPriority
                        ? Colors.red.shade100
                        : Colors.orange.shade100,
                    child: Icon(
                      Icons.report_problem,
                      color: complaint.isHighPriority
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                  title: Text(
                    complaint.category.toTitleCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        complaint.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              complaint.status.toUpperCase(),
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: _getStatusColor(complaint.status),
                            labelStyle: const TextStyle(color: Colors.white),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            complaint.createdAt.relativeTime,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error: ${error.toString()}')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => AddComplaintScreen(user: user),
            ),
          );
          if (result == true) {
            ref.invalidate(complaintsByStudentProvider(user.uid));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Complaint'),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

/// Fees tab
class _FeesTab extends ConsumerWidget {
  final UserModel user;

  const _FeesTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(feesByStudentProvider(user.uid));

    return feesAsync.when(
      data: (fees) {
        if (fees.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No fees', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: fees.length,
          itemBuilder: (context, index) {
            final fee = fees[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  Icons.payment,
                  color: fee.isPaid ? Colors.green : Colors.red,
                ),
                title: Text(fee.feeType.replaceAll('_', ' ').toTitleCase()),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount: ${fee.amount.toCurrency}'),
                    Text('Due: ${fee.dueDate.formatted}'),
                    Text('Status: ${fee.status}'),
                  ],
                ),
                trailing: Chip(
                  label: Text(fee.status),
                  backgroundColor: fee.isPaid ? Colors.green : Colors.red,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error: ${error.toString()}')),
    );
  }
}

/// Mess tab
class _MessTab extends ConsumerWidget {
  final UserModel user;

  const _MessTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(todayMenuProvider);

    return menuAsync.when(
      data: (menu) {
        if (menu == null) {
          return const Center(child: Text('Today\'s menu not available'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Menu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                menu.date.formatted,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              _buildMealSection(context, 'Breakfast', menu.breakfast),
              const SizedBox(height: 16),
              _buildMealSection(context, 'Lunch', menu.lunch),
              const SizedBox(height: 16),
              _buildMealSection(context, 'Dinner', menu.dinner),

              if (menu.remarks != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Remarks',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(menu.remarks!),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error: ${error.toString()}')),
    );
  }

  Widget _buildMealSection(
    BuildContext context,
    String mealName,
    List<String> items,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mealName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8),
                    const SizedBox(width: 8),
                    Text(item),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat tab with full Gemini AI integration
class _ChatTab extends ConsumerWidget {
  final UserModel user;

  const _ChatTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChatbotScreen(user: user);
  }
}
