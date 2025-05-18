import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/Models/userModel.dart';
import 'package:study_buddy_app/Views/groups_page.dart';
import 'package:study_buddy_app/providerService.dart';
import 'package:study_buddy_app/widgets/user_search_widget.dart';

class CreateGroupPage extends ConsumerStatefulWidget {
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  String selectedSubject = '';
  bool isPublic = true;
  List<User> selectedUsers = [];
  List<User> searchResults = [];
  bool isSearching = false;
  bool isCreating = false;

  // Full list of available subjects
  final List<String> _allSubjects = [
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

  @override
  void initState() {
    super.initState();
    // Add the current user to selected users if they're not already there
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserDataProvider).value;
      if (currentUser != null &&
          selectedUsers.isEmpty &&
          !selectedUsers.any((u) => u.userId == currentUser.userId)) {
        setState(() {
          selectedUsers = [currentUser];
        });
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // Function to search for users
  void searchUsers(String query) async {
    if (query.length < 2) {
      if (mounted) {
        setState(() {
          searchResults = [];
          isSearching = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        isSearching = true;
      });
    }

    try {
      final results = await ref
          .read(userServiceProvider)
          .searchUsers(
            query,
            excludeIds: selectedUsers.map((u) => u.userId).toList(),
          );

      if (mounted) {
        setState(() {
          searchResults = results;
          isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching users: $e')));
      }
    }
  }

  // Function to create a study group
  Future<void> createGroup() async {
    if (formKey.currentState?.validate() ?? false) {
      setState(() {
        isCreating = true;
      });

      try {
        final userId = ref.read(firebaseServiceProvider).currentUserId;
        if (userId == null) {
          throw Exception('User not logged in');
        }

        // Create the group with selected members
        final createdGroup = await ref
            .read(studyGroupServiceProvider)
            .createStudyGroup(
              groupName: nameController.text.trim(),
              subject: selectedSubject,
              description: descriptionController.text.trim(),
              creatorId: userId,
              isPublic: isPublic,
            );

        // Add selected users to the group
        for (final user in selectedUsers) {
          if (user.userId != userId) {
            // Skip the creator as they're already added
            await ref
                .read(studyGroupServiceProvider)
                .joinStudyGroup(createdGroup.groupId, user.userId);
          }
        }

        // Refresh groups and go back
        if (mounted) {
          ref.invalidate(userStudyGroupsProvider);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group created successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error creating group: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            isCreating = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Study Group'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Subject dropdown
                if (_allSubjects.isEmpty)
                  const Text(
                    'Please add subjects to your profile first',
                    style: TextStyle(color: Colors.red),
                  )
                else
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedSubject.isNotEmpty ? selectedSubject : null,
                    items:
                        _allSubjects.map((subject) {
                          return DropdownMenuItem(
                            value: subject,
                            child: Text(subject),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedSubject = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a subject';
                      }
                      return null;
                    },
                  ),

                const SizedBox(height: 24),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    helperText: 'Describe the purpose of your study group',
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Group privacy settings
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Privacy Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Public Group'),
                        subtitle: const Text(
                          'Allow others to find and join this group',
                        ),
                        value: isPublic,
                        activeColor: Colors.deepPurple,
                        onChanged: (value) {
                          setState(() {
                            isPublic = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // User search widget
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Members',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      UserSearchWidget(
                        onSearch: searchUsers,
                        searchResults: searchResults,
                        selectedUsers: selectedUsers,
                        onUserSelected: (user) {
                          setState(() {
                            selectedUsers.add(user);
                          });
                        },
                        onUserRemoved: (user) {
                          // Don't allow removing the current user
                          final currentUser =
                              ref.read(currentUserDataProvider).value;
                          if (currentUser?.userId == user.userId) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'You cannot remove yourself from the group',
                                ),
                              ),
                            );
                            return;
                          }

                          setState(() {
                            selectedUsers.removeWhere(
                              (u) => u.userId == user.userId,
                            );
                          });
                        },
                        isLoading: isSearching,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Create group button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isCreating ? null : createGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        isCreating
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Create Group',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
