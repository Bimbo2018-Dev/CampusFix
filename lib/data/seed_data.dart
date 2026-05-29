import '../models/app_user.dart';
import '../models/report_model.dart';
import '../models/report_note_model.dart';
import '../utils/app_constants.dart';

class SeedData {
  static final users = <AppUser>[
    const AppUser(
      id: 'user-student-1',
      name: 'Juan Dela Cruz',
      email: DemoCredentials.studentEmail,
      role: UserRoles.student,
      department: 'BS Information Technology',
      avatarText: 'JD',
    ),
    const AppUser(
      id: 'user-teacher-1',
      name: 'Maria Santos',
      email: DemoCredentials.teacherEmail,
      role: UserRoles.teacher,
      department: 'Computer Studies Department',
      avatarText: 'MS',
    ),
    const AppUser(
      id: 'user-admin-1',
      name: 'Admin User',
      email: DemoCredentials.adminEmail,
      role: UserRoles.admin,
      department: 'Campus Administration',
      avatarText: 'AU',
    ),
  ];

  static List<ReportModel> reports() {
    final now = DateTime.now();

    return [
      ReportModel(
        id: 'CF-1042',
        reporterId: 'user-student-1',
        reporterName: 'Juan Dela Cruz',
        reporterRole: UserRoles.student,
        title: 'Broken classroom chair',
        description:
            'One chair in Room 204 has a cracked support and may collapse when used by students.',
        category: ReportCategories.classroom,
        location: 'Room 204, Second Floor',
        priority: ReportPriorities.medium,
        status: ReportStatuses.pending,
        createdAt: now.subtract(const Duration(hours: 4)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        isValidatedByTeacher: false,
        notes: const [],
      ),
      ReportModel(
        id: 'CF-1041',
        reporterId: 'user-teacher-1',
        reporterName: 'Maria Santos',
        reporterRole: UserRoles.teacher,
        title: 'Projector not working',
        description:
            'The HDMI input in Computer Lab 2 does not detect laptops during lectures.',
        category: ReportCategories.itConcern,
        location: 'Computer Lab 2',
        priority: ReportPriorities.high,
        status: ReportStatuses.inProgress,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 8)),
        isValidatedByTeacher: true,
        assignedTo: 'IT Support',
        notes: [
          ReportNoteModel(
            id: 'note-1041-1',
            authorName: 'Admin User',
            authorRole: UserRoles.admin,
            message: 'Assigned to IT Support for cable and port inspection.',
            createdAt: now.subtract(const Duration(hours: 8)),
          ),
        ],
      ),
      ReportModel(
        id: 'CF-1040',
        reporterId: 'user-student-1',
        reporterName: 'Juan Dela Cruz',
        reporterRole: UserRoles.student,
        title: 'Comfort room faucet leaking',
        description:
            'The left sink faucet keeps leaking and water is pooling near the entrance.',
        category: ReportCategories.comfortRoom,
        location: 'Main Building CR, Ground Floor',
        priority: ReportPriorities.high,
        status: ReportStatuses.reviewed,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1, hours: 6)),
        isValidatedByTeacher: true,
        notes: [
          ReportNoteModel(
            id: 'note-1040-1',
            authorName: 'Maria Santos',
            authorRole: UserRoles.teacher,
            message: 'Verified after class dismissal. Needs maintenance.',
            createdAt: now.subtract(const Duration(days: 1, hours: 6)),
          ),
        ],
      ),
      ReportModel(
        id: 'CF-1039',
        reporterId: 'user-student-1',
        reporterName: 'Juan Dela Cruz',
        reporterRole: UserRoles.student,
        title: 'Lost ID card',
        description:
            'Student ID was found near the library entrance and turned over to the guard desk.',
        category: ReportCategories.lostAndFound,
        location: 'Library Entrance',
        priority: ReportPriorities.low,
        status: ReportStatuses.resolved,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2, hours: 4)),
        isValidatedByTeacher: true,
        assignedTo: 'Student Affairs',
        notes: [
          ReportNoteModel(
            id: 'note-1039-1',
            authorName: 'Admin User',
            authorRole: UserRoles.admin,
            message: 'Owner contacted and ID released.',
            createdAt: now.subtract(const Duration(days: 2, hours: 4)),
          ),
        ],
      ),
      ReportModel(
        id: 'CF-1038',
        reporterId: 'user-teacher-1',
        reporterName: 'Maria Santos',
        reporterRole: UserRoles.teacher,
        title: 'Clinic medicine request',
        description:
            'Clinic inventory needs basic fever medicine and antiseptic restock for student use.',
        category: ReportCategories.clinic,
        location: 'School Clinic',
        priority: ReportPriorities.medium,
        status: ReportStatuses.pending,
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
        isValidatedByTeacher: true,
        notes: const [],
      ),
      ReportModel(
        id: 'CF-1037',
        reporterId: 'user-student-1',
        reporterName: 'Juan Dela Cruz',
        reporterRole: UserRoles.student,
        title: 'WiFi connection issue',
        description:
            'Students cannot connect to campus WiFi in the library study area during peak hours.',
        category: ReportCategories.itConcern,
        location: 'Main Library, East Wing',
        priority: ReportPriorities.urgent,
        status: ReportStatuses.inProgress,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
        isValidatedByTeacher: true,
        assignedTo: 'Network Team',
        notes: [
          ReportNoteModel(
            id: 'note-1037-1',
            authorName: 'Maria Santos',
            authorRole: UserRoles.teacher,
            message: 'Confirmed with multiple students using different phones.',
            createdAt: now.subtract(const Duration(days: 4, hours: 20)),
          ),
        ],
      ),
      ReportModel(
        id: 'CF-1036',
        reporterId: 'user-teacher-1',
        reporterName: 'Maria Santos',
        reporterRole: UserRoles.teacher,
        title: 'Ceiling fan not working',
        description:
            'The ceiling fan in Room 305 stopped running and the room gets too warm by afternoon.',
        category: ReportCategories.maintenance,
        location: 'Room 305',
        priority: ReportPriorities.medium,
        status: ReportStatuses.rejected,
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 5, hours: 4)),
        isValidatedByTeacher: true,
        notes: [
          ReportNoteModel(
            id: 'note-1036-1',
            authorName: 'Admin User',
            authorRole: UserRoles.admin,
            message:
                'Duplicate of CF-1034. Maintenance request is already active.',
            createdAt: now.subtract(const Duration(days: 5, hours: 4)),
          ),
        ],
      ),
      ReportModel(
        id: 'CF-1035',
        reporterId: 'user-student-1',
        reporterName: 'Juan Dela Cruz',
        reporterRole: UserRoles.student,
        title: 'Trash bin overflow',
        description:
            'Trash bins near the canteen overflow after lunch and need additional collection.',
        category: ReportCategories.facility,
        location: 'Canteen Exit',
        priority: ReportPriorities.high,
        status: ReportStatuses.resolved,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 6, hours: 2)),
        isValidatedByTeacher: false,
        assignedTo: 'Facilities Team',
        notes: [
          ReportNoteModel(
            id: 'note-1035-1',
            authorName: 'Admin User',
            authorRole: UserRoles.admin,
            message: 'Added one extra bin and adjusted collection schedule.',
            createdAt: now.subtract(const Duration(days: 6, hours: 2)),
          ),
        ],
      ),
    ];
  }
}
