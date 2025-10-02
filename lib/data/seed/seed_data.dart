import 'package:hive_flutter/hive_flutter.dart';
import '../repositories/lab_repository.dart';
import '../repositories/event_repository.dart';
import '../repositories/user_repository.dart';
import '../repositories/booking_repository.dart';
import '../../domain/enums/role.dart';

class SeedData {
  static const String _seededKey = 'seeded';

  static Future<void> seedIfNeeded({
    required LabRepository labRepository,
    required EventRepository eventRepository,
    required UserRepository userRepository,
    required BookingRepository bookingRepository,
  }) async {
    // Check if already seeded
    final userBox = await Hive.openBox('users');
    if (userBox.get(_seededKey) == true) {
      return;
    }

    // Seed labs
    await _seedLabs(labRepository);
    
    // Seed events
    await _seedEvents(eventRepository);
    
    // Seed admin user
    await _seedAdminUser(userRepository);
    
    // Mark as seeded
    await userBox.put(_seededKey, true);
  }

  static Future<void> _seedLabs(LabRepository labRepository) async {
    final labs = [
      {
        'name': 'Lab A - AI & Machine Learning',
        'location': 'Building A, Floor 3, Room 301',
        'capacity': 30,
        'description': 'Advanced AI and Machine Learning laboratory with high-performance computing resources.',
      },
      {
        'name': 'Lab B - Robotics & IoT',
        'location': 'Building B, Floor 2, Room 205',
        'capacity': 25,
        'description': 'Robotics and Internet of Things laboratory equipped with sensors and robotic kits.',
      },
      {
        'name': 'Lab C - Software Development',
        'location': 'Building C, Floor 1, Room 101',
        'capacity': 40,
        'description': 'Software development laboratory with modern development tools and collaborative spaces.',
      },
    ];

    for (final labData in labs) {
      await labRepository.createLab(
        name: labData['name'] as String,
        location: labData['location'] as String,
        capacity: labData['capacity'] as int,
        description: labData['description'] as String,
      );
    }
  }

  static Future<void> _seedEvents(EventRepository eventRepository) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Get labs for events - we'll use hardcoded lab IDs for now
    final labIds = ['lab_1', 'lab_2', 'lab_3'];
    
    final events = [
      {
        'labId': labIds[0],
        'title': 'AI Workshop: Introduction to Neural Networks',
        'description': 'Learn the fundamentals of neural networks and deep learning.',
        'start': today.add(const Duration(hours: 9)),
        'end': today.add(const Duration(hours: 12)),
        'createdBy': 'admin',
      },
      {
        'labId': labIds[1],
        'title': 'Robotics Demo: Arduino Programming',
        'description': 'Hands-on session on Arduino programming for robotics projects.',
        'start': today.add(const Duration(hours: 14)),
        'end': today.add(const Duration(hours: 17)),
        'createdBy': 'admin',
      },
      {
        'labId': labIds[2],
        'title': 'Flutter Development Workshop',
        'description': 'Build mobile applications with Flutter framework.',
        'start': today.add(const Duration(days: 1, hours: 10)),
        'end': today.add(const Duration(days: 1, hours: 13)),
        'createdBy': 'admin',
      },
      {
        'labId': labIds[0],
        'title': 'Machine Learning Project Presentation',
        'description': 'Students present their ML projects and research findings.',
        'start': today.add(const Duration(days: 2, hours: 15)),
        'end': today.add(const Duration(days: 2, hours: 18)),
        'createdBy': 'admin',
      },
      {
        'labId': labIds[1],
        'title': 'IoT Sensors Workshop',
        'description': 'Learn about various IoT sensors and their applications.',
        'start': today.add(const Duration(days: 3, hours: 9)),
        'end': today.add(const Duration(days: 3, hours: 12)),
        'createdBy': 'admin',
      },
    ];

    for (final eventData in events) {
      await eventRepository.createEvent(
        labId: eventData['labId'] as String,
        title: eventData['title'] as String,
        description: eventData['description'] as String,
        start: eventData['start'] as DateTime,
        end: eventData['end'] as DateTime,
        createdBy: eventData['createdBy'] as String,
      );
    }
  }

  static Future<void> _seedAdminUser(UserRepository userRepository) async {
    await userRepository.createUser(
      name: 'Admin User',
      studentId: 'ADMIN001',
      role: Role.admin.name,
    );
  }
}
