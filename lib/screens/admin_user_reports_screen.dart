import 'package:flutter/material.dart';
import '../models/report.dart';
import '../services/report_service.dart';
import 'profile_screen.dart';

class AdminUserReportsScreen extends StatelessWidget {
  const AdminUserReportsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reportService = ReportService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Reports'),
      ),
      body: StreamBuilder<List<UserReport>>(
        stream: reportService.getUserReports(),
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
                'No user reports',
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
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                    userId: report.reportedUserId,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'View Profile: ${report.reportedUsername}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
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
                              await reportService.dismissUserReport(report.id);
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
                              await reportService.banUser(report.reportedUserId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('User banned'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                              foregroundColor: theme.colorScheme.onError,
                            ),
                            child: const Text('Ban User'),
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