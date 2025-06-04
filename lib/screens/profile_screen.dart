import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pronto/models/userType_model.dart';
import 'package:pronto/router.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;
  final UserType userType;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    final isApplicant = userType == UserType.applicant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit profile feature coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Icon(
                      isApplicant ? Icons.person : Icons.business,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isApplicant ? 'Job Seeker' : 'Employer',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ID: $userId',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildProfileStat('Profile Views', '24', Colors.blue),
                      _buildProfileStat(
                        isApplicant ? 'Applications' : 'Job Posts',
                        isApplicant ? '12' : '8',
                        Colors.green,
                      ),
                      _buildProfileStat(
                        isApplicant ? 'Interviews' : 'Hires',
                        isApplicant ? '3' : '5',
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Profile options
            Column(
              children: [
                _buildProfileItem(
                  Icons.person,
                  'Personal Information',
                  'Update your basic details',
                  context,
                ),
                _buildProfileItem(
                  Icons.work,
                  isApplicant ? 'Work Experience' : 'Company Details',
                  isApplicant
                      ? 'Add your work history'
                      : 'Update company information',
                  context,
                ),
                _buildProfileItem(
                  Icons.school,
                  isApplicant ? 'Education' : 'Subscription',
                  isApplicant
                      ? 'Add your educational background'
                      : 'Manage your plan',
                  context,
                ),
                _buildProfileItem(
                  Icons.badge,
                  isApplicant ? 'Skills & Certifications' : 'Job Categories',
                  isApplicant
                      ? 'Showcase your abilities'
                      : 'Set preferred job types',
                  context,
                ),
                _buildProfileItem(
                  Icons.location_on,
                  'Location Preferences',
                  'Set your preferred work locations',
                  context,
                ),
                _buildProfileItem(
                  Icons.notifications,
                  'Notification Settings',
                  'Manage your notification preferences',
                  context,
                ),
                _buildProfileItem(
                  Icons.security,
                  'Privacy & Security',
                  'Manage your account security',
                  context,
                ),
                _buildProfileItem(
                  Icons.help,
                  'Help & Support',
                  'Get help and contact support',
                  context,
                ),
                _buildProfileItem(
                  Icons.info,
                  'About',
                  'App version and terms',
                  context,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sign out button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Show confirmation dialog
                  final shouldSignOut = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );

                  if (shouldSignOut == true) {
                    try {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Signed out successfully'),
                          ),
                        );
                        // Navigate back to welcome screen
                        NavigationHelper.navigateAndClearStack('/welcome');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error signing out: $e')),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String title,
    String subtitle,
    BuildContext context,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title feature coming soon!')),
          );
        },
      ),
    );
  }
}
