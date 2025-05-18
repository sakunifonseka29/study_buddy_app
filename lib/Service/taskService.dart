import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:study_buddy_app/Models/task_model.dart';
import 'package:study_buddy_app/Models/suggested_task_model.dart';
import 'package:study_buddy_app/Service/firebaseService.dart';
import 'package:study_buddy_app/Service/rewardService.dart';
import 'package:study_buddy_app/Service/notificationService.dart';

class TaskService extends FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RewardService _rewardService = RewardService();

  // Collection reference for tasks
  CollectionReference get tasksCollection => _firestore.collection('tasks');

  // Collection reference for suggested tasks
  CollectionReference get suggestedTasksCollection =>
      _firestore.collection('suggestedTasks');

  // Create a new task
  Future<Task> createTask({
    required String userId,
    required String title,
    required String description,
    required DateTime dueDate,
    required String subject,
  }) async {
    try {
      final docRef = tasksCollection.doc();
      // Generate random XP between 5 and 50
      final int xpPoints = Random().nextInt(46) + 5; // 5 to 50 range

      final task = Task(
        id: docRef.id,
        userId: userId,
        title: title,
        description: description,
        dueDate: dueDate,
        xpPoints: xpPoints,
        subject: subject,
        createdAt: DateTime.now(),
      );

      await docRef.set(task.toMap());
      return task;
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // Get all tasks for a user
  Future<List<Task>> getUserTasks(String userId) async {
    try {
      final snapshot =
          await tasksCollection
              .where('userId', isEqualTo: userId)
              .orderBy('dueDate')
              .get();

      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user tasks: $e');
    }
  }

  // Get ongoing tasks for a user
  Future<List<Task>> getUserOngoingTasks(String userId) async {
    try {
      final snapshot =
          await tasksCollection
              .where('userId', isEqualTo: userId)
              .where('isCompleted', isEqualTo: false)
              .orderBy('dueDate')
              .get();

      return snapshot.docs
          .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user ongoing tasks: $e');
    }
  }

  // Get suggested tasks based on subject
  Future<List<Task>> getSuggestedTasks(String userId, String subject) async {
    try {
      // First try to get actual user tasks for this subject
      final snapshot =
          await tasksCollection
              .where('userId', isEqualTo: userId)
              .where('subject', isEqualTo: subject)
              .orderBy('dueDate')
              .limit(10) // Get more tasks so we can filter them
              .get();

      final allUserTasks =
          snapshot.docs
              .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

      // Filter tasks to include:
      // 1. Incomplete tasks
      // 2. Completed tasks that were completed more than 24 hours ago (they should reappear)
      final now = DateTime.now();
      final userTasks =
          allUserTasks
              .where((task) {
                // If task isn't completed, include it
                if (!task.isCompleted) return true;

                // If task is completed, check if 24 hours have passed since completion
                // For simplicity, we'll use task.dueDate as a proxy for completion date
                // In a real app, you'd store the actual completion timestamp
                final completionTime = task.dueDate;

                // If completed less than 24 hours ago, don't show it
                return now.difference(completionTime).inHours >= 24;
              })
              .take(5)
              .toList();

      // If we have enough user tasks, return them
      if (userTasks.length >= 3) {
        return userTasks;
      }

      // Otherwise, try to get suggested task templates
      List<SuggestedTask> templates = await getSuggestedTaskTemplates(subject);

      // If no templates exist, create some random ones for this subject
      if (templates.isEmpty) {
        templates = _generateRandomSuggestedTasks(subject);
      }

      // Randomly select up to 5 templates
      templates.shuffle();
      final selectedTemplates = templates.take(5 - userTasks.length).toList();

      // Convert templates to tasks
      final suggestedTasks =
          selectedTemplates.map((template) {
            // Generate a random due date between tomorrow and 2 weeks from now
            final int daysToAdd = Random().nextInt(14) + 1;
            final dueDate = DateTime.now().add(Duration(days: daysToAdd));

            return Task(
              id: 'suggestion_${template.id}',
              userId: userId,
              title: template.title,
              description: template.description,
              dueDate: dueDate,
              xpPoints: template.xpPoints,
              subject: template.subject,
              createdAt: DateTime.now(),
            );
          }).toList();

      // Combine user tasks with suggested tasks
      return [...userTasks, ...suggestedTasks];
    } catch (e) {
      throw Exception('Failed to get suggested tasks: $e');
    }
  }

  // Mark a task as completed and award XP
  Future<void> completeTask(Task task) async {
    try {
      // For suggested tasks (IDs starting with 'suggestion_'), we'll set a completion timestamp
      // This will allow us to make the task reappear after 24 hours
      if (task.id.startsWith('suggestion_')) {
        // For suggestion tasks, create a document in Firestore if it doesn't exist
        // This ensures we have a proper document to update and that XP points can be awarded
        final docRef = tasksCollection.doc(task.id);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          // Create the task document first
          await docRef.set(task.toMap());
        }

        // Then mark it as completed with the current timestamp as completion date
        await docRef.update({
          'isCompleted': true,
          'dueDate': Timestamp.fromDate(
            DateTime.now(),
          ), // Use dueDate as completion timestamp
        });
      } else {
        // Regular task - just mark as completed
        await tasksCollection.doc(task.id).update({'isCompleted': true});
      }

      // Award XP points - make sure this runs after the task document exists
      await _rewardService.addPoints(
        userId: task.userId,
        points: task.xpPoints,
        reason: 'Completed task: ${task.title}',
        relatedActivityId: task.id,
      );
    } catch (e) {
      throw Exception('Failed to complete task: $e');
    }
  }

  // Helper method to check if a suggested task should reappear
  // This would typically be done by a scheduled job or cloud function
  Future<void> checkAndReactivateSuggestedTasks() async {
    try {
      final now = DateTime.now();

      // Get all completed tasks
      final completedSnapshot =
          await tasksCollection.where('isCompleted', isEqualTo: true).get();

      // Then filter client-side for suggestion tasks
      final suggestedTasks =
          completedSnapshot.docs
              .where((doc) => doc.id.startsWith('suggestion_'))
              .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
              .toList();

      // Check each task to see if 24 hours have passed since completion
      for (final task in suggestedTasks) {
        // Use due date as a proxy for completion date
        final completionTime = task.dueDate;

        // If 24 hours have passed since completion, reactivate the task
        if (now.difference(completionTime).inHours >= 24) {
          await tasksCollection.doc(task.id).update({
            'isCompleted': false,
            'dueDate': Timestamp.fromDate(
              now.add(const Duration(days: 7)),
            ), // New due date 1 week from now
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to reactivate suggested tasks: $e');
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await tasksCollection.doc(taskId).delete();
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  // ------------------------------------------------------------------------
  // Suggested Tasks Methods
  // ------------------------------------------------------------------------

  // Create a new suggested task template
  Future<SuggestedTask> createSuggestedTaskTemplate({
    required String title,
    required String description,
    required String subject,
    required int xpPoints,
    required int difficultyLevel,
  }) async {
    try {
      final docRef = suggestedTasksCollection.doc();

      final suggestedTask = SuggestedTask(
        id: docRef.id,
        title: title,
        description: description,
        subject: subject,
        xpPoints: xpPoints,
        difficultyLevel: difficultyLevel,
      );

      await docRef.set(suggestedTask.toMap());
      return suggestedTask;
    } catch (e) {
      throw Exception('Failed to create suggested task template: $e');
    }
  }

  // Get all suggested task templates for a specific subject
  Future<List<SuggestedTask>> getSuggestedTaskTemplates(String subject) async {
    try {
      final snapshot =
          await suggestedTasksCollection
              .where('subject', isEqualTo: subject)
              .get();

      return snapshot.docs
          .map(
            (doc) => SuggestedTask.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get suggested task templates: $e');
    }
  }

  // Generate random suggested tasks for a subject
  List<SuggestedTask> _generateRandomSuggestedTasks(String subject) {
    // For each subject, we'll have some specific task templates
    final Map<String, List<Map<String, dynamic>>> subjectTaskTemplates = {
      'Mathematics': [
        {
          'title': 'Complete Practice Problems',
          'description':
              'Solve 10 practice problems on ${_getRandomTopic('Mathematics')}',
        },
        {
          'title': 'Review Formulas',
          'description':
              'Create a cheat sheet for ${_getRandomTopic('Mathematics')} formulas',
        },
        {
          'title': 'Watch Tutorial Video',
          'description':
              'Watch a video tutorial on ${_getRandomTopic('Mathematics')}',
        },
        {
          'title': 'Create Mind Map',
          'description':
              'Create a mind map connecting concepts in ${_getRandomTopic('Mathematics')}',
        },
        {
          'title': 'Study Group Session',
          'description':
              'Organize a study session focusing on ${_getRandomTopic('Mathematics')}',
        },
      ],
      'Physics': [
        {
          'title': 'Lab Report',
          'description':
              'Write a lab report on ${_getRandomTopic('Physics')} experiment',
        },
        {
          'title': 'Problem Set',
          'description':
              'Complete the problem set on ${_getRandomTopic('Physics')}',
        },
        {
          'title': 'Conceptual Questions',
          'description':
              'Answer conceptual questions about ${_getRandomTopic('Physics')}',
        },
        {
          'title': 'Review Equations',
          'description':
              'Create a reference sheet for ${_getRandomTopic('Physics')} equations',
        },
        {
          'title': 'Watch Documentary',
          'description':
              'Watch a documentary about ${_getRandomTopic('Physics')}',
        },
      ],
      'Chemistry': [
        {
          'title': 'Element Research',
          'description':
              'Research and create a profile for an assigned element',
        },
        {
          'title': 'Balancing Equations',
          'description':
              'Practice balancing chemical equations for ${_getRandomTopic('Chemistry')}',
        },
        {
          'title': 'Lab Preparation',
          'description':
              'Prepare for the upcoming lab on ${_getRandomTopic('Chemistry')}',
        },
        {
          'title': 'Periodic Table Review',
          'description': 'Review periodic table trends and properties',
        },
        {
          'title': 'Molecular Drawing',
          'description':
              'Draw molecular structures for compounds in ${_getRandomTopic('Chemistry')}',
        },
      ],
      'Biology': [
        {
          'title': 'Cell Diagram',
          'description':
              'Create a detailed diagram of a cell type in ${_getRandomTopic('Biology')}',
        },
        {
          'title': 'Ecosystem Analysis',
          'description':
              'Analyze the components of an ecosystem for ${_getRandomTopic('Biology')}',
        },
        {
          'title': 'Research Assignment',
          'description':
              'Research recent advances in ${_getRandomTopic('Biology')}',
        },
        {
          'title': 'Chapter Summary',
          'description':
              'Create a summary of the chapter on ${_getRandomTopic('Biology')}',
        },
        {
          'title': 'Species Profile',
          'description':
              'Create a profile for a species related to ${_getRandomTopic('Biology')}',
        },
      ],
      'Computer Science': [
        {
          'title': 'Coding Exercise',
          'description':
              'Complete the coding exercise on ${_getRandomTopic('Computer Science')}',
        },
        {
          'title': 'Algorithm Implementation',
          'description':
              'Implement the algorithm discussed in class for ${_getRandomTopic('Computer Science')}',
        },
        {
          'title': 'Debug Program',
          'description':
              'Find and fix bugs in the provided program for ${_getRandomTopic('Computer Science')}',
        },
        {
          'title': 'Create Flowchart',
          'description':
              'Create a flowchart for a program that ${_getRandomTopic('Computer Science')}',
        },
        {
          'title': 'Documentation',
          'description':
              'Write documentation for your code from the ${_getRandomTopic('Computer Science')} project',
        },
      ],
    };

    // For subjects not explicitly listed, use general templates
    final List<Map<String, dynamic>> generalTemplates = [
      {
        'title': 'Create Study Notes',
        'description':
            'Create comprehensive study notes for the recent topics in $subject',
      },
      {
        'title': 'Review Chapter',
        'description': 'Review and summarize the latest chapter in $subject',
      },
      {
        'title': 'Practice Questions',
        'description':
            'Complete practice questions from your $subject textbook',
      },
      {
        'title': 'Research Topic',
        'description':
            'Research and take notes on a topic in $subject that interests you',
      },
      {
        'title': 'Create Flashcards',
        'description':
            'Create flashcards for key terms and concepts in $subject',
      },
      {
        'title': 'Watch Tutorial',
        'description':
            'Watch and take notes from an online tutorial on a $subject topic',
      },
      {
        'title': 'Prepare Presentation',
        'description': 'Prepare a short presentation on a topic in $subject',
      },
    ];

    // Get the appropriate templates for the subject
    final templates = subjectTaskTemplates[subject] ?? generalTemplates;

    // Generate 5 random suggested tasks
    final result = <SuggestedTask>[];
    for (int i = 0; i < 5; i++) {
      // Get random template
      final template = templates[Random().nextInt(templates.length)];

      // Generate random XP between 10 and 50
      final int xpPoints = Random().nextInt(41) + 10; // 10 to 50 range

      // Generate random difficulty level between 1 and 5
      final int difficultyLevel = Random().nextInt(5) + 1; // 1 to 5 range

      result.add(
        SuggestedTask(
          id: 'random_${subject}_$i',
          title: template['title'] as String,
          description: template['description'] as String,
          subject: subject,
          xpPoints: xpPoints,
          difficultyLevel: difficultyLevel,
        ),
      );
    }

    return result;
  }

  // Get a random topic for a subject
  String _getRandomTopic(String subject) {
    final Map<String, List<String>> subjectTopics = {
      'Mathematics': [
        'Calculus',
        'Algebra',
        'Geometry',
        'Statistics',
        'Trigonometry',
        'Linear Algebra',
        'Number Theory',
        'Differential Equations',
      ],
      'Physics': [
        'Mechanics',
        'Thermodynamics',
        'Electromagnetism',
        'Optics',
        'Quantum Mechanics',
        'Relativity',
        'Nuclear Physics',
        'Fluid Dynamics',
      ],
      'Chemistry': [
        'Organic Chemistry',
        'Inorganic Chemistry',
        'Physical Chemistry',
        'Analytical Chemistry',
        'Biochemistry',
        'Polymer Chemistry',
        'Electrochemistry',
      ],
      'Biology': [
        'Genetics',
        'Ecology',
        'Cell Biology',
        'Evolution',
        'Microbiology',
        'Physiology',
        'Botany',
        'Zoology',
        'Marine Biology',
      ],
      'Computer Science': [
        'Data Structures',
        'Algorithms',
        'Web Development',
        'Databases',
        'Artificial Intelligence',
        'Machine Learning',
        'Operating Systems',
        'Networks',
        'Cybersecurity',
      ],
    };

    final topics =
        subjectTopics[subject] ??
        [
          'Recent Topics',
          'Key Concepts',
          'Important Theories',
          'Fundamental Principles',
        ];
    return topics[Random().nextInt(topics.length)];
  }

  // ------------------------------------------------------------------------
  // Initializing Suggested Tasks Templates in Database
  // ------------------------------------------------------------------------

  // Seed the database with predefined task templates for all subjects
  Future<void> seedSuggestedTaskTemplates() async {
    try {
      // Check if we already have templates
      final snapshot = await suggestedTasksCollection.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        // We already have templates, no need to seed
        return;
      }

      // Define the subjects and their topics
      final Map<String, List<String>> subjectTopics = {
        'Mathematics': [
          'Calculus',
          'Algebra',
          'Geometry',
          'Statistics',
          'Trigonometry',
          'Linear Algebra',
        ],
        'Physics': [
          'Mechanics',
          'Thermodynamics',
          'Electromagnetism',
          'Optics',
          'Quantum Physics',
        ],
        'Chemistry': [
          'Organic Chemistry',
          'Inorganic Chemistry',
          'Physical Chemistry',
          'Biochemistry',
        ],
        'Biology': [
          'Genetics',
          'Ecology',
          'Cell Biology',
          'Evolution',
          'Physiology',
        ],
        'Computer Science': [
          'Algorithms',
          'Data Structures',
          'Web Development',
          'Databases',
          'AI/ML',
        ],
        'History': [
          'Ancient History',
          'Medieval History',
          'Modern History',
          'World Wars',
          'Cold War',
        ],
        'Geography': [
          'Physical Geography',
          'Human Geography',
          'Cartography',
          'Climate Studies',
        ],
        'Literature': [
          'Poetry',
          'Prose',
          'Drama',
          'Literary Criticism',
          'Contemporary Literature',
        ],
        'Economics': [
          'Microeconomics',
          'Macroeconomics',
          'International Trade',
          'Finance',
          'Economic Theory',
        ],
        'Business Studies': [
          'Marketing',
          'Management',
          'Accounting',
          'Entrepreneurship',
          'Business Ethics',
        ],
        'Psychology': [
          'Clinical Psychology',
          'Cognitive Psychology',
          'Developmental Psychology',
          'Social Psychology',
        ],
        'Sociology': [
          'Social Theory',
          'Research Methods',
          'Social Institutions',
          'Cultural Studies',
        ],
        'Art': [
          'Art History',
          'Drawing Techniques',
          'Painting',
          'Sculpture',
          'Contemporary Art',
        ],
        'Music': [
          'Music Theory',
          'Music History',
          'Composition',
          'Instrument Studies',
        ],
        'Physical Education': [
          'Sports Science',
          'Fitness Training',
          'Nutrition',
          'Game Strategies',
        ],
        'Foreign Languages': [
          'Grammar',
          'Vocabulary',
          'Conversation Practice',
          'Cultural Studies',
        ],
      };

      // Define common task types for each subject
      final List<Map<String, String>> taskTypes = [
        {
          'title': 'Create Study Notes',
          'description': 'Create comprehensive study notes for TOPIC',
        },
        {
          'title': 'Practice Problems',
          'description': 'Complete the practice problems on TOPIC',
        },
        {
          'title': 'Research Assignment',
          'description': 'Research and write a summary of TOPIC',
        },
        {
          'title': 'Review Session',
          'description': 'Review and consolidate your knowledge of TOPIC',
        },
        {
          'title': 'Create Flashcards',
          'description':
              'Create flashcards for key terms and concepts in TOPIC',
        },
        {
          'title': 'Watch Tutorial',
          'description': 'Watch and take notes from a tutorial on TOPIC',
        },
        {
          'title': 'Prepare Presentation',
          'description':
              'Prepare a short presentation explaining the key concepts of TOPIC',
        },
      ];

      // Create templates for each subject
      final batch = _firestore.batch();
      int count = 0;

      subjectTopics.forEach((subject, topics) {
        topics.forEach((topic) {
          // Create 2-3 random tasks for each topic
          for (int i = 0; i < 2 + Random().nextInt(2); i++) {
            final taskType = taskTypes[Random().nextInt(taskTypes.length)];
            final docRef = suggestedTasksCollection.doc();

            // Generate random XP between 10 and 50
            final int xpPoints = Random().nextInt(41) + 10; // 10 to 50 range

            // Generate random difficulty level between 1 and 5
            final int difficultyLevel = Random().nextInt(5) + 1; // 1 to 5 range

            final suggestedTask = SuggestedTask(
              id: docRef.id,
              title: taskType['title']!,
              description: taskType['description']!.replaceAll('TOPIC', topic),
              subject: subject,
              xpPoints: xpPoints,
              difficultyLevel: difficultyLevel,
            );

            batch.set(docRef, suggestedTask.toMap());
            count++;

            // Firestore batches have a limit of 500 operations
            if (count >= 450) {
              batch.commit();
              count = 0;
            }
          }
        });
      });

      // Commit any remaining operations
      if (count > 0) {
        batch.commit();
      }
    } catch (e) {
      throw Exception('Failed to seed suggested task templates: $e');
    }
  }

  // Notify task assignment
  Future<void> notifyTaskAssigned(
    String taskId,
    String assignedToId,
    String assignerName,
  ) async {
    try {
      final taskDoc = await tasksCollection.doc(taskId).get();
      if (!taskDoc.exists) return;

      final task = Task.fromMap(taskDoc.data() as Map<String, dynamic>);

      // Create in-app notification
      await _firestore.collection('notifications').add({
        'userId': assignedToId,
        'title': 'New Task Assigned',
        'message': '$assignerName assigned you a task: ${task.title}',
        'time': DateTime.now().toIso8601String(),
        'isRead': false,
        'notificationType': 'task_assigned',
        'payload': {'taskId': taskId},
      });

      // Also create a push notification
      final notificationService = NotificationService();
      await notificationService.showStudyReminderNotification(
        id: taskId.hashCode,
        title: 'New Task Assigned',
        body: '$assignerName assigned you a task: ${task.title}',
        payload: '{"type":"task_assigned","taskId":"$taskId"}',
      );
    } catch (e) {
      debugPrint('Failed to notify task assignment: $e');
    }
  }

  // Add this method to check and notify tasks due soon
  Future<void> checkAndNotifyTasksDueSoon() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      // Get tasks due within the next 24 hours
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final tasksSnapshot =
          await tasksCollection
              .where('assignedTo', isEqualTo: userId)
              .where('status', isEqualTo: 'in_progress')
              .where('dueDate', isGreaterThan: now.toIso8601String())
              .where('dueDate', isLessThan: tomorrow.toIso8601String())
              .get();

      for (var doc in tasksSnapshot.docs) {
        final task = Task.fromMap(doc.data() as Map<String, dynamic>);

        // Create push notification
        final notificationService = NotificationService();
        await notificationService.showStudyReminderNotification(
          id: task.id.hashCode,
          title: 'Task Due Soon',
          body: '${task.title} is due in less than 24 hours',
          payload: '{"type":"task_due_soon","taskId":"${task.id}"}',
        );
      }
    } catch (e) {
      debugPrint('Failed to check for tasks due soon: $e');
    }
  }
}
