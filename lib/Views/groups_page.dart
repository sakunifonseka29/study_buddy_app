import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_buddy_app/Models/studygroupModel.dart';
import 'package:study_buddy_app/providerService.dart';
import 'package:study_buddy_app/Views/group_chat_page.dart';
import 'package:study_buddy_app/Views/create_group_page.dart';
import 'package:intl/intl.dart';

// Provider for available subjects from the current user
final availableSubjectsProvider = FutureProvider<List<String>>((ref) async {
  final user = await ref.watch(currentUserDataProvider.future);
  if (user == null) {
    return [];
  }
  return user.subjects;
});

// Provider for filtered study groups
final filteredStudyGroupsProvider = Provider.family<List<StudyGroup>, String?>((
  ref,
  String? subjectFilter,
) {
  final groups = ref.watch(userStudyGroupsProvider).value ?? [];
  if (subjectFilter == null) {
    return groups;
  }
  return groups.where((group) => group.subject == subjectFilter).toList();
});

class GroupsPage extends ConsumerStatefulWidget {
  const GroupsPage({super.key});

  @override
  ConsumerState<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends ConsumerState<GroupsPage> {
  String? _selectedSubject;

  @override
  Widget build(BuildContext context) {
    final allGroups = ref.watch(userStudyGroupsProvider);
    final availableSubjects = ref.watch(availableSubjectsProvider);
    final filteredGroups = ref.watch(
      filteredStudyGroupsProvider(_selectedSubject),
    );

    final displayGroups = filteredGroups;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with "Study Buddy" text
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: const Center(
                child: Text(
                  'Study Buddy',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main title "Study Groups"
                    const Text(
                      'Study Groups',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Create group button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateGroupPage(),
                              ),
                            ),
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Group'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Filter chips (subjects)
                    const Text(
                      'Filter by subject:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    availableSubjects.when(
                      data:
                          (subjects) => SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: FilterChip(
                                    label: const Text('All'),
                                    selected: _selectedSubject == null,
                                    onSelected: (_) {
                                      setState(() => _selectedSubject = null);
                                    },
                                    backgroundColor: Colors.grey.shade200,
                                    selectedColor: Colors.deepPurple.shade100,
                                  ),
                                ),
                                ...subjects.map(
                                  (subject) => _buildFilterChip(subject),
                                ),
                              ],
                            ),
                          ),
                      loading:
                          () =>
                              const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('Failed to load subjects'),
                    ),
                    const SizedBox(height: 20),

                    // Groups list
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedSubject == null
                              ? 'Your Groups'
                              : 'Groups: $_selectedSubject',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        allGroups.when(
                          data:
                              (groups) => Text(
                                '${displayGroups.length} group${displayGroups.length != 1 ? 's' : ''}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Groups list view
                    Expanded(
                      child: allGroups.when(
                        data: (groups) {
                          if (groups.isEmpty) {
                            return const Center(
                              child: Text(
                                'You haven\'t joined any study groups yet.\nUse the button below to join a group.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          if (displayGroups.isEmpty) {
                            return const Center(
                              child: Text(
                                'No groups match your current filters',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }
                          return RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(userStudyGroupsProvider);
                              return await ref.read(
                                userStudyGroupsProvider.future,
                              );
                            },
                            child: ListView.builder(
                              itemCount: displayGroups.length,
                              itemBuilder: (context, index) {
                                final group = displayGroups[index];
                                return _buildGroupCard(
                                  group.groupName,
                                  group.subject,
                                  '${group.memberIds.length} member${group.memberIds.length != 1 ? 's' : ''}',
                                  _getNextSessionText(group),
                                  onViewDetails:
                                      () => _showGroupDetailsDialog(group),
                                  onChat: () => _navigateToGroupChat(group),
                                );
                              },
                            ),
                          );
                        },
                        loading:
                            () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                        error:
                            (error, stack) => Center(
                              child: Text('Error: ${error.toString()}'),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: _selectedSubject == label,
        onSelected: (bool selected) {
          setState(() {
            _selectedSubject = selected ? label : null;
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.deepPurple.shade100,
      ),
    );
  }

  Widget _buildGroupCard(
    String name,
    String subject,
    String members,
    String nextMeeting, {
    required VoidCallback onViewDetails,
    required VoidCallback onChat,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.deepPurple,
                    ),
                  ),
                  backgroundColor: Colors.deepPurple.shade50,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(members),
            const SizedBox(height: 5),
            Text(nextMeeting),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onViewDetails,
                  child: const Text('View Details'),
                ),
                TextButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getNextSessionText(StudyGroup group) {
    if (group.nextSessionTime != null) {
      final formatter = DateFormat('E, MMM d, h:mm a');
      return 'Next meeting: ${formatter.format(group.nextSessionTime!)}';
    }
    return 'No upcoming meetings scheduled';
  }
  // Removed the _showCreateGroupDialog method as we now navigate to a dedicated page

  void _showGroupDetailsDialog(StudyGroup group) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(group.groupName),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    label: Text(
                      group.subject,
                      style: const TextStyle(color: Colors.deepPurple),
                    ),
                    backgroundColor: Colors.deepPurple.shade50,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(group.description),
                  const SizedBox(height: 16),
                  Text(
                    'Members (${group.memberIds.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder(
                    future: _fetchGroupMembersDetails(group.memberIds),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      final members = snapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            members
                                .map(
                                  (member) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Text(member),
                                  ),
                                )
                                .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (group.nextSessionTime != null) ...[
                    Text(
                      'Next Meeting',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat(
                        'EEEE, MMMM d, y - h:mm a',
                      ).format(group.nextSessionTime!),
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Ok'),
              ),
            ],
          ),
    );
  }

  Future<List<String>> _fetchGroupMembersDetails(List<String> memberIds) async {
    final userService = ref.read(userServiceProvider);
    final members = <String>[];

    for (final id in memberIds) {
      try {
        final user = await userService.getUser(id);
        if (user != null) {
          members.add(user.name);
        }
      } catch (e) {
        // Skip users that couldn't be fetched
      }
    }

    return members;
  }

  void _navigateToGroupChat(StudyGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupChatPage(group: group)),
    );
  }
}
