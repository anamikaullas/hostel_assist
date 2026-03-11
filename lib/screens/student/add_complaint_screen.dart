import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/index.dart';
import '../../models/index.dart';
import '../../services/complaint_service.dart';

/// Add complaint screen for students
/// Features: Category selection, description, priority, image upload
class AddComplaintScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const AddComplaintScreen({super.key, required this.user});

  @override
  ConsumerState<AddComplaintScreen> createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends ConsumerState<AddComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _complaintService = ComplaintService();

  String _selectedCategory = AppConstants.categoryMaintenance;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'value': AppConstants.categoryPlumbing,
      'label': 'Plumbing',
      'icon': Icons.plumbing,
    },
    {
      'value': AppConstants.categoryElectrical,
      'label': 'Electrical',
      'icon': Icons.electrical_services,
    },
    {
      'value': AppConstants.categoryMaintenance,
      'label': 'Maintenance',
      'icon': Icons.build,
    },
    {
      'value': AppConstants.categoryCleanliness,
      'label': 'Cleanliness',
      'icon': Icons.cleaning_services,
    },
    {
      'value': AppConstants.categoryNoise,
      'label': 'Noise',
      'icon': Icons.volume_up,
    },
    {
      'value': AppConstants.categoryHeating,
      'label': 'Heating/Cooling',
      'icon': Icons.ac_unit,
    },
    {
      'value': AppConstants.categoryOther,
      'label': 'Other',
      'icon': Icons.more_horiz,
    },
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _complaintService.submitComplaint(
        studentId: widget.user.uid,
        studentName: widget.user.fullName,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Complaint'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Provide detailed information to help us resolve your issue quickly.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Category Section
              Text(
                'Category',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Category Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category['value'];

                  return InkWell(
                    onTap: () {
                      setState(() => _selectedCategory = category['value']);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blue.shade700
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category['icon'] as IconData,
                            color: isSelected ? Colors.white : Colors.black87,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category['label'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Description Section
              Text(
                'Description',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Describe your issue in detail...',
                  border: OutlineInputBorder(),
                  helperText: 'Be specific about the location and issue',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your complaint';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitComplaint,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Complaint',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Future Scope Features
              ExpansionTile(
                title: const Text(
                  '🚀 Future Features',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _FutureFeatureItem(
                          icon: Icons.location_on,
                          text: 'Auto-detect room location',
                        ),
                        _FutureFeatureItem(
                          icon: Icons.smart_toy,
                          text: 'AI-powered complaint categorization',
                        ),
                        _FutureFeatureItem(
                          icon: Icons.notifications_active,
                          text: 'Real-time status notifications',
                        ),
                        _FutureFeatureItem(
                          icon: Icons.rate_review,
                          text: 'Rate admin response quality',
                        ),
                        _FutureFeatureItem(
                          icon: Icons.chat,
                          text: 'Chat with admin directly',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Future feature item widget
class _FutureFeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FutureFeatureItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
