import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/report_service.dart';

class ReportDialog extends StatefulWidget {
  final String reportedId;
  final ReportType type;
  final String reportedName;

  const ReportDialog({
    Key? key,
    required this.reportedId,
    required this.type,
    required this.reportedName,
  }) : super(key: key);

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final ReportService _reportService = ReportService();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedReason = '';
  bool _isSubmitting = false;

  final List<String> _reportReasons = [
    'Spam',
    'Harassment',
    'Hate speech',
    'Violence',
    'Nudity or sexual content',
    'False information',
    'Other'
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport(String reporterId) async {
    if (_selectedReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final report = Report(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reporterId: reporterId,
        reportedId: widget.reportedId,
        type: widget.type,
        reason: _selectedReason,
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _reportService.submitReport(report);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting report: $e')),
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
    final theme = Theme.of(context);
    final currentUser = ModalRoute.of(context)?.settings.arguments as String?;

    return AlertDialog(
      title: Text('Report ${widget.type == ReportType.post ? 'Post' : 'User'}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why are you reporting ${widget.type == ReportType.post ? 'this post' : widget.reportedName}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._reportReasons.map((reason) => RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) => setState(() => _selectedReason = value!),
            )),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Additional details (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
          onPressed: currentUser == null
              ? null
              : _isSubmitting
                  ? null
                  : () => _submitReport(currentUser),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }
} 