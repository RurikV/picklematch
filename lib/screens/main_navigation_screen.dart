import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import 'home_screen.dart';
import 'create_game_screen.dart';
import 'tournament_management_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final isAdmin = state.user.role == 'admin';

          // Define the screens for navigation
          final List<Widget> screens = [
            const HomeScreen(),
            if (isAdmin) const CreateGameScreen(),
            if (isAdmin) const TournamentManagementScreen(),
            const ProfileScreen(),
          ];

          // Define the navigation items
          final List<BottomNavigationBarItem> navItems = [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            if (isAdmin)
              const BottomNavigationBarItem(
                icon: Icon(Icons.add_circle),
                label: 'Create Game',
              ),
            if (isAdmin)
              const BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events),
                label: 'Tournaments',
              ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ];

          // Ensure selected index is valid
          final validIndex = _selectedIndex < screens.length ? _selectedIndex : 0;

          return Scaffold(
            body: IndexedStack(
              index: validIndex,
              children: screens,
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: validIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: navItems,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
            ),
          );
        } else {
          // Fallback for non-authenticated states
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
