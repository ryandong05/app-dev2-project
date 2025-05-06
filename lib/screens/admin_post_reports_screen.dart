import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/report_service.dart';

class AdminPostReportsScreen extends StatelessWidget {
  const AdminPostReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Reports'),
      ),
      body: StreamBuilder<List<PostReport>>(
        stream: reportService.getPostReports(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!;

          if (reports.isEmpty) {
            return Center(
              child: Text(
                'No post reports',
                style: theme.textTheme.titleLarge,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
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
                              await reportService.dismissPostReport(report.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Report dismissed'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            child: const Text('Dismiss'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              await reportService.deleteReportedPost(report.postId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Post deleted'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
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
        },
      ),
    );
  }
} 