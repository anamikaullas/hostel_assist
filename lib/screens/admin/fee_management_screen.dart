import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/index.dart';
import '../../providers/index.dart';
import '../../services/fee_service.dart';
import '../../utils/index.dart';

/// Fee management screen with CRUD operations
class FeeManagementScreen extends ConsumerStatefulWidget {
  const FeeManagementScreen({super.key});

  @override
  ConsumerState<FeeManagementScreen> createState() =>
      _FeeManagementScreenState();
}

class _FeeManagementScreenState extends ConsumerState<FeeManagementScreen> {
  String _selectedStatus = 'All';
  final _feeService = FeeService();

  @override
  Widget build(BuildContext context) {
    final feesAsync = ref.watch(allFeesProvider(null));

    return Column(
      children: [
        // Header with filter and add button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Fee Management',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              DropdownButton<String>(
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Status')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showFeeDialog(null),
                icon: const Icon(Icons.add),
                label: const Text('Add Fee'),
              ),
            ],
          ),
        ),
        // Fee list
        Expanded(
          child: feesAsync.when(
            data: (fees) {
              final filteredFees = _selectedStatus == 'All'
                  ? fees
                  : fees.where((f) => f.status == _selectedStatus).toList();

              if (filteredFees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No fees found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                );
              }

              // Sort by due date (newest first)
              filteredFees.sort((a, b) => b.dueDate.compareTo(a.dueDate));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredFees.length,
                itemBuilder: (context, index) {
                  final fee = filteredFees[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: fee.isPaid
                            ? Colors.green
                            : fee.isOverdue
                            ? Colors.red
                            : Colors.orange,
                        child: Icon(
                          fee.isPaid ? Icons.check : Icons.payment,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        fee.studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${fee.feeType.replaceAll('_', ' ').toTitleCase()} - ${fee.amount.toCurrency}',
                          ),
                          Text('Due: ${fee.dueDate.formatted}'),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(fee.status.toUpperCase()),
                        backgroundColor: fee.isPaid
                            ? Colors.green
                            : fee.isOverdue
                            ? Colors.red
                            : Colors.orange,
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
                                        Text('Student ID: ${fee.studentId}'),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Amount: ${fee.amount.toCurrency}',
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Created: ${fee.createdAt.formatted}',
                                        ),
                                        if (fee.paidDate != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Paid: ${fee.paidDate!.formatted}',
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!fee.isPaid) ...[
                                    ElevatedButton.icon(
                                      onPressed: () => _markAsPaid(fee),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Mark as Paid'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  OutlinedButton.icon(
                                    onPressed: () => _showFeeDialog(fee),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit'),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () => _deleteFee(fee),
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

  void _showFeeDialog(FeeModel? fee) {
    final isEdit = fee != null;
    final studentIdController = TextEditingController(text: fee?.studentId);
    final studentNameController = TextEditingController(text: fee?.studentName);
    final amountController = TextEditingController(
      text: fee?.amount.toString() ?? '',
    );
    String feeType = fee?.feeType ?? 'hostel_fee';
    DateTime dueDate =
        fee?.dueDate ?? DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Fee' : 'Add New Fee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Student ID',
                    hintText: 'Enter student ID',
                  ),
                  enabled: !isEdit,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: studentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                    hintText: 'Enter full name',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: feeType,
                  decoration: const InputDecoration(labelText: 'Fee Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'hostel_fee',
                      child: Text('Hostel Fee'),
                    ),
                    DropdownMenuItem(
                      value: 'mess_fee',
                      child: Text('Mess Fee'),
                    ),
                    DropdownMenuItem(
                      value: 'maintenance',
                      child: Text('Maintenance'),
                    ),
                    DropdownMenuItem(
                      value: 'security',
                      child: Text('Security'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => feeType = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Enter amount',
                    prefixText: '₹',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Due Date'),
                  subtitle: Text(dueDate.formatted),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => dueDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (isEdit) {
                    // Update fee - Firebase doesn't have update method, so delete and recreate
                    await _feeService.deleteFee(fee.feeId);
                    await _feeService.createFee(
                      studentId: studentIdController.text.trim(),
                      studentName: studentNameController.text.trim(),
                      amount: double.parse(amountController.text),
                      feeType: feeType,
                      dueDate: dueDate,
                    );
                  } else {
                    await _feeService.createFee(
                      studentId: studentIdController.text.trim(),
                      studentName: studentNameController.text.trim(),
                      amount: double.parse(amountController.text),
                      feeType: feeType,
                      dueDate: dueDate,
                    );
                  }
                  Navigator.pop(context);
                  ref.invalidate(allFeesProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'Fee updated successfully'
                              : 'Fee created successfully',
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
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _markAsPaid(FeeModel fee) async {
    try {
      await _feeService.markFeeAsPaid(
        feeId: fee.feeId,
        transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
      );
      ref.invalidate(allFeesProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fee marked as paid')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _deleteFee(FeeModel fee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Fee'),
        content: Text(
          'Are you sure you want to delete this fee for ${fee.studentName}?',
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
        await _feeService.deleteFee(fee.feeId);
        ref.invalidate(allFeesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fee deleted successfully')),
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
