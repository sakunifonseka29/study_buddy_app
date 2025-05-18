import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:study_buddy_app/Models/task_schedule.dart';
import 'package:study_buddy_app/providerService.dart';
import 'package:study_buddy_app/widgets/api_connection_status.dart';
import '../Service/python_service.dart';
import '../Service/remote_api_service.dart';
import '../helpers/notification_permission_helper_new.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  // Calendar variables
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  // API connection status
  bool _showApiStatus = false;
  bool _isApiConnecting = false;
  final RemoteAPIService _apiService = RemoteAPIService();
  @override
  void initState() {
    super.initState();

    // Initialize smart features (delayed to ensure we have the provider available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch schedules from Firebase
      ref.read(taskScheduleProvider.notifier).fetchSchedulesFromFirebase();
      _updateSmartFeatures();
      _checkApiConnection();
    });
  }

  // Check if the API server is reachable
  Future<void> _checkApiConnection() async {
    setState(() {
      _showApiStatus = true;
      _isApiConnecting = true;
    });

    bool isReachable = await _apiService.isServerReachable();

    setState(() {
      _showApiStatus =
          !isReachable; // Only show status if there's a connection issue
      _isApiConnecting = false;
    });

    // If not reachable, show instructions in console
    if (!isReachable) {
      debugPrint('*' * 60);
      debugPrint('CONNECTION ERROR: Flask server not running');
      debugPrint('To resolve this issue:');
      debugPrint('1. Open a terminal/command prompt');
      debugPrint('2. Navigate to your app\'s Py folder');
      debugPrint(
        '   cd "C:\\Users\\Sathsara Hewage\\Documents\\MyProjects\\Flutter Projects\\study_buddy_app\\Py"',
      );
      debugPrint('3. Run: python app.py');
      debugPrint('*' * 60);
    }
  }

  // Attempt to reconnect to server
  Future<void> _attemptReconnection() async {
    setState(() {
      _isApiConnecting = true;
    });

    bool reconnected = await _apiService.attemptReconnection();

    setState(() {
      _showApiStatus = !reconnected;
      _isApiConnecting = false;
    });

    if (reconnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully connected to server'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } // This method used to update smart features, but now is just a placeholder

  // since we've removed the dummy schedules and now rely on the Python backend
  void _updateSmartFeatures() {
    // No smart features to update anymore
  }
  // We've removed the scheduling conflict and smart suggestion helper methods
  // as they are no longer needed with the Python backend implementation
  Future<void> _generateAISchedule() async {
    final userId = ref.read(firebaseServiceProvider).currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to generate an AI schedule'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating your personalized schedule...'),
              ],
            ),
          ),
    );
    try {
      final pythonService = PythonService();

      // Generate the schedule using our service (which will try API first, then Python script)
      final success = await pythonService.generateSchedule(userId);

      // Close the loading dialog
      Navigator.pop(context);

      if (success) {
        // Fetch the newly created schedules from Firestore
        await ref
            .read(taskScheduleProvider.notifier)
            .fetchSchedulesFromFirebase();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI schedule generated successfully!'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );

        // Refresh the schedule data
        setState(() {
          _selectedDay = DateTime.now();
          _focusedDay = DateTime.now();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to generate AI schedule. Please try again later.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleNotifier = ref.watch(taskScheduleProvider.notifier);
    final eventsForSelectedDay = scheduleNotifier.getEventsForDay(_selectedDay);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar with title and back button
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'My Schedule',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const Spacer(),
                  // Optional help button
                  IconButton(
                    icon: const Icon(
                      Icons.help_outline,
                      color: Colors.deepPurple,
                    ),
                    onPressed: () {
                      // Show help dialog or tooltip
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tap a date to see your scheduled sessions',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Calendar section with improved styling
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TableCalendar(
                  firstDay: DateTime.utc(2023, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                    CalendarFormat.week: 'Week',
                  },
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    // When a new day is selected, we update our state
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });

                    // Update the smart features after the day changes
                    _updateSmartFeatures();
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  eventLoader: (day) {
                    return scheduleNotifier.getEventsForDay(day);
                  },
                  calendarStyle: CalendarStyle(
                    markerDecoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonTextStyle: TextStyle(color: Colors.deepPurple),
                    titleCentered: true,
                  ),
                ),
              ),
            ),

            // Date display with more prominent styling
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      DateFormat('EEEE, MMMM d').format(_selectedDay),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // XP available indicator
                  if (eventsForSelectedDay.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${eventsForSelectedDay.length * 15} XP available',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ), // Divider with gradient effect
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.deepPurple.withOpacity(0.5),
                    Colors.deepPurple,
                    Colors.deepPurple.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // API connection status indicator - only shown when needed
            if (_showApiStatus)
              APIConnectionStatus(
                isConnecting: _isApiConnecting,
                message:
                    _isApiConnecting
                        ? 'Connecting to schedule generator server...'
                        : 'Could not connect to the schedule server. Using local generation instead.',
                onRetry: _attemptReconnection,
              ),

            // Smart suggestions and conflict alerts have been removed
            // since we're now using the Python backend for schedule generation

            // Schedule list with improved styling
            Expanded(
              child:
                  eventsForSelectedDay.isEmpty
                      ? _buildEmptyState()
                      : _buildScheduleList(eventsForSelectedDay),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Build Schedule by AI button
            FloatingActionButton.extended(
              heroTag: 'aiScheduleButton',
              onPressed: _generateAISchedule,
              icon: const Icon(Icons.auto_awesome),
              label: const Text(
                'Build Schedule by AI',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.deepPurple,
            ),
            const SizedBox(width: 16),
            // Add Session button
            FloatingActionButton.extended(
              heroTag: 'addSessionButton',
              onPressed: () => _showAddSessionDialog(context),
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Session',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.deepPurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing scheduled for ${DateFormat('EEEE').format(_selectedDay)}!',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Nothing scheduled today! Tap ',
                style: TextStyle(color: Colors.grey),
              ),
              const Icon(Icons.add_circle, color: Colors.deepPurple, size: 16),
              const Text(
                ' to plan your study.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(List<TaskSchedule> schedules) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final schedule = schedules[index];
        return _buildScheduleCard(schedule);
      },
    );
  }

  Widget _buildScheduleCard(TaskSchedule schedule) {
    // Get color based on subject
    final Color subjectColor = _getSubjectColor(schedule.subject);

    return InkWell(
      onTap: () => _showSessionDetailsDialog(context, schedule),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject and time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Subject tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: subjectColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      schedule.subject,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: subjectColor,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  // Time
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        schedule.time,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title/description
              Row(
                children: [
                  // Type icon (solo or group) with improved styling
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      schedule.isGroup ? Icons.group : Icons.book,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      schedule.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Location if available
              if (schedule.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      schedule.location!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16), // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Notification toggle
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      _setReminderForSession(schedule);
                    },
                    tooltip: 'Set reminder',
                  ),

                  // Start button
                  OutlinedButton.icon(
                    onPressed: () {
                      _startStudySession(schedule);
                    },
                    icon: const Icon(Icons.timer, size: 16),
                    label: const Text('Start'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
        return Colors.blue;
      case 'biology':
        return Colors.green;
      case 'chemistry':
        return Colors.orange;
      case 'physics':
        return Colors.red;
      case 'computer science':
        return Colors.purple;
      case 'history':
        return Colors.brown;
      case 'literature':
        return Colors.teal;
      default:
        return Colors.deepPurple;
    }
  }

  void _showAddSessionDialog(BuildContext context) {
    final scheduleNotifier = ref.read(taskScheduleProvider.notifier);
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController startTimeController = TextEditingController();
    final TextEditingController endTimeController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    final TextEditingController notesController = TextEditingController();

    DateTime selectedDate = _selectedDay;
    bool isGroup = false;
    String? selectedSubject;

    // Get available subjects from the color map
    final subjectColorMap = TaskScheduleNotifier.getSubjectColorMap();
    final subjects =
        subjectColorMap.keys
            .toList()
            .map(
              (s) => s
                  .split(' ')
                  .map((word) => word[0].toUpperCase() + word.substring(1))
                  .join(' '),
            )
            .toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Study Session'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subject dropdown
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          subjects.map((String subject) {
                            return DropdownMenuItem<String>(
                              value: subject,
                              child: Text(subject),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSubject = value;
                          subjectController.text = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Custom subject if not in the list
                    if (selectedSubject == null) ...[
                      TextField(
                        controller: subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Subject',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Description field
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date picker
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('MMM d, y').format(selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Time range
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
                              border: OutlineInputBorder(),
                              hintText: '9:00 AM',
                            ),
                            onTap: () async {
                              FocusScope.of(context).requestFocus(FocusNode());
                              final TimeOfDay? pickedTime =
                                  await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                              if (pickedTime != null) {
                                setState(() {
                                  startTimeController.text = _formatTimeOfDay(
                                    pickedTime,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endTimeController,
                            decoration: const InputDecoration(
                              labelText: 'End Time',
                              border: OutlineInputBorder(),
                              hintText: '10:30 AM',
                            ),
                            onTap: () async {
                              FocusScope.of(context).requestFocus(FocusNode());
                              final TimeOfDay? pickedTime =
                                  await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                              if (pickedTime != null) {
                                setState(() {
                                  endTimeController.text = _formatTimeOfDay(
                                    pickedTime,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Location
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Group/Solo toggle
                    SwitchListTile(
                      title: const Text('Group Study'),
                      value: isGroup,
                      onChanged: (value) {
                        setState(() {
                          isGroup = value;
                        });
                      },
                      activeColor: Colors.deepPurple,
                    ),

                    // Notes
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    // Validate inputs
                    if (subjectController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        startTimeController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    // Create time string
                    final String timeString =
                        endTimeController.text.isNotEmpty
                            ? '${startTimeController.text} - ${endTimeController.text}'
                            : startTimeController.text;

                    // Create schedule
                    final TaskSchedule newSchedule = TaskSchedule(
                      subject: subjectController.text,
                      description: descriptionController.text,
                      time: timeString,
                      isGroup: isGroup,
                      location:
                          locationController.text.isEmpty
                              ? null
                              : locationController.text,
                      notes:
                          notesController.text.isEmpty
                              ? null
                              : notesController.text,
                    ); // Add to notifier
                    scheduleNotifier.addEvent(selectedDate, newSchedule);

                    // Update selected day if different from current
                    if (!isSameDay(selectedDate, _selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDate;
                        _focusedDay = selectedDate;
                      });
                    }

                    // Update smart features when a new schedule is added
                    _updateSmartFeatures();

                    Navigator.pop(context);

                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Study session added on ${DateFormat('EEEE, MMMM d').format(selectedDate)}',
                        ),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'View',
                          onPressed: () {
                            setState(() {
                              _selectedDay = selectedDate;
                              _focusedDay = selectedDate;
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper to format TimeOfDay to a string
  String _formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Show session details dialog
  void _showSessionDetailsDialog(BuildContext context, TaskSchedule schedule) {
    final Color subjectColor = _getSubjectColor(schedule.subject);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    schedule.isGroup ? Icons.group : Icons.book,
                    color: subjectColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    schedule.subject,
                    style: TextStyle(
                      color: subjectColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  tooltip: 'Edit session',
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditSessionDialog(context, schedule);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  tooltip: 'Delete session',
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, schedule);
                  },
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schedule.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Time
                  const Text(
                    'Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(schedule.time, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),

                  // Location if available
                  if (schedule.location != null &&
                      schedule.location!.isNotEmpty) ...[
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      schedule.location!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Study type
                  const Text(
                    'Study Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    schedule.isGroup ? 'Group Study' : 'Individual Study',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Notes if available
                  if (schedule.notes != null && schedule.notes!.isNotEmpty) ...[
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        schedule.notes!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _startStudySession(schedule);
                },
                icon: const Icon(Icons.timer),
                label: const Text('Start Studying'),
              ),
            ],
          ),
    );
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, TaskSchedule schedule) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Study Session'),
            content: Text(
              'Are you sure you want to delete "${schedule.subject}: ${schedule.description}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () {
                  final scheduleNotifier = ref.read(
                    taskScheduleProvider.notifier,
                  );
                  scheduleNotifier.deleteEvent(_selectedDay, schedule);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Study session deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ); // Refresh the state to show updated list and update smart features
                  setState(() {});
                  _updateSmartFeatures();
                },
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
    );
  }

  // Show edit session dialog
  void _showEditSessionDialog(BuildContext context, TaskSchedule schedule) {
    final scheduleNotifier = ref.read(taskScheduleProvider.notifier);
    final TextEditingController subjectController = TextEditingController(
      text: schedule.subject,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: schedule.description,
    );

    // Parse time string
    String startTime = '';
    String endTime = '';
    if (schedule.time.contains('-')) {
      final timeParts = schedule.time.split('-');
      startTime = timeParts[0].trim();
      endTime = timeParts[1].trim();
    } else {
      startTime = schedule.time;
    }

    final TextEditingController startTimeController = TextEditingController(
      text: startTime,
    );
    final TextEditingController endTimeController = TextEditingController(
      text: endTime,
    );
    final TextEditingController locationController = TextEditingController(
      text: schedule.location ?? '',
    );
    final TextEditingController notesController = TextEditingController(
      text: schedule.notes ?? '',
    );

    DateTime selectedDate = _selectedDay;
    bool isGroup = schedule.isGroup;
    String? selectedSubject = schedule.subject;

    // Get available subjects from the color map
    final subjectColorMap = TaskScheduleNotifier.getSubjectColorMap();
    final subjects =
        subjectColorMap.keys
            .toList()
            .map(
              (s) => s
                  .split(' ')
                  .map((word) => word[0].toUpperCase() + word.substring(1))
                  .join(' '),
            )
            .toList();

    // Check if current subject is in the list
    if (!subjects.contains(selectedSubject) && selectedSubject.isNotEmpty) {
      // If not, set selected to null but keep the text in the controller
      selectedSubject = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Study Session'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subject dropdown
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          subjects.map((String subject) {
                            return DropdownMenuItem<String>(
                              value: subject,
                              child: Text(subject),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedSubject = value;
                          subjectController.text = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Custom subject if not in the list
                    if (selectedSubject == null) ...[
                      TextField(
                        controller: subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Subject',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Description field
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Date picker
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('MMM d, y').format(selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Time range
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Start Time',
                              border: OutlineInputBorder(),
                              hintText: '9:00 AM',
                            ),
                            onTap: () async {
                              FocusScope.of(context).requestFocus(FocusNode());
                              final TimeOfDay? pickedTime =
                                  await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                              if (pickedTime != null) {
                                setState(() {
                                  startTimeController.text = _formatTimeOfDay(
                                    pickedTime,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endTimeController,
                            decoration: const InputDecoration(
                              labelText: 'End Time',
                              border: OutlineInputBorder(),
                              hintText: '10:30 AM',
                            ),
                            onTap: () async {
                              FocusScope.of(context).requestFocus(FocusNode());
                              final TimeOfDay? pickedTime =
                                  await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                              if (pickedTime != null) {
                                setState(() {
                                  endTimeController.text = _formatTimeOfDay(
                                    pickedTime,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Location
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Group/Solo toggle
                    SwitchListTile(
                      title: const Text('Group Study'),
                      value: isGroup,
                      onChanged: (value) {
                        setState(() {
                          isGroup = value;
                        });
                      },
                      activeColor: Colors.deepPurple,
                    ),

                    // Notes
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    // Validate inputs
                    if (subjectController.text.isEmpty ||
                        descriptionController.text.isEmpty ||
                        startTimeController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    // Create time string
                    final String timeString =
                        endTimeController.text.isNotEmpty
                            ? '${startTimeController.text} - ${endTimeController.text}'
                            : startTimeController.text;

                    // Create new schedule
                    final TaskSchedule newSchedule = TaskSchedule(
                      subject: subjectController.text,
                      description: descriptionController.text,
                      time: timeString,
                      isGroup: isGroup,
                      location:
                          locationController.text.isEmpty
                              ? null
                              : locationController.text,
                      notes:
                          notesController.text.isEmpty
                              ? null
                              : notesController.text,
                    );

                    // Edit the event
                    final DateTime originalDate = _selectedDay;
                    scheduleNotifier.editEvent(
                      originalDate,
                      schedule,
                      newSchedule,
                    ); // Update selected day if different from current
                    if (!isSameDay(selectedDate, _selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDate;
                        _focusedDay = selectedDate;
                      });
                    }

                    // Update smart features after editing a schedule
                    _updateSmartFeatures();

                    Navigator.pop(context);

                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Study session updated on ${DateFormat('EEEE, MMMM d').format(selectedDate)}',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Method to set a reminder for the study session
  void _setReminderForSession(TaskSchedule schedule) {
    // Extract time from schedule
    String startTime = schedule.time;
    if (schedule.time.contains('-')) {
      startTime = schedule.time.split('-')[0].trim();
    }

    // Parse the time string into a DateTime
    try {
      // Extract hour and minute from time format like "9:00 AM"
      final timeParts = startTime.split(' ');
      final hourMinute = timeParts[0].split(':');
      int hour = int.parse(hourMinute[0]);
      int minute = int.parse(hourMinute[1]);

      // Adjust for PM times
      if (timeParts[1] == 'PM' && hour < 12) {
        hour += 12;
      }
      // Adjust for 12 AM which should be 0 hours
      if (timeParts[1] == 'AM' && hour == 12) {
        hour = 0;
      }

      // Create a DateTime for today with the specified time
      final now = DateTime.now();
      final scheduledTime = DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
        hour,
        minute,
      );

      // Only set reminder for future events
      if (scheduledTime.isBefore(now)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot set reminder for past events'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Create a reminder 15 minutes before the scheduled time
      final reminderTime = scheduledTime.subtract(const Duration(minutes: 15));

      // Show reminder options dialog
      _showReminderOptionsDialog(schedule, reminderTime);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting reminder: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Show reminder options dialog
  void _showReminderOptionsDialog(
    TaskSchedule schedule,
    DateTime reminderTime,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: const Text('15 minutes before'),
                onTap: () {
                  Navigator.pop(context);
                  _scheduleNotification(
                    schedule,
                    reminderTime,
                    '15 minutes before session',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: const Text('30 minutes before'),
                onTap: () {
                  Navigator.pop(context);
                  _scheduleNotification(
                    schedule,
                    reminderTime.subtract(const Duration(minutes: 15)),
                    '30 minutes before session',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active),
                title: const Text('1 hour before'),
                onTap: () {
                  Navigator.pop(context);
                  _scheduleNotification(
                    schedule,
                    reminderTime.subtract(const Duration(minutes: 45)),
                    '1 hour before session',
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  } // Schedule the actual notification

  Future<void> _scheduleNotification(
    TaskSchedule schedule,
    DateTime time,
    String reminderText,
  ) async {
    // Create an instance of the notification helper
    final notificationHelper = NotificationHelper();
    // Get the current user ID to store in Firebase
    final userId = ref.read(firebaseServiceProvider).currentUserId;

    // Schedule the notification with the helper
    final success = await notificationHelper.scheduleReminderForSession(
      context: context,
      schedule: schedule,
      reminderTime: time,
      reminderText: reminderText,
      userId: userId, // Pass the userId for Firebase storage
    );

    // Show success message
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder set for $reminderText'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
    // Error handling is done inside the helper
  } // Method to start a study session

  void _startStudySession(TaskSchedule schedule) {
    // Show a confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Start Study Session'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subject: ${schedule.subject}'),
                const SizedBox(height: 8),
                Text('Description: ${schedule.description}'),
                const SizedBox(height: 16),
                const Text(
                  'Starting this session will track your study time and earn you XP when completed.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(context);

                  // Show snackbar notification
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Started studying ${schedule.subject}'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'End Session',
                        textColor: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          _completeStudySession(schedule);
                        },
                      ),
                    ),
                  );

                  // Use the notification helper to show the notification and store in Firestore
                  final notificationHelper = NotificationHelper();
                  final userId =
                      ref.read(firebaseServiceProvider).currentUserId;

                  await notificationHelper.notifySessionStarted(
                    context: context,
                    schedule: schedule,
                    userId: userId,
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Now'),
              ),
            ],
          ),
    );
  } // Method called when a study session is completed

  void _completeStudySession(TaskSchedule schedule) {
    // Show completion dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Session Completed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You completed studying ${schedule.subject}!'),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 24),
                    SizedBox(width: 8),
                    Text(
                      '+15 XP',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );

    // Show a notification for completion using the notification helper
    try {
      final notificationHelper = NotificationHelper();
      final userId = ref.read(firebaseServiceProvider).currentUserId;

      notificationHelper.notifySessionCompleted(
        context: context,
        schedule: schedule,
        userId: userId,
      );

      // Update the user's XP (would be implemented in a real app)
      // userService.addExperiencePoints(15);
    } catch (e) {
      debugPrint('Failed to show completion notification: $e');
    }
  }
}
