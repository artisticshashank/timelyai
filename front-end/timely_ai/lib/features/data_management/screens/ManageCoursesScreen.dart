import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely_ai/features/data_management/controller/timetable_controller.dart';
import 'package:timely_ai/features/data_management/screens/CourseFormScreen.dart';
import 'package:timely_ai/shared/widgets/glass_card.dart';
import 'package:timely_ai/shared/widgets/saas_scaffold.dart';

class ManageCoursesScreen extends ConsumerWidget {
  const ManageCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final homeNotifier = ref.read(homeControllerProvider.notifier);

    return SaaSScaffold(
      title: 'Manage Courses',
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CourseFormScreen()),
          );
          if (result != null) {
            homeNotifier.addCourse(result);
          }
        },
        backgroundColor: const Color(0xFF7F00FF), // Neon Violet
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: homeState.courses.isEmpty
          ? const Center(
              child: Text(
                'No courses added yet.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: homeState.courses.length,
              itemBuilder: (context, index) {
                final course = homeState.courses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        course.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${course.lectureHours}L - ${course.labHours}P',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          if (course.labHours > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: course.labType == 'Hardware Lab'
                                      ? Colors.orange.withOpacity(0.2)
                                      : Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: course.labType == 'Hardware Lab'
                                        ? Colors.orangeAccent
                                        : Colors.blueAccent,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  course.labType,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: course.labType == 'Hardware Lab'
                                        ? Colors.orangeAccent
                                        : Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                                      CourseFormScreen(initialCourse: course),
                                ),
                              );
                              if (result != null) {
                                homeNotifier.updateCourse(result);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => homeNotifier.deleteCourse(index),
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
