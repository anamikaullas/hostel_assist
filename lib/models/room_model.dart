import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a hostel room with occupancy and amenity information
/// Used by the room allocation algorithm
class RoomModel {
  final String roomId;
  final String blockName;
  final int floorNumber;
  final int capacity; // Maximum occupants
  final int currentOccupancy; // Current number of students
  final List<String> occupantIds; // UIDs of students in this room
  final String roomType; // 'single', 'double', 'triple', 'quad'
  final String condition; // 'good', 'fair', 'needs_repair'
  final List<String> amenities; // e.g., ['wifi', 'ac', 'attached_bathroom']
  final double monthlyRent;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoomModel({
    required this.roomId,
    required this.blockName,
    required this.floorNumber,
    required this.capacity,
    required this.currentOccupancy,
    required this.occupantIds,
    required this.roomType,
    required this.condition,
    required this.amenities,
    required this.monthlyRent,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create RoomModel from Firestore document
  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      roomId: json['roomId'] as String,
      blockName: json['blockName'] as String,
      floorNumber: json['floorNumber'] as int,
      capacity: json['capacity'] as int,
      currentOccupancy: json['currentOccupancy'] as int,
      occupantIds: List<String>.from(json['occupantIds'] as List),
      roomType: json['roomType'] as String,
      condition: json['condition'] as String,
      amenities: List<String>.from(json['amenities'] as List),
      monthlyRent: (json['monthlyRent'] as num).toDouble(),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert RoomModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'blockName': blockName,
      'floorNumber': floorNumber,
      'capacity': capacity,
      'currentOccupancy': currentOccupancy,
      'occupantIds': occupantIds,
      'roomType': roomType,
      'condition': condition,
      'amenities': amenities,
      'monthlyRent': monthlyRent,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with modified fields
  RoomModel copyWith({
    String? roomId,
    String? blockName,
    int? floorNumber,
    int? capacity,
    int? currentOccupancy,
    List<String>? occupantIds,
    String? roomType,
    String? condition,
    List<String>? amenities,
    double? monthlyRent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      blockName: blockName ?? this.blockName,
      floorNumber: floorNumber ?? this.floorNumber,
      capacity: capacity ?? this.capacity,
      currentOccupancy: currentOccupancy ?? this.currentOccupancy,
      occupantIds: occupantIds ?? this.occupantIds,
      roomType: roomType ?? this.roomType,
      condition: condition ?? this.condition,
      amenities: amenities ?? this.amenities,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if room is available for allocation
  bool get isAvailable => currentOccupancy < capacity;

  /// Get remaining capacity
  int get remainingCapacity => capacity - currentOccupancy;

  /// Get occupancy ratio (0.0 to 1.0)
  double get occupancyRatio => currentOccupancy / capacity;

  /// Get room number string (e.g., "A-101")
  String get roomNumber =>
      '$blockName-${floorNumber}${roomId.substring(roomId.length - 2)}';

  @override
  String toString() {
    return 'RoomModel(roomId: $roomId, block: $blockName, floor: $floorNumber, occupancy: $currentOccupancy/$capacity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomModel && other.roomId == roomId;
  }

  @override
  int get hashCode => roomId.hashCode;
}
