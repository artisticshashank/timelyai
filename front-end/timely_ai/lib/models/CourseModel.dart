class Course {
  final String id;
  final String name;
  final int lectureHours;
  final int labHours;
  final List<String> qualifiedInstructors;
  final List<String> equipment; // NEW: Added equipment list

  Course({
    required this.id,
    required this.name,
    required this.lectureHours,
    required this.labHours,
    required this.qualifiedInstructors,
    this.equipment = const [], // NEW: Initialize as empty list
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lectureHours': lectureHours,
      'labHours': labHours,
      'qualifiedInstructors': qualifiedInstructors,
      'equipment': equipment, // NEW: Include in JSON
    };
  }
}
