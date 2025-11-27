import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timely_ai/features/data_management/controller/timetable_controller.dart';
import 'package:timely_ai/models/StudentGroupModel.dart';
import 'package:timely_ai/shared/widgets/glass_card.dart';
import 'package:timely_ai/shared/widgets/saas_scaffold.dart';

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
      if (_selectedCourseIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one enrolled course'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final studentGroup = StudentGroup(
        id: _idController.text.trim(),
        size: int.parse(_sizeController.text),
        enrolledCourses: _selectedCourseIds,
      );
      Navigator.of(context).pop(studentGroup);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCourses = ref.watch(homeControllerProvider).courses;

    return SaaSScaffold(
      title: widget.initialStudentGroup == null
          ? 'Add New Student Group'
          : 'Edit Student Group',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Enter group details and select enrolled courses',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 24),

            // Details Card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Group ID / Name *'),
                  TextFormField(
                    controller: _idController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('CS-Year1-A'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter an ID' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Group Size *'),
                  TextFormField(
                    controller: _sizeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('30'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a size' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Courses Card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Enrolled Courses *'),
                  const Text(
                    'Select all courses this group is enrolled in',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (allCourses.isEmpty)
                    const Text(
                      'No courses available. Please add courses first.',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ...allCourses.map((course) {
                    return CheckboxListTile(
                      title: Text(
                        course.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        '(${course.id})',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      value: _selectedCourseIds.contains(course.id),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.tealAccent, // Neon Teal
                      checkColor: Colors.black,
                      side: const BorderSide(color: Colors.white54),
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
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Save Group',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.tealAccent), // Neon Teal
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
