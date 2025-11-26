class StudentGroup {
  final String id;
  final int size;
  // A list of course IDs this group is enrolled in
  final List<String> enrolledCourses;

  StudentGroup({
    required this.id,
    required this.size,
    required this.enrolledCourses,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'size': size,
      'enrolledCourses': enrolledCourses,
    };
  }
}
