import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import 'dart:developer' as developer;
import 'dart:async';

class AdminPostReportsScreen extends StatefulWidget {
  const AdminPostReportsScreen({Key? key}) : super(key: key);

  @override
  State<AdminPostReportsScreen> createState() => AdminPostReportsScreenState();
}

class AdminPostReportsScreenState extends State<AdminPostReportsScreen> {
  final ReportService _reportService = ReportService();
  List<PostReport> _reports = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _reportsSubscription;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  @override
  void dispose() {
    _mounted = false;
    _reportsSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadReports() async {
    if (!_mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _reportsSubscription?.cancel();
      _reportsSubscription = _reportService.getPostReports().listen(
        (reports) {
          if (_mounted) {
            setState(() {
              _reports = reports;
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          if (_mounted) {
            setState(() {
              _error = error.toString();
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (_mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!_mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_error',
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadReports,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Text(
          'No post reports',
          style: theme.textTheme.titleLarge,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report header
                Row(
                  children: [
                    Text(
                      'Reported by: ${report.reporterUsername}',
                      style: theme.textTheme.titleSmall,
                    ),
                    const Spacer(),
                    Text(
                      'Posted by: ${report.reportedUsername}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Post content
                Text(
                  report.postContent,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),

                // Report reason
                Text(
                  'Reason: ${report.reason}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        try {
                          await _reportService.dismissPostReport(report.id);
                          if (_mounted) {
                            _showSnackBar('Report dismissed');
                          }
                        } catch (e) {
                          if (_mounted) {
                            _showSnackBar('Error dismissing report: $e',
                                isError: true);
                          }
                        }
                      },
                      child: const Text('Dismiss'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        try {
                          await _reportService
                              .deleteReportedPost(report.postId);
                          if (_mounted) {
                            _showSnackBar('Post deleted');
                          }
                        } catch (e) {
                          if (_mounted) {
                            _showSnackBar('Error deleting post: $e',
                                isError: true);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      child: const Text('Delete Post'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
