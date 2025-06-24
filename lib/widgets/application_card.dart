import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pronto/models/application_model.dart';
import 'package:pronto/models/job_model.dart';
import 'package:pronto/constants/colours.dart';
import 'package:pronto/router.dart';

class ApplicationCard extends StatelessWidget {
  final Application application;
  final Job? job;
  final Map<String, String?>? companyData;
  final List<String> statusOptions;
  final void Function() onDelete;
  final void Function() onToggleFavorite;
  final void Function(String newStatus) onUpdateStatus;
  final String timeAgo;
  final Color Function(String status) getStatusColor;

  const ApplicationCard({
    super.key,
    required this.application,
    required this.job,
    required this.companyData,
    required this.statusOptions,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onUpdateStatus,
    required this.timeAgo,
    required this.getStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: Key(application.applicationID),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (context) => onDelete(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                bottomLeft: Radius.circular(0),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: job != null
                ? () => NavigationHelper.navigateTo(
                    '/job-details',
                    arguments: job,
                  )
                : null,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Logo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: companyData?['companyLogoUrl'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              companyData!['companyLogoUrl']!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.business,
                                    color: Colors.grey[400],
                                    size: 28,
                                  ),
                            ),
                          )
                        : Icon(
                            Icons.business,
                            color: Colors.grey[400],
                            size: 28,
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Job Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${companyData?['company'] ?? 'Unknown Company'} • ${job?.location ?? 'Unknown'} (${job?.workArrangement ?? 'Unknown'})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: onToggleFavorite,
                              child: Icon(
                                application.favorite
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: application.favorite
                                    ? AppColors.primary
                                    : Colors.grey,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Job Title
                        Text(
                          job?.title ?? 'Unknown Position',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),

                        // Bottom row: status and time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: getStatusColor(
                                  application.status,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: getStatusColor(
                                    application.status,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: DropdownButton<String>(
                                value: application.status,
                                isDense: true,
                                underline: const SizedBox(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: getStatusColor(application.status),
                                  fontWeight: FontWeight.w600,
                                ),
                                items: statusOptions
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null)
                                    onUpdateStatus(newStatus);
                                },
                              ),
                            ),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
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
          ),
        ),
      ),
    );
  }
}
