from flask import Flask, request, jsonify
from flask_cors import CORS
from ortools.sat.python import cp_model

app = Flask(__name__)
CORS(app)

@app.route('/generate-timetable', methods=['POST'])
def generate_timetable():
    try:
        data = request.get_json()
        instructors = data.get('instructors', [])
        courses = data.get('courses', [])
        rooms = data.get('rooms', [])
        student_groups = data.get('student_groups', [])
        days = data.get('days', [])
        timeslots = data.get('timeslots', [])

        model = cp_model.CpModel()

        # --- DATA PREPARATION ---
        all_instructors = {i['id']: i for i in instructors}
        all_courses = {c['id']: c for c in courses}
        all_rooms = {r['id']: r for r in rooms}
        all_student_groups = {sg['id']: sg for sg in student_groups}
        all_days = days
        all_timeslots = timeslots

        # Create unique tasks for each required session (lecture or lab)
        tasks = {}
        for c_id, course in all_courses.items():
            for i in range(course.get('lectureHours', 0)):
                task_id = f'{c_id}_lec_{i}'
                tasks[task_id] = {'course_id': c_id, 'type': 'lecture'}
            for i in range(course.get('labHours', 0)):
                task_id = f'{c_id}_lab_{i}'
                tasks[task_id] = {'course_id': c_id, 'type': 'lab'}

        # --- CREATE VARIABLES ---
        assign = {}
        for task_id, task_info in tasks.items():
            course_id = task_info['course_id']
            course = all_courses[course_id]
            for inst_id in course.get('qualifiedInstructors', []):
                for room_id in all_rooms:
                    for day in all_days:
                        for timeslot in all_timeslots:
                            assign[(task_id, inst_id, room_id, day, timeslot)] = model.NewBoolVar(f'assign_{task_id}_{inst_id}_{room_id}_{day}_{timeslot}')

        # --- HARD CONSTRAINTS ---

        # 1. Each task must be scheduled exactly once
        for task_id in tasks:
            model.AddExactlyOne(assign[(task_id, inst_id, room_id, day, timeslot)]
                                for inst_id in all_instructors for room_id in all_rooms
                                for day in all_days for timeslot in all_timeslots
                                if (task_id, inst_id, room_id, day, timeslot) in assign)

        # 2. No double booking
        for day in all_days:
            for timeslot in all_timeslots:
                for inst_id in all_instructors:
                    model.AddAtMostOne(assign.get((task_id, inst_id, room_id, day, timeslot))
                                       for task_id in tasks for room_id in all_rooms
                                       if assign.get((task_id, inst_id, room_id, day, timeslot)) is not None)
                for room_id in all_rooms:
                    model.AddAtMostOne(assign.get((task_id, inst_id, room_id, day, timeslot))
                                       for task_id in tasks for inst_id in all_instructors
                                       if assign.get((task_id, inst_id, room_id, day, timeslot)) is not None)
                for sg_id, group in all_student_groups.items():
                    group_tasks = [task_id for task_id, task_info in tasks.items() if task_info['course_id'] in group.get('enrolledCourses', [])]
                    model.AddAtMostOne(assign.get((task_id, inst_id, room_id, day, timeslot))
                                       for task_id in group_tasks for inst_id in all_instructors for room_id in all_rooms
                                       if assign.get((task_id, inst_id, room_id, day, timeslot)) is not None)

        # 3. Room capacity constraint
        for task_id, task_info in tasks.items():
            course_id = task_info['course_id']
            group_size = 0
            for sg in all_student_groups.values():
                if course_id in sg.get('enrolledCourses', []):
                    group_size = sg.get('size', 0)
                    break
            
            for room_id, room in all_rooms.items():
                if group_size > room.get('capacity', 0):
                    for inst_id in all_instructors:
                        for day in all_days:
                            for timeslot in all_timeslots:
                                if (task_id, inst_id, room_id, day, timeslot) in assign:
                                    model.Add(assign[(task_id, inst_id, room_id, day, timeslot)] == 0)

        # 4. Equipment constraint
        for task_id, task_info in tasks.items():
            course = all_courses[task_info['course_id']]
            required_equipment = set(course.get('equipment', []))
            
            if required_equipment:
                for room_id, room in all_rooms.items():
                    room_equipment = set(room.get('equipment', []))
                    if not required_equipment.issubset(room_equipment):
                        for inst_id in all_instructors:
                             for day in all_days:
                                for timeslot in all_timeslots:
                                    if (task_id, inst_id, room_id, day, timeslot) in assign:
                                        model.Add(assign[(task_id, inst_id, room_id, day, timeslot)] == 0)
        
        # --- SOLVE ---
        solver = cp_model.CpSolver()
        solver.parameters.max_time_in_seconds = 30.0
        status = solver.Solve(model)

        # --- PROCESS RESULTS ---
        if status == cp_model.OPTIMAL or status == cp_model.FEASIBLE:
            schedule = []
            for (task_id, inst_id, room_id, day, timeslot), var in assign.items():
                if solver.Value(var) == 1:
                    task_info = tasks[task_id]
                    course_id = task_info['course_id']
                    group_name = next((sg['name'] for sg in all_student_groups.values() if course_id in sg.get('enrolledCourses', [])), 'Unknown')
                    schedule.append({
                        'day': day,
                        'timeslot': timeslot,
                        'course': all_courses[course_id]['name'],
                        'instructor': all_instructors[inst_id]['name'],
                        'room': room_id,
                        'group': group_name
                    })
            return jsonify({'status': 'success', 'schedule': schedule})
        else:
            return jsonify({'status': 'error', 'message': 'No solution found for the given constraints.'}), 400

    except Exception as e:
        # This will now give a more descriptive error message in the app
        return jsonify({'status': 'error', 'message': f"Server crashed: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

