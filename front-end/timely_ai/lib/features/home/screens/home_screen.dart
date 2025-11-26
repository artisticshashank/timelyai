import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely_ai/features/data_management/controller/timetable_controller.dart';
import 'package:timely_ai/features/data_management/repository/timetable_repository.dart';
import 'package:timely_ai/features/data_management/screens/CourseFormScreen.dart';
import 'package:timely_ai/features/data_management/screens/InstructorFormScreen.dart';
import 'package:timely_ai/features/data_management/screens/RoomFormScreen.dart';
import 'package:timely_ai/features/data_management/screens/StudentGroupFormScreen.dart';
import 'package:timely_ai/features/data_management/screens/data_management_screen.dart';
import 'package:timely_ai/features/timetable/screens/timetable_view_screen.dart';
import 'package:timely_ai/models/CourseModel.dart';
import 'package:timely_ai/models/InstructorModel.dart';
import 'package:timely_ai/models/RoomModel.dart';
import 'package:timely_ai/models/StudentGroupModel.dart';

// The main UI screen for the application.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Handles calling the backend to generate the timetable.
  void _generateTimetable(BuildContext context, WidgetRef ref) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await ref
          .read(timetableRepositoryProvider)
          .generateTimetable();

      // --- FIX: Safely cast the schedule list ---
      // The JSON decoder gives us a List<dynamic>, but our UI needs a List<Map<String, dynamic>>.
      // We create a new, correctly typed list to prevent the TypeError.
      final List<dynamic> dynamicSchedule = result['schedule'];
      final List<Map<String, dynamic>> typedSchedule =
          List<Map<String, dynamic>>.from(dynamicSchedule);

      Navigator.of(context).pop(); // Close loading dialog
      Navigator.of(context).push(
        MaterialPageRoute(
          // Pass the new, correctly typed list to the screen.
          builder: (context) => TimetableViewScreen(schedule: typedSchedule),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  // --- Navigation logic for managing instructors ---
  void _manageInstructors(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DataManagementScreen<Instructor>(
          title: 'Manage Instructors',
          items: ref.watch(homeControllerProvider).instructors,
          itemTitleBuilder: (instructor) => instructor.name,
          onDelete: (index) {
            ref.read(homeControllerProvider.notifier).deleteInstructor(index);
          },
          onEdit: (context, instructor) async {
            final result = await Navigator.of(context).push<Instructor>(
              MaterialPageRoute(
                builder: (context) =>
                    InstructorFormScreen(initialInstructor: instructor),
              ),
            );
            if (result != null) {
              if (instructor == null) {
                ref.read(homeControllerProvider.notifier).addInstructor(result);
              } else {
                ref
                    .read(homeControllerProvider.notifier)
                    .updateInstructor(result);
              }
            }
          },
        ),
      ),
    );
  }

  // --- Navigation logic for managing courses ---
  void _manageCourses(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DataManagementScreen<Course>(
          title: 'Manage Courses',
          items: ref.watch(homeControllerProvider).courses,
          itemTitleBuilder: (course) => course.name,
          onDelete: (index) {
            ref.read(homeControllerProvider.notifier).deleteCourse(index);
          },
          onEdit: (context, course) async {
            final result = await Navigator.of(context).push<Course>(
              MaterialPageRoute(
                builder: (context) => CourseFormScreen(initialCourse: course),
              ),
            );
            if (result != null) {
              if (course == null) {
                ref.read(homeControllerProvider.notifier).addCourse(result);
              } else {
                ref.read(homeControllerProvider.notifier).updateCourse(result);
              }
            }
          },
        ),
      ),
    );
  }

  // --- Navigation logic for managing rooms ---
  void _manageRooms(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DataManagementScreen<Room>(
          title: 'Manage Rooms',
          items: ref.watch(homeControllerProvider).rooms,
          itemTitleBuilder: (room) => room.id,
          onDelete: (index) {
            ref.read(homeControllerProvider.notifier).deleteRoom(index);
          },
          onEdit: (context, room) async {
            final result = await Navigator.of(context).push<Room>(
              MaterialPageRoute(
                builder: (context) => RoomFormScreen(initialRoom: room),
              ),
            );
            if (result != null) {
              if (room == null) {
                ref.read(homeControllerProvider.notifier).addRoom(result);
              } else {
                ref.read(homeControllerProvider.notifier).updateRoom(result);
              }
            }
          },
        ),
      ),
    );
  }

  // --- Navigation logic for managing student groups ---
  void _manageStudentGroups(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DataManagementScreen<StudentGroup>(
          title: 'Manage Student Groups',
          items: ref.watch(homeControllerProvider).studentGroups,
          itemTitleBuilder: (group) => group.id,
          onDelete: (index) {
            ref.read(homeControllerProvider.notifier).deleteStudentGroup(index);
          },
          onEdit: (context, group) async {
            final result = await Navigator.of(context).push<StudentGroup>(
              MaterialPageRoute(
                builder: (context) =>
                    StudentGroupFormScreen(initialStudentGroup: group),
              ),
            );
            if (result != null) {
              if (group == null) {
                ref
                    .read(homeControllerProvider.notifier)
                    .addStudentGroup(result);
              } else {
                ref
                    .read(homeControllerProvider.notifier)
                    .updateStudentGroup(result);
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the home controller's state for changes.
    final homeState = ref.watch(homeControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Timely.AI Dashboard')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                // Card for navigating to instructor management.
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Manage Instructors'),
                    subtitle: Text(
                      '${homeState.instructors.length} instructors',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _manageInstructors(context, ref),
                  ),
                ),
                // Card for navigating to course management.
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.book_outlined),
                    title: const Text('Manage Courses'),
                    subtitle: Text('${homeState.courses.length} courses'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _manageCourses(context, ref),
                  ),
                ),
                // Card for navigating to room management.
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.room_outlined),
                    title: const Text('Manage Rooms'),
                    subtitle: Text('${homeState.rooms.length} rooms'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _manageRooms(context, ref),
                  ),
                ),
                // Card for navigating to student group management.
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.group_outlined),
                    title: const Text('Manage Student Groups'),
                    subtitle: Text('${homeState.studentGroups.length} groups'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _manageStudentGroups(context, ref),
                  ),
                ),
              ],
            ),
          ),
          // Bottom section with the main action button.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _generateTimetable(context, ref),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Timetable'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
