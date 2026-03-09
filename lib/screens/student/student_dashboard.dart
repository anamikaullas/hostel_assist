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

  static const _tabTitles = ['Home', 'Complaints', 'Fees', 'Mess', 'Assistant'];

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final unreadCount = notificationsAsync.valueOrNull?.length ?? 0;
    final colorScheme = Theme.of(context).colorScheme;
    final initial = widget.user.fullName.isNotEmpty
        ? widget.user.fullName[0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        leading: PopupMenuButton<String>(
          offset: const Offset(0, 56),
          tooltip: 'Profile',
          onSelected: (value) async {
            if (value == 'logout') {
              await ref.read(loginProvider.notifier).logout();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: const [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 10),
                  Text('Logout'),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        title: Text(_tabTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notices',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => _NoticesScreen(user: widget.user),
                ),
              );
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
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem_rounded),
            label: 'Complaints',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Fees',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu_rounded),
            label: 'Mess',
          ),
          const NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy_rounded),
            label: 'Assistant',
          ),
        ],
      ),
    );
  }
}

/// Home tab showing overview
class _HomeTab extends ConsumerWidget {
  final UserModel user;

  const _HomeTab({required this.user});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomByStudentIdProvider(user.uid));
    final complaintsAsync = ref.watch(complaintsByStudentProvider(user.uid));
    final feesAsync = ref.watch(pendingFeesByStudentProvider(user.uid));
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            color: Colors.white.withOpacity(0.75),
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            user.enrollmentId ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.school_outlined,
                            color: Colors.white.withOpacity(0.75),
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Year ${user.year}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Quick Overview',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Room info card
          roomAsync.when(
            data: (room) => _InfoCard(
              icon: room == null ? Icons.hotel_outlined : Icons.hotel_rounded,
              iconColor: room == null ? Colors.orange : Colors.green,
              title: room == null
                  ? 'Room Not Assigned'
                  : 'Room ${room.roomNumber}',
              subtitle: room == null
                  ? 'Contact admin for allocation'
                  : 'Block ${room.blockName}  •  Floor ${room.floorNumber}',
              trailing: room != null
                  ? Chip(
                      label: Text(
                        room.condition.toTitleCase(),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 11,
                        ),
                      ),
                      backgroundColor: Colors.green.shade50,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )
                  : null,
            ),
            loading: () => const _InfoCard(
              icon: Icons.hotel_outlined,
              iconColor: Colors.grey,
              title: 'Loading room info...',
              subtitle: '',
              isLoading: true,
            ),
            error: (e, _) => _InfoCard(
              icon: Icons.error_outline,
              iconColor: Colors.red,
              title: 'Error loading room',
              subtitle: e.toString(),
            ),
          ),
          const SizedBox(height: 12),

          // Stats row (complaints + fees)
          Row(
            children: [
              Expanded(
                child: complaintsAsync.when(
                  data: (complaints) {
                    final open = complaints.where((c) => c.isOpen).length;
                    return _StatsCard(
                      icon: Icons.report_problem_rounded,
                      color: Colors.orange,
                      value: '${complaints.length}',
                      label: 'Complaints',
                      badge: open > 0 ? '$open open' : 'All resolved',
                      badgeGood: open == 0,
                    );
                  },
                  loading: () => const _StatsCard(
                    icon: Icons.report_problem_rounded,
                    color: Colors.orange,
                    value: '—',
                    label: 'Complaints',
                  ),
                  error: (_, _) => const _StatsCard(
                    icon: Icons.error,
                    color: Colors.red,
                    value: '!',
                    label: 'Error',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: feesAsync.when(
                  data: (fees) {
                    final total = fees.fold<double>(0, (s, f) => s + f.amount);
                    return _StatsCard(
                      icon: Icons.receipt_long_rounded,
                      color: fees.isEmpty ? Colors.green : Colors.red,
                      value: '${fees.length}',
                      label: 'Pending Fees',
                      badge: fees.isEmpty ? 'All paid ✓' : total.toCurrency,
                      badgeGood: fees.isEmpty,
                    );
                  },
                  loading: () => const _StatsCard(
                    icon: Icons.receipt_long_rounded,
                    color: Colors.blue,
                    value: '—',
                    label: 'Fees',
                  ),
                  error: (_, _) => const _StatsCard(
                    icon: Icons.error,
                    color: Colors.red,
                    value: '!',
                    label: 'Error',
                  ),
                ),
              ),
            ],
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
                Icon(
                  Icons.check_circle_rounded,
                  size: 72,
                  color: Colors.green.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'All Clear!',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'No fees due at this time',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final pendingFees = fees.where((f) => !f.isPaid).toList();
        final paidFees = fees.where((f) => f.isPaid).toList();
        final totalPending = pendingFees.fold<double>(
          0,
          (s, f) => s + f.amount,
        );

        return Column(
          children: [
            // Summary header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: pendingFees.isNotEmpty
                      ? [Colors.red.shade400, Colors.red.shade600]
                      : [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pendingFees.isNotEmpty
                              ? 'Amount Due'
                              : 'All Settled!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pendingFees.isNotEmpty
                              ? totalPending.toCurrency
                              : '₹0',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (pendingFees.isNotEmpty)
                        _PillBadge('${pendingFees.length} Pending'),
                      if (pendingFees.isNotEmpty && paidFees.isNotEmpty)
                        const SizedBox(height: 4),
                      if (paidFees.isNotEmpty)
                        _PillBadge('${paidFees.length} Paid'),
                    ],
                  ),
                ],
              ),
            ),

            // Fee list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: fees.length,
                itemBuilder: (context, i) {
                  final fee = fees[i];
                  final isPaid = fee.isPaid;
                  final statusColor = isPaid ? Colors.green : Colors.red;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPaid
                                  ? Icons.check_circle_rounded
                                  : Icons.receipt_long_rounded,
                              color: statusColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fee.feeType
                                      .replaceAll('_', ' ')
                                      .toTitleCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Due: ${fee.dueDate.formatted}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                fee.amount.toCurrency,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  fee.status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 72,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  "Today's menu not available",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    menu.date.formatted,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildMealCard(
                context,
                'Breakfast',
                menu.breakfast,
                Icons.free_breakfast_rounded,
                Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildMealCard(
                context,
                'Lunch',
                menu.lunch,
                Icons.lunch_dining_rounded,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildMealCard(
                context,
                'Dinner',
                menu.dinner,
                Icons.dinner_dining_rounded,
                Colors.indigo,
              ),
              if (menu.remarks != null && menu.remarks!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.blue.shade50,
                  child: ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                    ),
                    title: const Text(
                      'Remarks',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(menu.remarks!),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildMealCard(
    BuildContext context,
    String mealName,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  mealName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${items.length} item${items.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Not available',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: items
                        .map(
                          (item) => Chip(
                            label: Text(
                              item,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: color.withOpacity(0.07),
                            side: BorderSide(color: color.withOpacity(0.2)),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        .toList(),
                  ),
                ),
        ],
      ),
    );
  }
}

/// Full-screen notices page pushed from the bell icon
class _NoticesScreen extends StatelessWidget {
  final UserModel user;

  const _NoticesScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      body: _NotificationsTab(user: user),
    );
  }
}

/// Notifications tab showing admin broadcasts
class _NotificationsTab extends ConsumerWidget {
  final UserModel user;

  const _NotificationsTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No notices',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('Admin announcements will appear here'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(notificationsStreamProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.campaign, color: Colors.blue),
                  ),
                  title: Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notification.message),
                      const SizedBox(height: 6),
                      Text(
                        'From: ${notification.sentBy}  •  '
                        '${_formatDate(notification.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error: ${error.toString()}')),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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

/// Icon + title + subtitle card used in the home tab overview
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool isLoading;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: iconColor,
                        ),
                      ),
                    )
                  : Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Compact stat card with value + label + optional badge
class _StatsCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String? badge;
  final bool badgeGood;

  const _StatsCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.badge,
    this.badgeGood = false,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = badgeGood ? Colors.green : color;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    color: badgeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small pill badge used in the fees summary header
class _PillBadge extends StatelessWidget {
  final String label;
  const _PillBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
