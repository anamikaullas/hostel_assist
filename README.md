# HostelAssist - Smart AI-Powered Hostel Administration App

## 📱 Overview

HostelAssist is a comprehensive Flutter mobile application designed for intelligent hostel administration. It combines AI-powered features with intelligent algorithms for automatic room allocation, complaint classification, and chatbot support.

**Tech Stack:**
- **Frontend:** Flutter (Dart)
- **Backend:** Firebase (Authentication, Firestore, Cloud Storage, Cloud Messaging)
- **Architecture:** Clean architecture with providers (Riverpod)
- **Key Features:** AI-based room allocation, automated complaint classification, NLP chatbot

---

## 🎯 Core Features

### 1. Role-Based Authentication
- **Students:** Login/Register with enrollment details
- **Admins:** Login with admin credentials
- Automatic role-based dashboard routing
- Secure Firebase Authentication

### 2. Intelligent Room Allocation
**Algorithm Details:**
- Constraint-based automatic allocation
- Scoring system considering:
  - Room availability and occupancy
  - Room condition (good/fair/needs_repair)
  - Amenity preferences
  - Capacity constraints
- Firestore transactions ensure data consistency
- Prevents over-allocation with atomic operations

**See:** `lib/services/room_allocation_service.dart` (180+ lines with detailed comments)

### 3. AI Complaint Management
**Classification Logic:**
- Rule-based NLP for automatic categorization
- Keyword matching for complaint categories (plumbing, electrical, maintenance, cleanliness, etc.)
- intelligent priority assignment (high/medium/low)
- Admin can review and override classifications

**See:** `lib/services/complaint_service.dart`

### 4. NLP-Based AI Chatbot
**Intent Detection:**
- 9 different intents (complaint_status, fee_info, mess_menu, room_info, rules, etc.)
- Context-aware dynamic responses
- Fetches real data from Firestore
- Conversation logging for analytics

**Sample Intents:**
- `complaint_status` - Get complaint progress
- `fee_info` - View payment details
- `mess_menu` - See daily meals
- `room_info` - Get room details
- `rules_regulations` - Learn hostel rules

**See:** `lib/services/chatbot_service.dart`

### 5. Digital Mess Management
- Admin: Add/update daily/weekly menus
- Students: View meals and provide feedback
- Rating and feedback system
- Feedback analytics for admin

### 6. Fee Management with Notifications
- Automated fee creation
- Payment tracking
- Overdue alerts via FCM
- Fee statistics and reports
- Payment status updates

---

## 📁 Project Structure

```
hostel_assist_mobile/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── app.dart                           # Main app widget with routing
│   │
│   ├── models/                            # Firestore data models
│   │   ├── user_model.dart               
│   │   ├── room_model.dart               
│   │   ├── complaint_model.dart          
│   │   ├── mess_menu_model.dart         
│   │   ├── feedback_model.dart          
│   │   ├── fee_model.dart               
│   │   ├── chatbot_model.dart           
│   │   └── index.dart                    # Models barrel file
│   │
│   ├── services/                          # Business logic & Firestore operations
│   │   ├── firebase_service.dart         # Firebase initialization & core operations
│   │   ├── auth_service.dart             # User authentication
│   │   ├── room_allocation_service.dart  # Room allocation algorithm
│   │   ├── complaint_service.dart        # Complaint classification logic
│   │   ├── chatbot_service.dart          # NLP intent detection & responses
│   │   ├── mess_service.dart             # Mess menu management
│   │   ├── fee_service.dart              # Fee management
│   │   └── index.dart                    # Services barrel file
│   │
│   ├── providers/                         # Riverpod state management
│   │   ├── auth_provider.dart            # Auth state & login/register
│   │   ├── room_provider.dart            # Room allocation state
│   │   ├── complaint_provider.dart       # Complaint state
│   │   ├── fee_provider.dart             # Fee state
│   │   ├── mess_provider.dart            # Mess state
│   │   ├── chatbot_provider.dart         # Chatbot queries
│   │   └── index.dart                    # Providers barrel file
│   │
│   ├── screens/                           # UI Screens
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── student/
│   │   │   └── student_dashboard.dart    # Main student interface
│   │   └── admin/
│   │       └── admin_dashboard.dart      # Main admin interface
│   │
│   ├── widgets/                           # Reusable UI components
│   │   └── (custom widgets to be added)
│   │
│   ├── constants/                         # App constants & configuration
│   │   ├── constants.dart
│   │   └── index.dart
│   │
│   └── utils/                             # Utility functions
│       └── (helpers & extensions)
│
├── pubspec.yaml                           # Dependencies & project config
├── README.md                              # This file
└── SETUP.md                               # Detailed setup instructions
```

---

## 🗄️ Firebase Firestore Structure

```
users/
  {uid}
    - email
    - fullName
    - role (student/admin)
    - phoneNumber
    - enrollmentId (students only)
    - roomId
    - createdAt
    - updatedAt

rooms/
  {roomId}
    - blockName
    - floorNumber
    - capacity
    - currentOccupancy
    - occupantIds (array of student UIDs)
    - roomType (single/double/triple/quad)
    - condition (good/fair/needs_repair)
    - amenities (array)
    - monthlyRent

complaints/
  {complaintId}
    - studentId
    - studentName
    - category (user input)
    - determinedCategory (AI classification)
    - description
    - status (pending/in_progress/resolved)
    - priority (high/medium/low)
    - imageUrl
    - adminRemarks
    - createdAt

mess_menu/
  {menuId}
    - date
    - breakfast (array of meals)
    - lunch (array of meals)
    - dinner (array of meals)
    - remarks

fees/
  {feeId}
    - studentId
    - studentName
    - amount
    - feeType
    - dueDate
    - status (pending/overdue/paid)
    - paidDate
    - transactionId

chatbot_logs/
  {messageId}
    - studentId
    - message
    - response
    - detectedIntent
    - keywords
    - timestamp
```

---

## 🤖 AI Algorithms

### Room Allocation Algorithm

**Scoring Formula:**
```
Score = (Availability × 30) + (Condition × 15) + (RoomType × 20) 
       + (Amenity Match × 20) + (Remaining Capacity × 15)

Where:
- Availability = (1 - occupancy_ratio) × 30
- Condition: good=15, fair=10, needs_repair=5
- RoomType: single=20, double=15, triple=10, quad=5
- Amenity Match = (matching_amenities / preferred_amenities) × 20
- Remaining Capacity = (remaining_slots / total_capacity) × 15
```

**Transaction Safety:**
- Atomic updates using Firestore transactions
- Prevents race conditions
- Consistent occupancy counts

### Complaint Classification (NLP)

**Keywords Approach:**
```dart
categoryKeywords = {
  'plumbing': ['water', 'leak', 'tap', 'toilet', 'flush', ...],
  'electrical': ['light', 'switch', 'power', 'socket', ...],
  'maintenance': ['paint', 'wall', 'door', 'window', ...],
  ...
}

Algorithm:
1. Convert description to lowercase
2. Extract words (split by non-alphanumeric)
3. Count keyword matches per category
4. Return category with highest match count
```

### Priority Assignment

**Keywords-based:**
```
High Priority: 'urgent', 'emergency', 'critical', 'danger', 'hazard', ...
Medium Priority: 'important', 'problem', 'issue', 'soon', ...
Low Priority: 'minor', 'slight', 'when possible', ...
```

### Chatbot Intent Detection

**Intent Keywords:**
```dart
{
  'complaint_status': ['status', 'complaint', 'issue', 'progress', ...],
  'fee_info': ['fee', 'cost', 'payment', 'due', ...],
  'mess_menu': ['menu', 'food', 'lunch', 'breakfast', ...],
  'room_info': ['room', 'accommodation', 'block', 'floor', ...],
  'rules_regulations': ['rule', 'regulation', 'curfew', 'visit', ...],
  ...
}
```

**Response Generation:**
- Dynamic: Fetches real data from Firestore
- Context-aware: Uses user profile and specific queries
- Conversational: Natural language responses
- Analytics: Logs all conversations for improvement

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0+)
- Dart SDK
- Firebase project created
- Android Studio or Xcode

### Installation Steps

1. **Clone the project**
```bash
git clone <repo-url>
cd hostel_assist_mobile
```

2. **Get dependencies**
```bash
flutter pub get
```

3. **Configure Firebase**
   - Download `google-services.json` (Android)
   - Download `GoogleService-Info.plist` (iOS)
   - Place in respective platform directories

4. **Run the app**
```bash
flutter run
```

For detailed setup, see [SETUP.md](SETUP.md)

---

## 🔐 Security Considerations

- Firebase Authentication for secure login
- Firestore security rules (to be configured)
- Role-based access control
- Data encryption in transit
- Sensitive data stored server-side

---

## 📊 Performance Optimizations

- Firestore query optimization
- Local caching with Hive
- Image optimization with caching
- Riverpod for efficient state management
- Lazy loading for lists

---

## 🧪 Testing

Example test cases to implement:
```dart
// Room allocation algorithm test
test('Should allocate room based on preferences', () async {
  final service = RoomAllocationService();
  final roomId = await service.allocateRoom(
    studentId: 'test123',
    fullName: 'Test Student',
    preferredYear: 2,
  );
  expect(roomId, isNotNull);
});

// Complaint classification test
test('Should classify plumbing complaint', () {
  final service = ComplaintClassificationService();
  final category = service._classifyCategory(
    'Water is leaking from the tap'
  );
  expect(category, equals('plumbing'));
});
```

---

## 📱 Future Enhancements

1. Video call support for admin assistance
2. Advanced analytics dashboard
3. ML-based demand forecasting
4. Push notification system improvements
5. Offline mode with sync
6. QR code room access
7. Integration with payment gateways
8. Advanced chatbot with ML/NLP

---

## 🤝 Contributing

Guidelines for contributing to the project:
1. Create a feature branch
2. Make your changes with comments
3. Test thoroughly
4. Submit a pull request

---

## 📝 License

This project is proprietary and confidential.

---

## 📞 Support

For issues, feature requests, or questions:
- Email: support@hostelassist.dev
- Issue Tracker: GitHub Issues

---

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Dart Language Guide](https://dart.dev)

