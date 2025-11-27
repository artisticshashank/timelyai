import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely_ai/features/data_management/controller/timetable_controller.dart';
import 'package:timely_ai/features/data_management/screens/RoomFormScreen.dart';
import 'package:timely_ai/shared/widgets/glass_card.dart';
import 'package:timely_ai/shared/widgets/saas_scaffold.dart';

class ManageRoomsScreen extends ConsumerWidget {
  const ManageRoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final homeNotifier = ref.read(homeControllerProvider.notifier);

    return SaaSScaffold(
      title: 'Manage Rooms',
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RoomFormScreen()),
          );
          if (result != null) {
            homeNotifier.addRoom(result);
          }
        },
        backgroundColor: const Color(0xFFFF4E50), // Neon Red/Orange
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: homeState.rooms.isEmpty
          ? const Center(
              child: Text(
                'No rooms added yet.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: homeState.rooms.length,
              itemBuilder: (context, index) {
                final room = homeState.rooms[index];
                final isLab = room.type.toLowerCase().contains('lab');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isLab ? Icons.computer : Icons.meeting_room_outlined,
                        color: Colors.white70,
                      ),
                      title: Text(
                        room.id, // Changed from room.name to room.id
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        'Capacity: ${room.capacity} • ${room.type}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white70),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RoomFormScreen(initialRoom: room),
                                ),
                              );
                              if (result != null) {
                                homeNotifier.updateRoom(result);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => homeNotifier.deleteRoom(index),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
