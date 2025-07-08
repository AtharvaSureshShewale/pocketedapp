import 'package:flutter/material.dart';
import 'package:pocketed/widgets/draggable_assistive_button.dart';

class SharedScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final String currentRoute;
  final bool showNavbar;

  const SharedScaffold({
    super.key,
    required this.body,
    this.appBar,
    required this.currentRoute,
    this.showNavbar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: Stack(
        children: [
          body,
          DraggableAssistiveButton(
            onTap: () {
              Navigator.pushNamed(context, '/assistive');
            },
            allowedRoutes: [
              '/home',
              '/blog',
              '/courses',
              '/mentor',
            ],
            currentRoute: currentRoute,
          ),
        ],
      ),
      bottomNavigationBar: showNavbar
          ? BottomNavigationBar(
              currentIndex: _getCurrentIndex(),
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.black,
              selectedIconTheme: const IconThemeData(size: 28),
              unselectedIconTheme: const IconThemeData(size: 24),
              type: BottomNavigationBarType.fixed,
              onTap: (index) {
                switch (index) {
                  case 0:
                    if (currentRoute != '/home') {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                    break;
                  case 1:
                    if (currentRoute != '/blogDisplay') {
                      Navigator.pushReplacementNamed(context, '/blogDisplay');
                    }
                    break;
                  case 2:
                    if (currentRoute != '/courses') {
                      Navigator.pushReplacementNamed(context, '/courses');
                    }
                    break;
                  case 3:
                    if (currentRoute != '/mentor') {
                      Navigator.pushReplacementNamed(context, '/mentor');
                    }
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.article),
                  label: 'Blog',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.school),
                  label: 'Courses',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: 'Mentor',
                ),
              ],
            )
          : null,
    );
  }

  int _getCurrentIndex() {
    switch (currentRoute) {
      case '/home':
        return 0;
      case '/blogDisplay': // ✅ FIXED: matches route in onTap
        return 1;
      case '/courses':
        return 2;
      case '/mentor':
        return 3;
      default:
        return 0;
    }
  }
}
