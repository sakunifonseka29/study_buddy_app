import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/Models/userModel.dart';
import 'package:study_buddy_app/Views/dashbord.dart';
import 'package:study_buddy_app/providerService.dart';

class SubjectPreferencePage extends ConsumerStatefulWidget {
  final String userId;
  final String name;
  final String email;

  const SubjectPreferencePage({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
  });

  @override
  ConsumerState<SubjectPreferencePage> createState() =>
      _SubjectPreferencePageState();
}

class _SubjectPreferencePageState extends ConsumerState<SubjectPreferencePage> {
  final List<String> _availableSubjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'History',
    'Geography',
    'Literature',
    'Economics',
    'Business Studies',
    'Psychology',
    'Sociology',
    'Art',
    'Music',
    'Physical Education',
    'Foreign Languages',
  ];

  final List<String> _selectedSubjects = [];

  // Study preferences
  String _preferredStudyTime = 'Morning';
  String _studyDuration = '1-2 hours';
  String _studyFrequency = 'Daily';
  bool _isLoading = false;

  final List<String> _studyTimeOptions = [
    'Morning',
    'Afternoon',
    'Evening',
    'Night',
  ];
  final List<String> _durationOptions = [
    '30-60 minutes',
    '1-2 hours',
    '2-3 hours',
    '3+ hours',
  ];
  final List<String> _frequencyOptions = [
    'Daily',
    'Few times a week',
    'Weekends only',
    'As needed',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Welcome, ${widget.name}!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Let\'s personalize your study experience',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 30),

                      // Subjects section
                      const Text(
                        'Select your subjects',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Choose the subjects you\'re studying or interested in',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            _availableSubjects.map((subject) {
                              final isSelected = _selectedSubjects.contains(
                                subject,
                              );
                              return FilterChip(
                                selected: isSelected,
                                label: Text(subject),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedSubjects.add(subject);
                                    } else {
                                      _selectedSubjects.remove(subject);
                                    }
                                  });
                                },
                                selectedColor: Colors.deepPurple.shade100,
                                checkmarkColor: Colors.deepPurple,
                                backgroundColor: Colors.grey.shade200,
                              );
                            }).toList(),
                      ),

                      const SizedBox(height: 30),

                      // Study preferences section
                      const Text(
                        'Study Preferences',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Preferred study time
                      const Text(
                        'When do you prefer to study?',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children:
                            _studyTimeOptions.map((time) {
                              return ChoiceChip(
                                label: Text(time),
                                selected: _preferredStudyTime == time,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _preferredStudyTime = time;
                                    });
                                  }
                                },
                                selectedColor: Colors.deepPurple.shade100,
                                backgroundColor: Colors.grey.shade200,
                              );
                            }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Study duration
                      const Text(
                        'How long do you typically study in one session?',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children:
                            _durationOptions.map((duration) {
                              return ChoiceChip(
                                label: Text(duration),
                                selected: _studyDuration == duration,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _studyDuration = duration;
                                    });
                                  }
                                },
                                selectedColor: Colors.deepPurple.shade100,
                                backgroundColor: Colors.grey.shade200,
                              );
                            }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Study frequency
                      const Text(
                        'How often do you study?',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children:
                            _frequencyOptions.map((frequency) {
                              return ChoiceChip(
                                label: Text(frequency),
                                selected: _studyFrequency == frequency,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _studyFrequency = frequency;
                                    });
                                  }
                                },
                                selectedColor: Colors.deepPurple.shade100,
                                backgroundColor: Colors.grey.shade200,
                              );
                            }).toList(),
                      ),

                      const SizedBox(height: 40),

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed:
                              _selectedSubjects.isEmpty
                                  ? null
                                  : _savePreferences,
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      if (_selectedSubjects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Center(
                            child: Text(
                              'Please select at least one subject',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create user preferences map
      final Map<String, dynamic> preferences = {
        'preferredStudyTime': _preferredStudyTime,
        'studyDuration': _studyDuration,
        'studyFrequency': _studyFrequency,
      };

      // Create user with preferences and subjects
      final user = User(
        userId: widget.userId,
        name: widget.name,
        email: widget.email,
        studyGroupIds: [],
        subjects: _selectedSubjects,
        preferences: preferences,
        totalPoints: 0,
        createdAt: DateTime.now(),
      );

      // Use UserService to update the user
      await ref.read(userServiceProvider).createUser(user);

      if (mounted) {
        // Navigate to dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Dashboard()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving preferences: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
