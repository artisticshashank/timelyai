import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely_ai/features/data_management/controller/timetable_controller.dart';
import 'package:timely_ai/features/data_management/screens/StudentGroupFormScreen.dart';
import 'package:timely_ai/shared/widgets/glass_card.dart';
import 'package:timely_ai/shared/widgets/saas_scaffold.dart';

class ManageStudentGroupsScreen extends ConsumerWidget {
  const ManageStudentGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final homeNotifier = ref.read(homeControllerProvider.notifier);

    return SaaSScaffold(
      title: 'Manage Student Groups',
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentGroupFormScreen(),
            ),
          );
          if (result != null) {
            homeNotifier.addStudentGroup(result);
          }
        },
        backgroundColor: Colors.tealAccent, // Neon Teal
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: homeState.studentGroups.isEmpty
          ? const Center(
              child: Text(
                'No student groups added yet.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: homeState.studentGroups.length,
              itemBuilder: (context, index) {
                final group = homeState.studentGroups[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.groups_outlined,
                        color: Colors.white70,
                      ),
                      title: Text(
                        group.id, // Changed from group.name to group.id
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        'Size: ${group.size} • Courses: ${group.enrolledCourses.length}',
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
                                  builder: (context) => StudentGroupFormScreen(
                                    initialStudentGroup:
                                        group, // Corrected parameter name
                                  ),
                                ),
                              );
                              if (result != null) {
                                homeNotifier.updateStudentGroup(result);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () =>
                                homeNotifier.deleteStudentGroup(index),
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
