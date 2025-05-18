import 'package:flutter/material.dart';
import 'package:study_buddy_app/widgets/activity_chart_widget.dart';
import 'package:study_buddy_app/widgets/greeting_widget.dart';
import 'package:study_buddy_app/widgets/today_schedule_card_widget.dart';
import 'package:study_buddy_app/widgets/top_bar_widget.dart';
import 'package:study_buddy_app/Views/profile_page.dart';
import 'package:study_buddy_app/Views/schedule_page.dart';
import 'package:study_buddy_app/Views/tasks_page.dart';
import 'package:study_buddy_app/Views/groups_page.dart';
import 'package:study_buddy_app/Views/quick_note_page.dart';
import 'package:study_buddy_app/Views/leaderboard_page.dart';
import 'package:study_buddy_app/Views/library_page.dart';
import 'package:study_buddy_app/widgets/notification_card_widget.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  bool _isButtonPressed = false;
  // Offset for the position of the floating button
  Offset _dragPosition = const Offset(40, 100);
  // List of pages to display
  final List<Widget> _pages = [
    const DashboardContent(),
    const SchedulePage(),
    const TasksPage(),
    const GroupsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Positioned(
            left: _dragPosition.dx,
            top: _dragPosition.dy,
            child: Draggable(
              feedback: _buildFloatingButton(),
              childWhenDragging: Container(),
              onDragEnd: (details) {
                // Update position when dragging ends
                setState(() {
                  // Adjust position according to screen bounds
                  double maxX = MediaQuery.of(context).size.width - 60;
                  double maxY = MediaQuery.of(context).size.height - 160;

                  _dragPosition = Offset(
                    details.offset.dx.clamp(0, maxX),
                    details.offset.dy.clamp(0, maxY),
                  );
                });
              },
              child: _buildFloatingButton(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            showSelectedLabels: true,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.task_alt),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),

              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingButton() {
    return GestureDetector(
      onTap: () {
        // First create a small scale animation on the button
        setState(() {
          _isButtonPressed = true;
        });

        // Delay to show the button animation before navigating
        Future.delayed(const Duration(milliseconds: 150), () {
          setState(() {
            _isButtonPressed = false;
          });

          // Navigate with a custom page transition
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      const QuickNotePage(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeOutQuint;

                var tween = Tween(
                  begin: begin,
                  end: end,
                ).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);

                var scaleAnimation = Tween(
                  begin: 0.8,
                  end: 1.0,
                ).chain(CurveTween(curve: curve)).animate(animation);

                var fadeAnimation = Tween(begin: 0.0, end: 1.0)
                    .chain(CurveTween(curve: const Interval(0.0, 0.5)))
                    .animate(animation);

                return FadeTransition(
                  opacity: fadeAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        });
      },
      child: AnimatedScale(
        scale: _isButtonPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/bookreader.png',
            color: Colors.white,
            width: 10,
            height: 10,
          ),
        ),
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          // Implement the refresh functionality here
          // This is where you would update your data from your providers
          await Future.delayed(
            const Duration(seconds: 1),
          ); // Simulating a refresh delay
          // You could refresh your data here like:
          // await context.read(yourProvider).refreshData();

          // Show a snackbar to confirm refresh action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dashboard refreshed!'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        },
        color: Colors.deepPurple,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with Study Buddy text and profile picture
              const TopBarWidget(), // Greeting and notification section
              const GreetingWidget(),

              // Notification Card
              const NotificationCardWidget(),

              // Today's Schedule Card
              const TodayScheduleCardWidget(),

              // Activity Chart
              const ActivityChartWidget(),

              // Leaderboard and Library buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // Leaderboard Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LeaderboardPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.leaderboard),
                            SizedBox(width: 8),
                            Text(
                              'Leaderboard',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Library Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to Library tab
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LibraryPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade300,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.library_books),
                            SizedBox(width: 8),
                            Text(
                              'Library',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
