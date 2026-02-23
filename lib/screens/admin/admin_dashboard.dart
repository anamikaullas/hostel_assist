import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/index.dart';
import '../../providers/index.dart';
import '../../utils/index.dart';

/// Admin dashboard with tabs
class AdminDashboard extends ConsumerStatefulWidget {
  final UserModel user;

  const AdminDashboard({super.key, required this.user});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(loginProvider.notifier).logout();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.report_problem), text: 'Complaints'),
            Tab(icon: Icon(Icons.payment), text: 'Fees'),
            Tab(icon: Icon(Icons.room), text: 'Rooms'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(user: widget.user),
          _ComplaintsTab(),
          _FeesTab(),
          _RoomsTab(),
        ],
      ),
    );
  }
}

/// Overview tab showing statistics
class _OverviewTab extends ConsumerWidget {
  final UserModel user;

  const _OverviewTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintStatsAsync = ref.watch(complaintStatisticsProvider);
    final feeStatsAsync = ref.watch(feeStatisticsProvider);

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
                  const Text('Admin Dashboard'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Complaint statistics
          Text(
            'Complaint Statistics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          complaintStatsAsync.when(
            data: (stats) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total',
                          value: '${stats['total']}',
                          icon: Icons.report,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: 'Pending',
                          value: '${stats['pending']}',
                          icon: Icons.pending,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'In Progress',
                          value: '${stats['inProgress']}',
                          icon: Icons.hourglass_empty,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: 'Resolved',
                          value: '${stats['resolved']}',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Error: ${error.toString()}'),
          ),
          const SizedBox(height: 24),

          // Fee statistics
          Text('Fee Statistics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),

          feeStatsAsync.when(
            data: (stats) {
              final collectionRate = stats['collectionRate'] as double;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Amount',
                          value: (stats['totalAmount'] as double).toCurrency,
                          icon: Icons.account_balance,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: 'Collected',
                          value: (stats['paidAmount'] as double).toCurrency,
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Pending',
                          value: (stats['pendingAmount'] as double).toCurrency,
                          icon: Icons.pending,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          title: 'Collection Rate',
                          value: '${collectionRate.toStringAsFixed(1)}%',
                          icon: Icons.trending_up,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text('Error: ${error.toString()}'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Complaints management tab
class _ComplaintsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(allComplaintsProvider(null));

    return complaintsAsync.when(
      data: (complaints) {
        if (complaints.isEmpty) {
          return const Center(child: Text('No complaints'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (context, index) {
            final complaint = complaints[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  Icons.report_problem,
                  color: complaint.isHighPriority ? Colors.red : Colors.orange,
                ),
                title: Text('${complaint.studentName} - ${complaint.category}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: ${complaint.status} • Priority: ${complaint.priority}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (complaint.determinedCategory != null)
                      Text(
                        'AI Category: ${complaint.determinedCategory}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                trailing: Text(complaint.createdAt.relativeTime),
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

/// Fees management tab
class _FeesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feesAsync = ref.watch(allFeesProvider(null));

    return feesAsync.when(
      data: (fees) {
        if (fees.isEmpty) {
          return const Center(child: Text('No fees'));
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
                title: Text(
                  '${fee.studentName} - ${fee.feeType.replaceAll('_', ' ').toTitleCase()}',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount: ${fee.amount.toCurrency}'),
                    Text('Due: ${fee.dueDate.formatted}'),
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

/// Rooms management tab
class _RoomsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(allRoomsProvider);

    return roomsAsync.when(
      data: (rooms) {
        if (rooms.isEmpty) {
          return const Center(child: Text('No rooms'));
        }

        // Group rooms by block
        final roomsByBlock = <String, List<RoomModel>>{};
        for (final room in rooms) {
          roomsByBlock.putIfAbsent(room.blockName, () => []).add(room);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: roomsByBlock.length,
          itemBuilder: (context, blockIndex) {
            final block = roomsByBlock.keys.elementAt(blockIndex);
            final blockRooms = roomsByBlock[block]!;

            return Card(
              child: ExpansionTile(
                title: Text('Block $block (${blockRooms.length} rooms)'),
                children: blockRooms.map((room) {
                  return ListTile(
                    leading: Icon(
                      Icons.room,
                      color: room.isAvailable ? Colors.green : Colors.red,
                    ),
                    title: Text(room.roomNumber),
                    subtitle: Text(
                      'Occupancy: ${room.currentOccupancy}/${room.capacity} • ${room.roomType}',
                    ),
                    trailing: Text(room.condition),
                  );
                }).toList(),
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
