import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/index.dart';
import '../../providers/index.dart';
import '../../services/room_allocation_service.dart';

/// Room management screen with CRUD operations
class RoomManagementScreen extends ConsumerStatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  ConsumerState<RoomManagementScreen> createState() =>
      _RoomManagementScreenState();
}

class _RoomManagementScreenState extends ConsumerState<RoomManagementScreen> {
  String _selectedBlock = 'All';
  final _roomService = RoomAllocationService();

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(allRoomsProvider);

    return Column(
      children: [
        // Header with filter and add button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Room Management',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              DropdownButton<String>(
                value: _selectedBlock,
                items: [
                  const DropdownMenuItem(
                    value: 'All',
                    child: Text('All Blocks'),
                  ),
                  const DropdownMenuItem(value: 'A', child: Text('Block A')),
                  const DropdownMenuItem(value: 'B', child: Text('Block B')),
                  const DropdownMenuItem(value: 'C', child: Text('Block C')),
                  const DropdownMenuItem(value: 'D', child: Text('Block D')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedBlock = value);
                  }
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showRoomDialog(null),
                icon: const Icon(Icons.add),
                label: const Text('Add Room'),
              ),
            ],
          ),
        ),
        // Room list
        Expanded(
          child: roomsAsync.when(
            data: (rooms) {
              final filteredRooms = _selectedBlock == 'All'
                  ? rooms
                  : rooms.where((r) => r.blockName == _selectedBlock).toList();

              if (filteredRooms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.room, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No rooms found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredRooms.length,
                itemBuilder: (context, index) {
                  final room = filteredRooms[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: room.isAvailable
                            ? Colors.green
                            : Colors.red,
                        child: Text(
                          room.currentOccupancy.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        '${room.blockName}-${room.roomNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${room.roomType} • Occupancy: ${room.currentOccupancy}/${room.capacity} • ${room.condition}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showRoomDialog(room),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteRoom(room),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Floor: ${room.floorNumber}'),
                              const SizedBox(height: 8),
                              Text('Amenities: ${room.amenities.join(', ')}'),
                              const SizedBox(height: 8),
                              if (room.occupantIds.isNotEmpty) ...[
                                const Text(
                                  'Occupants:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...room.occupantIds.map((id) => Text('• $id')),
                              ],
                              const SizedBox(height: 16),
                              if (room.isAvailable)
                                ElevatedButton.icon(
                                  onPressed: () => _showAllocateDialog(room),
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Allocate Student'),
                                )
                              else if (room.occupantIds.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: () => _showDeallocateDialog(room),
                                  icon: const Icon(Icons.person_remove),
                                  label: const Text('Deallocate Student'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Error: ${error.toString()}')),
          ),
        ),
      ],
    );
  }

  void _showRoomDialog(RoomModel? room) {
    final isEdit = room != null;
    final blockController = TextEditingController(text: room?.blockName);
    final floorController = TextEditingController(
      text: room?.floorNumber.toString() ?? '1',
    );
    final capacityController = TextEditingController(
      text: room?.capacity.toString() ?? '2',
    );
    String roomType = room?.roomType ?? 'Single';
    String condition = room?.condition ?? 'good';
    List<String> selectedAmenities = room?.amenities ?? [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Room' : 'Add New Room'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: blockController,
                  decoration: const InputDecoration(
                    labelText: 'Block Name',
                    hintText: 'A',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: floorController,
                  decoration: const InputDecoration(labelText: 'Floor'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: roomType,
                  decoration: const InputDecoration(labelText: 'Room Type'),
                  items: const [
                    DropdownMenuItem(value: 'Single', child: Text('Single')),
                    DropdownMenuItem(value: 'Double', child: Text('Double')),
                    DropdownMenuItem(value: 'Triple', child: Text('Triple')),
                    DropdownMenuItem(value: 'Quad', child: Text('Quad')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => roomType = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: capacityController,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: condition,
                  decoration: const InputDecoration(labelText: 'Condition'),
                  items: const [
                    DropdownMenuItem(value: 'good', child: Text('Good')),
                    DropdownMenuItem(value: 'fair', child: Text('Fair')),
                    DropdownMenuItem(
                      value: 'needs_repair',
                      child: Text('Needs Repair'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => condition = value);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Amenities:'),
                Wrap(
                  spacing: 8,
                  children:
                      [
                        'WiFi',
                        'AC',
                        'Attached Bathroom',
                        'Balcony',
                        'Study Table',
                      ].map((amenity) {
                        return FilterChip(
                          label: Text(amenity),
                          selected: selectedAmenities.contains(amenity),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedAmenities.add(amenity);
                              } else {
                                selectedAmenities.remove(amenity);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (isEdit) {
                    await _roomService.updateRoom(
                      roomId: room.roomId,
                      blockName: blockController.text,
                      floor: int.parse(floorController.text),
                      roomType: roomType,
                      capacity: int.parse(capacityController.text),
                      condition: condition,
                      amenities: selectedAmenities,
                    );
                  } else {
                    await _roomService.createRoom(
                      roomNumber:
                          '${blockController.text}${floorController.text}01',
                      blockName: blockController.text,
                      floor: int.parse(floorController.text),
                      roomType: roomType,
                      capacity: int.parse(capacityController.text),
                      condition: condition,
                      amenities: selectedAmenities,
                    );
                  }
                  Navigator.pop(context);
                  ref.invalidate(allRoomsProvider);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit
                              ? 'Room updated successfully'
                              : 'Room created successfully',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRoom(RoomModel room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text(
          'Are you sure you want to delete room ${room.blockName}-${room.roomNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _roomService.deleteRoom(room.roomId);
        ref.invalidate(allRoomsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  void _showAllocateDialog(RoomModel room) {
    final studentIdController = TextEditingController();
    final studentNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Allocate Room ${room.blockName}-${room.roomNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                hintText: 'Enter student ID',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: studentNameController,
              decoration: const InputDecoration(
                labelText: 'Student Name',
                hintText: 'Enter full name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _roomService.allocateRoom(
                  studentId: studentIdController.text.trim(),
                  fullName: studentNameController.text.trim(),
                );
                Navigator.pop(context);
                ref.invalidate(allRoomsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student allocated successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Allocate'),
          ),
        ],
      ),
    );
  }

  void _showDeallocateDialog(RoomModel room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deallocate Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select student to deallocate:'),
            const SizedBox(height: 16),
            ...List.generate(
              room.occupantIds.length,
              (index) => ListTile(
                title: Text(room.occupantIds[index]),
                subtitle: const Text('Student ID'),
                onTap: () async {
                  try {
                    await _roomService.deallocateRoom(
                      room.occupantIds[index],
                      room.roomId,
                    );
                    Navigator.pop(context);
                    ref.invalidate(allRoomsProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Student deallocated successfully'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
