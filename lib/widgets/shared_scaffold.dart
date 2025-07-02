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
            allowedRoutes: ['/home', '/blog', '/courses'], // ⬅️ allow on courses page
            currentRoute: currentRoute,
          ),
        ],
      ),
      bottomNavigationBar: showNavbar
          ? BottomNavigationBar(
              currentIndex: _getCurrentIndex(),
              onTap: (index) {
                switch (index) {
                  case 0:
                    if (currentRoute != '/home') {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                    break;
                  case 1:
                    if (currentRoute != '/blog') {
                      Navigator.pushReplacementNamed(context, '/blog');
                    }
                    break;
                  case 2:
                    if (currentRoute != '/courses') {
                      Navigator.pushReplacementNamed(context, '/courses');
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
              ],
            )
          : null,
    );
  }

  int _getCurrentIndex() {
    switch (currentRoute) {
      case '/home':
        return 0;
      case '/blog':
        return 1;
      case '/courses':
        return 2;
      default:
        return 0;
    }
  }
}
