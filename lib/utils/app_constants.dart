class UserRoles {
  static const student = 'Student';
  static const teacher = 'Teacher';
  static const admin = 'Admin';

  static const all = [student, teacher, admin];
}

class ReportCategories {
  static const facility = 'Facility';
  static const itConcern = 'IT Concern';
  static const classroom = 'Classroom';
  static const comfortRoom = 'Comfort Room';
  static const lostAndFound = 'Lost and Found';
  static const clinic = 'Clinic';
  static const maintenance = 'Maintenance';
  static const other = 'Other';

  static const all = [
    facility,
    itConcern,
    classroom,
    comfortRoom,
    lostAndFound,
    clinic,
    maintenance,
    other,
  ];
}

class ReportPriorities {
  static const low = 'Low';
  static const medium = 'Medium';
  static const high = 'High';
  static const urgent = 'Urgent';

  static const all = [low, medium, high, urgent];
}

class ReportStatuses {
  static const pending = 'Pending';
  static const reviewed = 'Reviewed';
  static const inProgress = 'In Progress';
  static const resolved = 'Resolved';
  static const rejected = 'Rejected';

  static const all = [pending, reviewed, inProgress, resolved, rejected];
}

class CampusTeams {
  static const facilitiesTeam = 'Facilities Team';
  static const maintenanceTeam = 'Maintenance Team';
  static const itSupport = 'IT Support Team';
  static const networkTeam = 'Network Team';
  static const clinicStaff = 'Clinic Staff';
  static const studentAffairs = 'Student Affairs';
  static const securityOffice = 'Security Office';
  static const adminOffice = 'Admin Office';

  static const all = [
    facilitiesTeam,
    maintenanceTeam,
    itSupport,
    networkTeam,
    clinicStaff,
    studentAffairs,
    securityOffice,
    adminOffice,
  ];
}

class CampusFixRoutes {
  static const splash = '/';
  static const roles = '/roles';
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const reports = '/reports';
  static const addReport = '/add-report';
  static const accounts = '/accounts';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const reportDetails = '/report-details';
}

class DemoCredentials {
  static const studentEmail = 'student@campusfix.app';
  static const studentPassword = 'student123';
  static const teacherEmail = 'teacher@campusfix.app';
  static const teacherPassword = 'teacher123';
  static const adminEmail = 'admin@campusfix.app';
  static const adminPassword = 'admin123';

  static bool matches({
    required String role,
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();

    switch (role) {
      case UserRoles.student:
        return normalizedEmail == studentEmail && password == studentPassword;
      case UserRoles.teacher:
        return normalizedEmail == teacherEmail && password == teacherPassword;
      case UserRoles.admin:
        return normalizedEmail == adminEmail && password == adminPassword;
      default:
        return false;
    }
  }

  static String helperForRole(String role) {
    switch (role) {
      case UserRoles.teacher:
        return '$teacherEmail / $teacherPassword';
      case UserRoles.admin:
        return '$adminEmail / $adminPassword';
      case UserRoles.student:
      default:
        return '$studentEmail / $studentPassword';
    }
  }
}
