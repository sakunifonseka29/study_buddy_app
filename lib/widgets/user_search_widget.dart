import 'package:flutter/material.dart';
import 'package:study_buddy_app/Models/userModel.dart';
import 'dart:async';

class UserSearchWidget extends StatefulWidget {
  final Function(String) onSearch;
  final List<User> searchResults;
  final List<User> selectedUsers;
  final Function(User) onUserSelected;
  final Function(User) onUserRemoved;
  final bool isLoading;

  const UserSearchWidget({
    super.key,
    required this.onSearch,
    required this.searchResults,
    required this.selectedUsers,
    required this.onUserSelected,
    required this.onUserRemoved,
    this.isLoading = false,
  });

  @override
  State<UserSearchWidget> createState() => _UserSearchWidgetState();
}

class _UserSearchWidgetState extends State<UserSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    debouncer.run(() {
      widget.onSearch(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search box
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search users by name or email',
            hintText: 'Type at least 3 characters',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                    : null,
          ),
        ),
        const SizedBox(height: 16),

        // Selected users section
        if (widget.selectedUsers.isNotEmpty) ...[
          const Text(
            'Selected Users:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.selectedUsers.map((user) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                      child:
                          user.profileImageUrl == null
                              ? Text(user.name[0].toUpperCase())
                              : null,
                    ),
                    label: Text(user.name),
                    onDeleted: () => widget.onUserRemoved(user),
                    deleteIconColor: Colors.deepPurple,
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Search results section
        if (_searchController.text.isNotEmpty) ...[
          const Text(
            'Search Results:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (widget.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (widget.searchResults.isEmpty)
            const Text('No users found. Try a different search term.')
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: widget.searchResults.length,
                itemBuilder: (context, index) {
                  final user = widget.searchResults[index];
                  final isSelected = widget.selectedUsers.any(
                    (selected) => selected.userId == user.userId,
                  );

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          user.profileImageUrl != null
                              ? NetworkImage(user.profileImageUrl!)
                              : null,
                      child:
                          user.profileImageUrl == null
                              ? Text(user.name[0].toUpperCase())
                              : null,
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    trailing: IconButton(
                      icon: Icon(
                        isSelected ? Icons.remove_circle : Icons.add_circle,
                        color: isSelected ? Colors.red : Colors.deepPurple,
                      ),
                      onPressed: () {
                        if (isSelected) {
                          widget.onUserRemoved(user);
                        } else {
                          widget.onUserSelected(user);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}

/// Helper class for debouncing search requests
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
