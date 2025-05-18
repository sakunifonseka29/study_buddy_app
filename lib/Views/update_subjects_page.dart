import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/providerService.dart';

class UpdateSubjectsPage extends ConsumerStatefulWidget {
  const UpdateSubjectsPage({super.key});

  @override
  ConsumerState<UpdateSubjectsPage> createState() => _UpdateSubjectsPageState();
}

class _UpdateSubjectsPageState extends ConsumerState<UpdateSubjectsPage> {
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

  List<String> _selectedSubjects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSubjects();
  }

  Future<void> _loadCurrentSubjects() async {
    final userAsync = ref.read(currentUserDataProvider);

    userAsync.whenData((user) {
      if (user != null) {
        setState(() {
          _selectedSubjects = List<String>.from(user.subjects);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Subjects'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 40),
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
                            _selectedSubjects.isEmpty ? null : _saveSubjects,
                        child: const Text(
                          'Save Changes',
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
    );
  }

  Future<void> _saveSubjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = ref.read(firebaseServiceProvider).currentUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Update user subjects
      await ref
          .read(userServiceProvider)
          .updateUserSubjects(userId, _selectedSubjects);

      // Refresh the user data
      ref.refresh(currentUserDataProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subjects updated successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating subjects: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
