/// Application-wide constants
/// Centralized configuration for the HostelAssist app

class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // App Info
  static const String appName = 'HostelAssist';
  static const String appVersion = '1.0.0';

  // User Roles
  static const String roleStudent = 'student';
  static const String roleAdmin = 'admin';

  // Complaint Status
  static const String complaintPending = 'pending';
  static const String complaintInProgress = 'in_progress';
  static const String complaintResolved = 'resolved';

  // Complaint Priority
  static const String priorityHigh = 'high';
  static const String priorityMedium = 'medium';
  static const String priorityLow = 'low';

  // Complaint Categories
  static const String categoryPlumbing = 'plumbing';
  static const String categoryElectrical = 'electrical';
  static const String categoryMaintenance = 'maintenance';
  static const String categoryCleanliness = 'cleanliness';
  static const String categoryNoise = 'noise';
  static const String categoryHeating = 'heating';
  static const String categoryOther = 'other';

  // Room Types
  static const String roomTypeSingle = 'single';
  static const String roomTypeDouble = 'double';
  static const String roomTypeTriple = 'triple';
  static const String roomTypeQuad = 'quad';

  // Room Conditions
  static const String conditionGood = 'good';
  static const String conditionFair = 'fair';
  static const String conditionNeedsRepair = 'needs_repair';

  // Fee Types
  static const String feeTypeRoomRent = 'room_rent';
  static const String feeTypeMessFee = 'mess_fee';
  static const String feeTypeMaintenance = 'maintenance';
  static const String feeTypeOther = 'other';

  // Fee Status
  static const String feePending = 'pending';
  static const String feeOverdue = 'overdue';
  static const String feePaid = 'paid';

  // Meal Types
  static const String mealBreakfast = 'breakfast';
  static const String mealLunch = 'lunch';
  static const String mealDinner = 'dinner';

  // Chatbot Intents
  static const String intentComplaintStatus = 'complaint_status';
  static const String intentFeeInfo = 'fee_info';
  static const String intentMessMenu = 'mess_menu';
  static const String intentRoomInfo = 'room_info';
  static const String intentRulesRegulations = 'rules_regulations';
  static const String intentMaintenance = 'maintenance';
  static const String intentGreeting = 'greeting';
  static const String intentHelp = 'help';
  static const String intentOther = 'other';

  // Firestore Collections
  static const String collectionUsers = 'users';
  static const String collectionRooms = 'rooms';
  static const String collectionComplaints = 'complaints';
  static const String collectionMessMenu = 'mess_menu';
  static const String collectionFeedback = 'feedback';
  static const String collectionFees = 'fees';
  static const String collectionChatbotLogs = 'chatbot_logs';

  // Storage Paths
  static const String storageComplaintImages = 'complaint_images';
  static const String storageProfilePictures = 'profile_pictures';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxComplaintDescriptionLength = 500;
  static const int maxFeedbackCommentLength = 300;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Room Allocation Scoring Weights
  static const double weightAvailability = 30.0;
  static const double weightCondition = 15.0;
  static const double weightRoomType = 20.0;
  static const double weightAmenities = 20.0;
  static const double weightCapacity = 15.0;

  // Demo Credentials (for testing)
  static const String demoStudentEmail = 'student@hostel.com';
  static const String demoAdminEmail = 'admin@hostel.com';
  static const String demoPassword = 'demo123';
}
