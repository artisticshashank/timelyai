import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely_ai/features/data_management/controller/timetable_controller.dart';
import 'package:timely_ai/features/home/widget/TagInputField.dart';
import 'package:timely_ai/models/CourseModel.dart';


class CourseFormScreen extends ConsumerStatefulWidget {
  final Course? initialCourse;

  const CourseFormScreen({super.key, this.initialCourse});

  @override
  ConsumerState<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends ConsumerState<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _lectureHoursController;
  late TextEditingController _labHoursController;
  late List<String> _selectedInstructorIds;
  late List<String> _equipment;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialCourse?.name ?? '');
    _idController = TextEditingController(text: widget.initialCourse?.id ?? '');
    _lectureHoursController = TextEditingController(text: widget.initialCourse?.lectureHours.toString() ?? '0');
    _labHoursController = TextEditingController(text: widget.initialCourse?.labHours.toString() ?? '0');
    _selectedInstructorIds = List<String>.from(widget.initialCourse?.qualifiedInstructors ?? []);
    _equipment = List<String>.from(widget.initialCourse?.equipment ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _lectureHoursController.dispose();
    _labHoursController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final course = Course(
        id: _idController.text,
        name: _nameController.text,
        lectureHours: int.parse(_lectureHoursController.text),
        labHours: int.parse(_labHoursController.text),
        qualifiedInstructors: _selectedInstructorIds,
        equipment: _equipment,
      );
      Navigator.of(context).pop(course);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allInstructors = ref.watch(homeControllerProvider).instructors;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialCourse == null ? 'Add Course' : 'Edit Course'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submit,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Course Name'),
              validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
            ),
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'Course ID'),
              validator: (value) => value!.isEmpty ? 'Please enter an ID' : null,
            ),
            TextFormField(
              controller: _lectureHoursController,
              decoration: const InputDecoration(labelText: 'Lecture Hours per Week'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            TextFormField(
              controller: _labHoursController,
              decoration: const InputDecoration(labelText: 'Lab Hours per Week'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),
            // --- NEW: Using the TagInputField for equipment ---
            TagInputField(
              labelText: 'Required Equipment',
              initialTags: _equipment,
              onChanged: (newTags) {
                setState(() {
                  _equipment = newTags;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text('Qualified Instructors', style: TextStyle(fontWeight: FontWeight.bold)),
            ...allInstructors.map((instructor) {
              return CheckboxListTile(
                title: Text(instructor.name),
                subtitle: Text(instructor.id),
                value: _selectedInstructorIds.contains(instructor.id),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedInstructorIds.add(instructor.id);
                    } else {
                      _selectedInstructorIds.remove(instructor.id);
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

