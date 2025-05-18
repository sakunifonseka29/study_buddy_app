import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:study_buddy_app/Models/userModel.dart';
import 'package:study_buddy_app/Service/cloudinaryTestUtil.dart';
import 'package:study_buddy_app/Views/subject_preference_page.dart';
import 'package:study_buddy_app/providerService.dart';
import 'package:study_buddy_app/Views/update_subjects_page.dart';
import 'package:study_buddy_app/widgets/study_buddy_matching_widget.dart';
import 'package:study_buddy_app/Views/login_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  File? _imageFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check if user is authenticated when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  // Check if user is authenticated and redirect if not
  void _checkAuthStatus() {
    final authState = ref.read(authStateProvider).value;
    if (authState == null) {
      _redirectToLogin();
    }
  }

  // Redirect to login page
  void _redirectToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _imageFile = File(pickedFile.path);
      });

      // Upload the image
      await _uploadImage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = ref.read(firebaseServiceProvider).currentUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Upload to Cloudinary using the UserService
      final imageUrl = await ref
          .read(userServiceProvider)
          .uploadProfileImage(userId, _imageFile!);

      if (imageUrl == null) {
        throw Exception('Failed to upload image to Cloudinary');
      }

      // The userServiceProvider.uploadProfileImage method already updates the user profile in Firestore      // Refresh the user data
      await ref.refresh(currentUserDataProvider.future);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _imageFile = null;
        });
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }

  // Test Cloudinary connection
  void _testCloudinaryConnection() async {
    await CloudinaryTestUtil.testCloudinaryConnection(context);
  }

  @override
  Widget build(BuildContext context) {
    // Watch both auth state and user data
    final authState = ref.watch(authStateProvider);
    final userDataAsyncValue = ref.watch(currentUserDataProvider);

    // Handle authentication state
    return authState.when(
      data: (user) {
        if (user == null) {
          // Redirect to login if not authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _redirectToLogin();
          });
          return const Scaffold(
            body: Center(child: Text('Not authenticated, redirecting...')),
          );
        }

        // User is authenticated, show profile
        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                // Refresh user data when pulled down
                return ref.refresh(currentUserDataProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Top bar with Study Buddy text in the center
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
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
                    const SizedBox(height: 20),

                    // Profile content
                    userDataAsyncValue.when(
                      data: (userData) {
                        if (userData == null) {
                          // Show button to create profile if user exists but has no profile
                          return _buildCreateProfilePrompt();
                        }
                        return _buildProfileContent(userData);
                      },
                      loading:
                          () => const SizedBox(
                            height: 300,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      error:
                          (error, stack) => SizedBox(
                            height: 300,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Error: $error'),
                                  ElevatedButton(
                                    onPressed:
                                        () => ref.refresh(
                                          currentUserDataProvider,
                                        ),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error:
          (error, stackTrace) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Authentication error: $error'),
                  ElevatedButton(
                    onPressed: () => ref.refresh(authStateProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildCreateProfilePrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(
                Icons.person_outline,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 20),
              const Text(
                'Profile Not Found',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'It looks like your profile data is missing. Let\'s set up your profile now.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  final userId =
                      ref.read(firebaseServiceProvider).currentUserId;
                  if (userId != null) {
                    // Navigate to subject preference page to create profile
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => SubjectPreferencePage(
                              userId: userId,
                              name: "User", // Default name
                              email:
                                  ref
                                      .read(authServiceProvider)
                                      .currentUser
                                      ?.email ??
                                  "",
                            ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                ),
                child: const Text('Set Up Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile picture
              Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: _showImageSourceActionSheet,
                    child: Hero(
                      tag: 'profileImage',
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            user.profileImageUrl != null
                                ? NetworkImage(user.profileImageUrl!)
                                : null,
                        child:
                            user.profileImageUrl == null
                                ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                                : null,
                      ),
                    ),
                  ),
                  if (_isLoading) const CircularProgressIndicator(),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // User name
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // User email
              Text(
                user.email,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              // Stats section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    user.studyGroupIds.length.toString(),
                    'Groups',
                  ),
                  const VerticalDivider(
                    color: Colors.grey,
                    thickness: 1,
                    width: 1,
                    indent: 10,
                    endIndent: 10,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const UpdateSubjectsPage(),
                        ),
                      );
                    },
                    child: _buildStatItem(
                      user.subjects.length.toString(),
                      'Subjects',
                      showEditIcon: true,
                    ),
                  ),
                  const VerticalDivider(
                    color: Colors.grey,
                    thickness: 1,
                    width: 1,
                    indent: 10,
                    endIndent: 10,
                  ),
                  _buildStatItem(user.totalPoints.toString(), 'Points'),
                ],
              ),

              const SizedBox(height: 24),

              // Find Study Buddies button
              const Center(child: FindStudyBuddiesButton()),

              const SizedBox(height: 24), // Test Cloudinary Connection Button
              TextButton.icon(
                onPressed: _testCloudinaryConnection,
                icon: const Icon(Icons.cloud_upload, color: Colors.deepPurple),
                label: const Text(
                  'Test Cloudinary Connection',
                  style: TextStyle(color: Colors.deepPurple),
                ),
              ),

              const SizedBox(height: 16),

              // Logout Button
              ElevatedButton.icon(
                onPressed: () async {
                  // Show confirmation dialog
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text(
                            'Are you sure you want to logout?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                  );
                  if (shouldLogout == true) {
                    try {
                      // Invalidate all cached providers to force data refresh on next login
                      ref.invalidate(currentUserDataProvider);
                      ref.invalidate(userTasksProvider);
                      ref.invalidate(userOngoingTasksProvider);
                      ref.invalidate(weeklyPointsProvider);
                      ref.invalidate(userStudyGroupsProvider);
                      ref.invalidate(leaderboardProvider);

                      // Then sign out
                      await ref.read(authServiceProvider).signOut();

                      if (context.mounted) {
                        _redirectToLogin();
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to log out: $e')),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label, {
    bool showEditIcon = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            if (showEditIcon)
              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: Icon(Icons.edit, size: 16, color: Colors.deepPurple),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
