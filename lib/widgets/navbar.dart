import 'package:flutter/material.dart';
import 'package:pronto/screens/applicant_home_screen.dart';
import 'package:pronto/screens/applicant_applications_screen.dart';
import 'package:pronto/screens/recruiter_home_screen.dart';
import 'package:pronto/screens/recruiter_jobs_screen.dart';
import 'package:pronto/screens/notifications_screen.dart';
import 'package:pronto/screens/profile_screen.dart';
import 'package:pronto/models/userType_model.dart' as user_type_model;

// Main navigation widget
class NavBar extends StatefulWidget {
  final String userId;
  final user_type_model.UserType userType;

  const NavBar({super.key, required this.userId, required this.userType});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _currentIndex = 0;

  List<Widget> _getScreens() {
    if (widget.userType == user_type_model.UserType.applicant) {
      return [
        ApplicantHomeScreen(userId: widget.userId),
        ApplicantApplicationsScreen(userId: widget.userId),
        NotificationsScreen(userId: widget.userId),
        ProfileScreen(userId: widget.userId, userType: widget.userType),
      ];
    } else {
      return [
        RecruiterHomeScreen(userId: widget.userId),
        RecruiterJobsScreen(userId: widget.userId),
        NotificationsScreen(userId: widget.userId),
        ProfileScreen(userId: widget.userId, userType: widget.userType),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavBarItems() {
    return [
      BottomNavigationBarItem(
        icon: Icon(_currentIndex == 0 ? Icons.home : Icons.home_outlined),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Icon(_currentIndex == 1 ? Icons.work : Icons.work_outline),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Icon(
          _currentIndex == 2
              ? Icons.notifications
              : Icons.notifications_outlined,
        ),
        label: '',
      ),
      BottomNavigationBarItem(
        icon: Icon(_currentIndex == 3 ? Icons.person : Icons.person_outline),
        label: '',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).primaryColor,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: _getNavBarItems(),
      ),
    );
  }
}
