import 'package:flutter_riverpod/legacy.dart';
import 'package:timely_ai/models/CourseModel.dart';
import 'package:timely_ai/models/InstructorModel.dart';
import 'package:timely_ai/models/RoomModel.dart';
import 'package:timely_ai/models/StudentGroupModel.dart';

// The state class that holds all our application data.
class HomeState {
  final List<Instructor> instructors;
  final List<Course> courses;
  final List<Room> rooms;
  final List<StudentGroup> studentGroups;
  final List<String> days;
  final List<String> timeslots;

  HomeState({
    required this.instructors,
    required this.courses,
    required this.rooms,
    required this.studentGroups,
    required this.days,
    required this.timeslots,
  });

  // A copyWith method to easily create a new state object with updated values.
  HomeState copyWith({
    List<Instructor>? instructors,
    List<Course>? courses,
    List<Room>? rooms,
    List<StudentGroup>? studentGroups,
  }) {
    return HomeState(
      instructors: instructors ?? this.instructors,
      courses: courses ?? this.courses,
      rooms: rooms ?? this.rooms,
      studentGroups: studentGroups ?? this.studentGroups,
      days: days,
      timeslots: timeslots,
    );
  }
}

// The StateNotifier class that manages our HomeState.
class HomeController extends StateNotifier<HomeState> {
  HomeController() : super(_getInitialState());

  // Initializes the state with sample data.
  static HomeState _getInitialState() {
    return HomeState(
      instructors: [
        Instructor(
          id: 'inst_1',
          name: 'Dr. Smith',
          availability: {
            'Monday': [1, 1, 1, 0],
            'Tuesday': [1, 1, 1, 1],
            'Wednesday': [1, 1, 0, 0],
            'Thursday': [1, 1, 1, 1],
            'Friday': [0, 0, 1, 1],
          },
        ),
        Instructor(
          id: 'inst_2',
          name: 'Prof. Jones',
          availability: {
            'Monday': [1, 1, 1, 1],
            'Tuesday': [0, 0, 1, 1],
            'Wednesday': [1, 1, 1, 1],
            'Thursday': [1, 0, 1, 0],
            'Friday': [1, 1, 1, 1],
          },
        ),
      ],
      courses: [
        Course(
          id: 'c_1',
          name: 'CS101',
          lectureHours: 3,
          labHours: 0,
          qualifiedInstructors: ['inst_1'],
          equipment: ['Projector'],
        ),
        Course(
          id: 'c_2',
          name: 'MA203',
          lectureHours: 4,
          labHours: 0,
          qualifiedInstructors: ['inst_2'],
        ),
        Course(
          id: 'c_3',
          name: 'PHY-LAB',
          lectureHours: 0,
          labHours: 2,
          qualifiedInstructors: ['inst_1'],
          equipment: ['Lab Kit'],
        ),
      ],
      rooms: [
        Room(
          id: 'Room 101',
          capacity: 50,
          type: 'Lecture Hall',
          equipment: ['Projector'],
        ),
        Room(id: 'Room 102', capacity: 50, type: 'Lecture Hall'),
        Room(
          id: 'Physics Lab',
          capacity: 30,
          type: 'Lab',
          equipment: ['Lab Kit', 'Oscilloscope'],
        ),
      ],
      studentGroups: [
        StudentGroup(
          id: 'sg_1',
          size: 45,
          enrolledCourses: ['c_1', 'c_2', 'c_3'],
        ),
      ],
      days: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
      timeslots: ['09-10', '10-11', '11-12', '13-14'],
    );
  }

  // --- METHODS FOR INSTRUCTOR MANIPULATION ---
  void addInstructor(Instructor instructor) {
    state = state.copyWith(instructors: [...state.instructors, instructor]);
  }

  void updateInstructor(Instructor updatedInstructor) {
    state = state.copyWith(
      instructors: [
        for (final instructor in state.instructors)
          if (instructor.id == updatedInstructor.id)
            updatedInstructor
          else
            instructor,
      ],
    );
  }

  void deleteInstructor(int index) {
    final newList = List<Instructor>.from(state.instructors)..removeAt(index);
    state = state.copyWith(instructors: newList);
  }

  // --- METHODS FOR COURSE MANIPULATION ---
  void addCourse(Course course) {
    state = state.copyWith(courses: [...state.courses, course]);
  }

  void updateCourse(Course updatedCourse) {
    state = state.copyWith(
      courses: [
        for (final course in state.courses)
          if (course.id == updatedCourse.id) updatedCourse else course,
      ],
    );
  }

  void deleteCourse(int index) {
    final newList = List<Course>.from(state.courses)..removeAt(index);
    state = state.copyWith(courses: newList);
  }

  // --- METHODS FOR ROOM MANIPULATION ---
  void addRoom(Room room) {
    state = state.copyWith(rooms: [...state.rooms, room]);
  }

  void updateRoom(Room updatedRoom) {
    state = state.copyWith(
      rooms: [
        for (final room in state.rooms)
          if (room.id == updatedRoom.id) updatedRoom else room,
      ],
    );
  }

  void deleteRoom(int index) {
    final newList = List<Room>.from(state.rooms)..removeAt(index);
    state = state.copyWith(rooms: newList);
  }

  // --- METHODS FOR STUDENT GROUP MANIPULATION ---
  void addStudentGroup(StudentGroup group) {
    state = state.copyWith(studentGroups: [...state.studentGroups, group]);
  }

  void updateStudentGroup(StudentGroup updatedGroup) {
    state = state.copyWith(
      studentGroups: [
        for (final group in state.studentGroups)
          if (group.id == updatedGroup.id) updatedGroup else group,
      ],
    );
  }

  void deleteStudentGroup(int index) {
    final newList = List<StudentGroup>.from(state.studentGroups)
      ..removeAt(index);
    state = state.copyWith(studentGroups: newList);
  }
}

// The provider that makes the HomeController available throughout the app.
final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) {
    return HomeController();
  },
);
