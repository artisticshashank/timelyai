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
  final Map<String, dynamic> settings;

  HomeState({
    required this.instructors,
    required this.courses,
    required this.rooms,
    required this.studentGroups,
    required this.days,
    required this.timeslots,
    this.settings = const {},
  });

  // A copyWith method to easily create a new state object with updated values.
  HomeState copyWith({
    List<Instructor>? instructors,
    List<Course>? courses,
    List<Room>? rooms,
    List<StudentGroup>? studentGroups,
    Map<String, dynamic>? settings,
  }) {
    return HomeState(
      instructors: instructors ?? this.instructors,
      courses: courses ?? this.courses,
      rooms: rooms ?? this.rooms,
      studentGroups: studentGroups ?? this.studentGroups,
      days: days,
      timeslots: timeslots,
      settings: settings ?? this.settings,
    );
  }
}

// The StateNotifier class that manages our HomeState.
class HomeController extends StateNotifier<HomeState> {
  HomeController() : super(_getInitialState());

  // Initializes the state with sample data.
  static HomeState _getInitialState() {
    return HomeState(
      instructors: [],
      courses: [],
      rooms: [],
      studentGroups: [],
      days: [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ],
      timeslots: [
        '08:30 AM - 09:30 AM',
        '09:30 AM - 10:30 AM',
        '11:00 AM - 12:00 PM',
        '12:00 PM - 01:00 PM',
        '02:00 PM - 03:00 PM',
        '03:00 PM - 04:00 PM',
        '04:00 PM - 05:00 PM',
      ],
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

  // --- METHODS FOR SETTINGS MANIPULATION ---
  void updateSettings(Map<String, dynamic> newSettings) {
    state = state.copyWith(settings: newSettings);
  }
}

// The provider that makes the HomeController available throughout the app.
final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) {
    return HomeController();
  },
);
