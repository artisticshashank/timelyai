import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely_ai/features/data_management/controller/timetable_controller.dart';
import 'package:timely_ai/models/StudentGroupModel.dart';

class StudentGroupFormScreen extends ConsumerStatefulWidget {
  final StudentGroup? initialStudentGroup;

  const StudentGroupFormScreen({super.key, this.initialStudentGroup});

  @override
  ConsumerState<StudentGroupFormScreen> createState() =>
      _StudentGroupFormScreenState();
}

class _StudentGroupFormScreenState
    extends ConsumerState<StudentGroupFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _idController;
  late TextEditingController _sizeController;
  late List<String> _selectedCourseIds;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(
      text: widget.initialStudentGroup?.id ?? '',
    );
    // --- FIX: Made the .toString() call null-safe to prevent crash when adding a new group ---
    _sizeController = TextEditingController(
      text: (widget.initialStudentGroup?.size)?.toString() ?? '',
    );
    _selectedCourseIds = List<String>.from(
      widget.initialStudentGroup?.enrolledCourses ?? [],
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final studentGroup = StudentGroup(
        id: _idController.text,

        size: int.parse(_sizeController.text),
        enrolledCourses: _selectedCourseIds,
      );
      Navigator.of(context).pop(studentGroup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCourses = ref.watch(homeControllerProvider).courses;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialStudentGroup == null ? 'Add Group' : 'Edit Group',
        ),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _submit)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'Group ID'),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter an ID' : null,
            ),
            TextFormField(
              controller: _sizeController,
              decoration: const InputDecoration(labelText: 'Group Size'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) =>
                  value!.isEmpty ? 'Please enter a size' : null,
            ),
            const SizedBox(height: 20),
            const Text(
              'Enrolled Courses',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...allCourses.map((course) {
              return CheckboxListTile(
                title: Text(course.name),
                subtitle: Text(course.id),
                value: _selectedCourseIds.contains(course.id),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedCourseIds.add(course.id);
                    } else {
                      _selectedCourseIds.remove(course.id);
                    }
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
