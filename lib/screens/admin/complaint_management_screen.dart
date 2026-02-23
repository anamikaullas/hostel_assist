import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/index.dart';
import '../../providers/index.dart';
import '../../services/complaint_service.dart';
import '../../utils/index.dart';

/// Complaint management screen with update and delete operations
class ComplaintManagementScreen extends ConsumerStatefulWidget {
  const ComplaintManagementScreen({super.key});

  @override
  ConsumerState<ComplaintManagementScreen> createState() =>
      _ComplaintManagementScreenState();
}

class _ComplaintManagementScreenState
    extends ConsumerState<ComplaintManagementScreen> {
  String _selectedStatus = 'All';
  final _complaintService = ComplaintService();

  @override
  Widget build(BuildContext context) {
    final complaintsAsync = ref.watch(allComplaintsProvider(null));

    return Column(
      children: [
        // Header with filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Complaint Management',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              DropdownButton<String>(
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Status')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text('In Progress'),
                  ),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
            ],
          ),
        ),
        // Complaint list
        Expanded(
          child: complaintsAsync.when(
            data: (complaints) {
              final filteredComplaints = _selectedStatus == 'All'
                  ? complaints
                  : complaints
                        .where((c) => c.status == _selectedStatus)
                        .toList();

              if (filteredComplaints.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.report_problem,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No complaints found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                );
              }

              // Sort by created date (newest first)
              filteredComplaints.sort(
                (a, b) => b.createdAt.compareTo(a.createdAt),
              );

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredComplaints.length,
                itemBuilder: (context, index) {
                  final complaint = filteredComplaints[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: complaint.isHighPriority
                            ? Colors.red
                            : complaint.priority == 'medium'
                            ? Colors.orange
                            : Colors.blue,
                        child: Icon(
                          complaint.isResolved
                              ? Icons.check
                              : Icons.report_problem,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        complaint.studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${complaint.category} • ${complaint.priority.toUpperCase()}',
                          ),
                          Text(
                            complaint.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (complaint.determinedCategory != null)
                            Text(
                              'AI: ${complaint.determinedCategory}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(complaint.status.toUpperCase()),
                        backgroundColor: complaint.isResolved
                            ? Colors.green
                            : complaint.status == 'in_progress'
                            ? Colors.orange
                            : Colors.red,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Student ID: ${complaint.studentId}',
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Category: ${complaint.category}'),
                                        const SizedBox(height: 4),
                                        Text('Priority: ${complaint.priority}'),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Created: ${complaint.createdAt.formatted}',
                                        ),
                                        if (complaint.resolvedAt != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Resolved: ${complaint.resolvedAt!.formatted}',
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text(
                                'Description:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(complaint.description),
                              if (complaint.adminRemarks != null) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'Admin Remarks:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(complaint.adminRemarks!),
                              ],
                              if (complaint.imageUrl != null) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'Attached Image:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Image.network(
                                  complaint.imageUrl!,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ],
                              const SizedBox(height: 16),
                              Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (!complaint.isResolved) ...[
                                    if (complaint.status == 'pending')
                                      ElevatedButton.icon(
                                        onPressed: () => _updateStatus(
                                          complaint,
                                          'in_progress',
                                        ),
                                        icon: const Icon(Icons.play_arrow),
                                        label: const Text('Start Progress'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                        ),
                                      ),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _showRemarkDialog(complaint),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Mark Resolved'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                  ],
                                  OutlinedButton.icon(
                                    onPressed: () => _showRemarkDialog(
                                      complaint,
                                      isResolving: false,
                                    ),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Add Remark'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _deleteComplaint(complaint),
                                    icon: const Icon(Icons.delete),
                                    label: const Text('Delete'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Error: ${error.toString()}')),
          ),
        ),
      ],
    );
  }

  void _updateStatus(ComplaintModel complaint, String status) async {
    try {
      await _complaintService.updateComplaintStatus(
        complaintId: complaint.complaintId,
        status: status,
      );
      ref.invalidate(allComplaintsProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to $status')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _showRemarkDialog(ComplaintModel complaint, {bool isResolving = true}) {
    final remarksController = TextEditingController(
      text: complaint.adminRemarks ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isResolving ? 'Resolve Complaint' : 'Add Admin Remark'),
        content: TextField(
          controller: remarksController,
          decoration: const InputDecoration(
            labelText: 'Admin Remarks',
            hintText: 'Enter remarks...',
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _complaintService.updateComplaintStatus(
                  complaintId: complaint.complaintId,
                  status: isResolving ? 'resolved' : complaint.status,
                  adminRemarks: remarksController.text.trim(),
                );
                Navigator.pop(context);
                ref.invalidate(allComplaintsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isResolving
                            ? 'Complaint resolved successfully'
                            : 'Remark added successfully',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: Text(isResolving ? 'Resolve' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _deleteComplaint(ComplaintModel complaint) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Complaint'),
        content: Text(
          'Are you sure you want to delete this complaint from ${complaint.studentName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _complaintService.deleteComplaint(complaint.complaintId);
        ref.invalidate(allComplaintsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complaint deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }
}
