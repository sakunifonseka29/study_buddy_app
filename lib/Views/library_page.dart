import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:study_buddy_app/Service/cloudinaryService.dart';
import 'package:study_buddy_app/Service/resourceService.dart';
import 'package:study_buddy_app/Models/studyresaurceModel.dart';
import 'package:study_buddy_app/providerService.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;

// Provider for resources based on selected subject
final resourcesProvider = FutureProvider.family<List<StudyResource>, String>((
  ref,
  String subject,
) async {
  if (subject.isEmpty) {
    return [];
  }
  return ref.watch(resourceServiceProvider).getResourcesBySubject(subject);
});

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  String _selectedSubject = '';
  bool _isUploading = false;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // List of available subjects
  final List<String> _subjects = [
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
    _initSelectedSubject();
  }

  void _initSelectedSubject() async {
    // Get the user's subjects and select the first one by default
    final userAsync = await ref.read(currentUserDataProvider.future);
    if (userAsync != null && userAsync.subjects.isNotEmpty) {
      setState(() {
        _selectedSubject = userAsync.subjects.first;
      });
    } else if (_subjects.isNotEmpty) {
      setState(() {
        _selectedSubject = _subjects.first;
      });
    }
  }

  Future<void> _uploadFile() async {
    setState(() {
      _isUploading = true;
    });

    try {
      // Get current user ID
      final userId = ref.read(firebaseServiceProvider).currentUserId;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Pick a file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      // Determine the resource type based on file extension
      final extension = path.extension(fileName).toLowerCase();
      String resourceType;

      if (extension == '.pdf') {
        resourceType = 'PDF';
      } else if (extension == '.doc' ||
          extension == '.docx' ||
          extension == '.txt') {
        resourceType = 'Document';
      } else if (extension == '.ppt' || extension == '.pptx') {
        resourceType = 'Presentation';
      } else {
        resourceType = 'Other';
      } // Upload to Cloudinary
      final fileUrl = await _cloudinaryService.uploadFile(
        file: file,
        userId: userId,
        folder: 'study_materials',
      );

      if (fileUrl == null) {
        throw Exception(
          'Failed to upload file to Cloudinary. Please check your Cloudinary credentials.',
        );
      }

      // Create resource entry in database
      await ref
          .read(resourceServiceProvider)
          .addResource(
            title: fileName,
            subject: _selectedSubject,
            description:
                'Uploaded on ${DateTime.now().toString().split(' ')[0]}',
            url: fileUrl,
            resourceType: resourceType,
            uploaderId: userId,
            tags: [_selectedSubject, resourceType],
          );

      // Success message
      if (mounted) {
        // Refresh the resource list to show the newly uploaded file
        final _ = ref.refresh(resourcesProvider(_selectedSubject));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!')),
        );
      }
    } catch (e) {
      // Error message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _openDocument(String url, String resourceType) async {
    if (resourceType == 'PDF') {
      _showPdfViewer(url);
    } else {
      // For other types, try to launch URL in browser
      final urlUri = Uri.parse(url);
      if (await canLaunchUrl(urlUri)) {
        await launchUrl(urlUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the document')),
          );
        }
      }
    }
  }

  void _showPdfViewer(String url) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('PDF Viewer'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: SfPdfViewer.network(url),
            ),
          ),
    );
  }

  Widget _buildSubjectFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButtonFormField<String>(
        value: _selectedSubject.isEmpty ? null : _selectedSubject,
        hint: const Text('Select a subject'),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        items:
            _subjects
                .map(
                  (subject) =>
                      DropdownMenuItem(value: subject, child: Text(subject)),
                )
                .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedSubject = value;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resourcesAsync = ref.watch(resourcesProvider(_selectedSubject));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Library'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Browse study materials by subject',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _buildSubjectFilter(),
                const SizedBox(height: 16),
                const Divider(),
              ],
            ),
          ),

          // Resource list
          Expanded(
            child: resourcesAsync.when(
              data: (resources) {
                if (resources.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No study materials found for this subject.',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Upload your first document with the button below.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: resources.length,
                  itemBuilder: (context, index) {
                    final resource = resources[index];
                    return _buildResourceCard(resource);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${error.toString()}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _uploadFile,
        backgroundColor: Colors.deepPurple,
        child:
            _isUploading
                ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                : const Icon(Icons.upload_file),
      ),
    );
  }

  Widget _buildResourceCard(StudyResource resource) {
    IconData iconData;

    switch (resource.resourceType) {
      case 'PDF':
        iconData = Icons.picture_as_pdf;
        break;
      case 'Document':
        iconData = Icons.description;
        break;
      case 'Presentation':
        iconData = Icons.slideshow;
        break;
      default:
        iconData = Icons.insert_drive_file;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _openDocument(resource.url, resource.resourceType),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(iconData, size: 30, color: Colors.deepPurple),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      resource.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${resource.uploadDate.day}/${resource.uploadDate.month}/${resource.uploadDate.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.thumb_up,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${resource.upvotes}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          resource.tags
                              .map(
                                (tag) => Chip(
                                  label: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: Colors.grey.shade200,
                                  labelStyle: TextStyle(
                                    color: Colors.grey.shade800,
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                ),
                              )
                              .toList(),
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
