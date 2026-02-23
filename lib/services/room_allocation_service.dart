import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

import '../constants/index.dart';
import '../models/index.dart';
import '../utils/index.dart';
import 'firebase_service.dart';

/// Room allocation service with intelligent scoring algorithm
/// Automatically assigns rooms based on multiple criteria
/// Uses Firestore transactions for atomic operations
class RoomAllocationService {
  final FirebaseService _firebaseService;
  final Logger _logger = Logger();

  RoomAllocationService({FirebaseService? firebaseService})
    : _firebaseService = firebaseService ?? FirebaseService();

  FirebaseFirestore get _firestore => _firebaseService.firestore;

  /// Allocate room to a student using intelligent scoring
  ///
  /// Scoring Algorithm:
  /// - Availability Score (30 points): Based on occupancy ratio
  /// - Condition Score (15 points): Room condition (good/fair/needs_repair)
  /// - Room Type Score (20 points): Preference for less crowded rooms
  /// - Amenity Match Score (20 points): Matching preferred amenities
  /// - Capacity Score (15 points): Remaining capacity
  ///
  /// Total Score: 0-100 (higher is better)
  Future<String> allocateRoom({
    required String studentId,
    required String fullName,
    List<String> preferredAmenities = const [],
    int? preferredFloor,
    String? preferredBlock,
  }) async {
    try {
      _logger.i('Starting room allocation for student: $studentId');

      // Fetch all available rooms
      final availableRooms = await _getAvailableRooms();

      if (availableRooms.isEmpty) {
        throw RoomAllocationException('No rooms available for allocation');
      }

      // Calculate scores for each room
      final scoredRooms = availableRooms.map((room) {
        final score = _calculateRoomScore(
          room,
          preferredAmenities: preferredAmenities,
          preferredFloor: preferredFloor,
          preferredBlock: preferredBlock,
        );
        return {'room': room, 'score': score};
      }).toList();

      // Sort by score (highest first)
      scoredRooms.sort(
        (a, b) => (b['score'] as double).compareTo(a['score'] as double),
      );

      _logger.i(
        'Scored ${scoredRooms.length} rooms. Top score: ${scoredRooms.first['score']}',
      );

      // Try to allocate the best room using transaction
      for (final scoredRoom in scoredRooms) {
        final room = scoredRoom['room'] as RoomModel;
        try {
          await _allocateRoomTransaction(room.roomId, studentId, fullName);
          _logger.i(
            'Successfully allocated room ${room.roomId} to student $studentId (score: ${scoredRoom['score']})',
          );
          return room.roomId;
        } catch (e) {
          // Room might have been taken by another transaction, try next best room
          _logger.w(
            'Failed to allocate room ${room.roomId}, trying next option',
          );
          continue;
        }
      }

      throw RoomAllocationException(
        'Failed to allocate any room due to concurrent allocation conflicts',
      );
    } catch (e) {
      _logger.e('Error during room allocation', error: e);
      if (e is HostelAssistException) rethrow;
      throw RoomAllocationException(
        'Room allocation failed: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get all available rooms
  Future<List<RoomModel>> _getAvailableRooms() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionRooms)
          .where(
            'currentOccupancy',
            isLessThan: FieldPath.fromString('capacity'),
          )
          .get();

      return querySnapshot.docs
          .map((doc) => RoomModel.fromJson(doc.data()))
          .where((room) => room.isAvailable)
          .toList();
    } catch (e) {
      _logger.e('Error fetching available rooms', error: e);
      throw FirestoreException(
        'Failed to fetch available rooms: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Calculate room score based on multiple criteria
  ///
  /// Scoring breakdown:
  /// 1. Availability (30 pts): Rooms with lower occupancy get higher scores
  /// 2. Condition (15 pts): good=15, fair=10, needs_repair=5
  /// 3. Room Type (20 pts): single=20, double=15, triple=10, quad=5
  /// 4. Amenity Match (20 pts): Percentage of preferred amenities present
  /// 5. Remaining Capacity (15 pts): More remaining slots = higher score
  double _calculateRoomScore(
    RoomModel room, {
    List<String> preferredAmenities = const [],
    int? preferredFloor,
    String? preferredBlock,
  }) {
    double score = 0.0;

    // 1. Availability Score (30 points) - Lower occupancy is better
    final availabilityScore =
        (1 - room.occupancyRatio) * AppConstants.weightAvailability;
    score += availabilityScore;

    // 2. Condition Score (15 points)
    double conditionScore = 0.0;
    switch (room.condition) {
      case AppConstants.conditionGood:
        conditionScore = AppConstants.weightCondition;
        break;
      case AppConstants.conditionFair:
        conditionScore = AppConstants.weightCondition * 0.67;
        break;
      case AppConstants.conditionNeedsRepair:
        conditionScore = AppConstants.weightCondition * 0.33;
        break;
    }
    score += conditionScore;

    // 3. Room Type Score (20 points) - Prefer less crowded room types
    double roomTypeScore = 0.0;
    switch (room.roomType) {
      case AppConstants.roomTypeSingle:
        roomTypeScore = AppConstants.weightRoomType;
        break;
      case AppConstants.roomTypeDouble:
        roomTypeScore = AppConstants.weightRoomType * 0.75;
        break;
      case AppConstants.roomTypeTriple:
        roomTypeScore = AppConstants.weightRoomType * 0.50;
        break;
      case AppConstants.roomTypeQuad:
        roomTypeScore = AppConstants.weightRoomType * 0.25;
        break;
    }
    score += roomTypeScore;

    // 4. Amenity Match Score (20 points)
    double amenityScore = 0.0;
    if (preferredAmenities.isNotEmpty) {
      final matchingAmenities = room.amenities
          .where((amenity) => preferredAmenities.contains(amenity))
          .length;
      amenityScore =
          (matchingAmenities / preferredAmenities.length) *
          AppConstants.weightAmenities;
    } else {
      // If no preference, give average score
      amenityScore = AppConstants.weightAmenities * 0.5;
    }
    score += amenityScore;

    // 5. Remaining Capacity Score (15 points)
    final capacityScore =
        (room.remainingCapacity / room.capacity) * AppConstants.weightCapacity;
    score += capacityScore;

    // Bonus: Preferred floor (5 points)
    if (preferredFloor != null && room.floorNumber == preferredFloor) {
      score += 5.0;
    }

    // Bonus: Preferred block (5 points)
    if (preferredBlock != null && room.blockName == preferredBlock) {
      score += 5.0;
    }

    return score;
  }

  /// Allocate room using Firestore transaction (ensures atomic operation)
  /// Prevents race conditions and over-allocation
  Future<void> _allocateRoomTransaction(
    String roomId,
    String studentId,
    String fullName,
  ) async {
    final roomRef = _firestore
        .collection(AppConstants.collectionRooms)
        .doc(roomId);
    final userRef = _firestore
        .collection(AppConstants.collectionUsers)
        .doc(studentId);

    await _firestore.runTransaction((transaction) async {
      // Read current room state
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) {
        throw NotFoundException('Room not found: $roomId');
      }

      final room = RoomModel.fromJson(roomSnapshot.data()!);

      // Verify room is still available
      if (room.currentOccupancy >= room.capacity) {
        throw RoomAllocationException('Room is full: $roomId');
      }

      // Update room occupancy
      final updatedOccupantIds = [...room.occupantIds, studentId];
      transaction.update(roomRef, {
        'currentOccupancy': room.currentOccupancy + 1,
        'occupantIds': updatedOccupantIds,
        'updatedAt': Timestamp.now(),
      });

      // Update student's room assignment
      transaction.update(userRef, {
        'roomId': roomId,
        'updatedAt': Timestamp.now(),
      });

      _logger.i('Transaction: Allocated room $roomId to student $studentId');
    });
  }

  /// Deallocate room from a student
  Future<void> deallocateRoom(String studentId, String roomId) async {
    try {
      _logger.i('Deallocating room $roomId from student $studentId');

      final roomRef = _firestore
          .collection(AppConstants.collectionRooms)
          .doc(roomId);
      final userRef = _firestore
          .collection(AppConstants.collectionUsers)
          .doc(studentId);

      await _firestore.runTransaction((transaction) async {
        final roomSnapshot = await transaction.get(roomRef);
        if (!roomSnapshot.exists) {
          throw NotFoundException('Room not found: $roomId');
        }

        final room = RoomModel.fromJson(roomSnapshot.data()!);

        // Remove student from occupants
        final updatedOccupantIds = room.occupantIds
            .where((id) => id != studentId)
            .toList();

        transaction.update(roomRef, {
          'currentOccupancy': room.currentOccupancy - 1,
          'occupantIds': updatedOccupantIds,
          'updatedAt': Timestamp.now(),
        });

        transaction.update(userRef, {
          'roomId': FieldValue.delete(),
          'updatedAt': Timestamp.now(),
        });
      });

      _logger.i('Room deallocated successfully');
    } catch (e) {
      _logger.e('Error deallocating room', error: e);
      if (e is HostelAssistException) rethrow;
      throw RoomAllocationException(
        'Failed to deallocate room: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get all rooms
  Future<List<RoomModel>> getAllRooms() async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.collectionRooms)
          .get();

      return querySnapshot.docs
          .map((doc) => RoomModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      _logger.e('Error fetching all rooms', error: e);
      throw FirestoreException(
        'Failed to fetch rooms: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get room by ID
  Future<RoomModel> getRoomById(String roomId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionRooms)
          .doc(roomId)
          .get();

      if (!doc.exists) {
        throw NotFoundException('Room not found: $roomId');
      }

      return RoomModel.fromJson(doc.data()!);
    } catch (e) {
      _logger.e('Error fetching room', error: e);
      if (e is HostelAssistException) rethrow;
      throw FirestoreException(
        'Failed to fetch room: ${e.toString()}',
        details: e,
      );
    }
  }

  /// Get rooms by student ID
  Future<RoomModel?> getRoomByStudentId(String studentId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(studentId)
          .get();

      if (!userDoc.exists) {
        throw NotFoundException('User not found: $studentId');
      }

      final user = UserModel.fromJson(userDoc.data()!);
      if (user.roomId == null) return null;

      return await getRoomById(user.roomId!);
    } catch (e) {
      _logger.e('Error fetching room by student ID', error: e);
      if (e is HostelAssistException) rethrow;
      throw FirestoreException(
        'Failed to fetch room for student: ${e.toString()}',
        details: e,
      );
    }
  }
}
