import 'package:flutter/material.dart';
import 'profile_setup/project_screen.dart'; // Adjust the import path as needed

class HomeScreen extends StatelessWidget {
  final String? userId;

  const HomeScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen'), centerTitle: true),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectExperienceScreen(userId: userId),
              ),
            );
          },
          child: const Text('Go to Project Experience'),
        ),
      ),
    );
  }
}
