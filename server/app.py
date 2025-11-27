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
        settings = data.get('settings', {})

        # DEBUG: Print received data
        print(f"DEBUG: Received {len(student_groups)} student groups.")
        for sg in student_groups:
             print(f"DEBUG: Group {sg.get('id')} enrolled: {sg.get('enrolledCourses')}")

        model = cp_model.CpModel()

        # --- DATA PREPARATION ---
        all_instructors = {i['id']: i for i in instructors}
        all_courses = {c['id']: c for c in courses}
        all_rooms = {r['id']: r for r in rooms}
        all_student_groups = {sg['id']: sg for sg in student_groups}
        all_days = days
        all_timeslots = timeslots

        # Create unique tasks for each required session (lecture or lab)
        # REFACTOR: Tasks are now specific to a Student Group.
        # Task ID format: {sg_id}_{c_id}_{type}_{index}
        tasks = {}
        
        for sg_id, group in all_student_groups.items():
            enrolled_courses = group.get('enrolledCourses', [])
            for c_id in enrolled_courses:
                course = all_courses.get(c_id)
                if not course:
                    continue
                
                try:
                    lec_hours = int(course.get('lectureHours', 0))
                except (ValueError, TypeError):
                    lec_hours = 0
                
                try:
                    lab_hours = int(course.get('labHours', 0))
                except (ValueError, TypeError):
                    lab_hours = 0

                for i in range(lec_hours):
                    task_id = f'{sg_id}_{c_id}_lec_{i}'
                    tasks[task_id] = {
                        'course_id': c_id, 
                        'type': 'lecture',
                        'group_id': sg_id
                    }
                for i in range(lab_hours):
                    task_id = f'{sg_id}_{c_id}_lab_{i}'
                    tasks[task_id] = {
                        'course_id': c_id, 
                        'type': 'lab',
                        'group_id': sg_id
                    }

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
            # Check if any assignment variable exists for this task (it might not if no qualified instructor)
            possible_vars = [assign[(task_id, inst_id, room_id, day, timeslot)]
                                for inst_id in all_instructors for room_id in all_rooms
                                for day in all_days for timeslot in all_timeslots
                                if (task_id, inst_id, room_id, day, timeslot) in assign]
            if possible_vars:
                model.AddExactlyOne(possible_vars)

        # 2. No double booking
        for day in all_days:
            for timeslot in all_timeslots:
                # Instructor conflict
                for inst_id in all_instructors:
                    model.AddAtMostOne(assign.get((task_id, inst_id, room_id, day, timeslot))
                                       for task_id in tasks for room_id in all_rooms
                                       if assign.get((task_id, inst_id, room_id, day, timeslot)) is not None)
                
                # Room conflict
                for room_id in all_rooms:
                    model.AddAtMostOne(assign.get((task_id, inst_id, room_id, day, timeslot))
                                       for task_id in tasks for inst_id in all_instructors
                                       if assign.get((task_id, inst_id, room_id, day, timeslot)) is not None)
                
                # Student Group conflict
                # Since tasks are now group-specific, we just need to ensure that for a given group,
                # only one task is scheduled at a time.
                for sg_id in all_student_groups:
                    # Filter tasks belonging to this group
                    group_tasks = [tid for tid, t in tasks.items() if t['group_id'] == sg_id]
                    
                    model.AddAtMostOne(assign.get((task_id, inst_id, room_id, day, timeslot))
                                       for task_id in group_tasks for inst_id in all_instructors for room_id in all_rooms
                                       if assign.get((task_id, inst_id, room_id, day, timeslot)) is not None)

        # 3. Room capacity constraint
        for task_id, task_info in tasks.items():
            sg_id = task_info['group_id']
            group = all_student_groups[sg_id]
            
            try:
                group_size = int(group.get('size', 0))
            except (ValueError, TypeError):
                group_size = 0
            
            for room_id, room in all_rooms.items():
                try:
                    capacity = int(room.get('capacity', 0))
                except (ValueError, TypeError):
                    capacity = 0
                    
                if group_size > capacity:
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

        # 5. Guaranteed Lunch Break (Hard Constraint)
        # Implicitly handled.

        # 6. Lab Room Constraint
        # Labs must be scheduled in rooms of type 'Lab' or 'Computer Lab'
        for task_id, task_info in tasks.items():
            if task_info['type'] == 'lab':
                course = all_courses[task_info['course_id']]
                lab_type = course.get('labType', 'Computer Lab') # Default to Computer Lab

                for room_id, room in all_rooms.items():
                    room_type = room.get('type', '').lower()
                    
                    is_valid_room = False
                    if lab_type == 'Hardware Lab':
                        if 'hardware' in room_type:
                            is_valid_room = True
                    else: # Computer Lab
                        if 'computer' in room_type:
                            is_valid_room = True
                        # Fallback: if just 'lab' is specified, assume it's a generic lab (maybe computer)
                        # But to be strict, let's stick to the specific types if possible.
                        # If the room is just "Lab", we might allow it for Computer Lab but not Hardware Lab unless specified.
                        # For now, let's match "computer" for Computer Lab.
                        # If the user has rooms just named "Lab", they might need to update them.
                        # Let's allow "lab" for Computer Lab as a fallback if no "computer" rooms exist? 
                        # Or just stick to the plan: Computer Lab -> Computer Lab.
                        if 'lab' in room_type and 'hardware' not in room_type:
                             is_valid_room = True

                    
                    if not is_valid_room:
                        for inst_id in all_instructors:
                            for day in all_days:
                                for timeslot in all_timeslots:
                                    if (task_id, inst_id, room_id, day, timeslot) in assign:
                                        model.Add(assign[(task_id, inst_id, room_id, day, timeslot)] == 0)
            
            elif task_info['type'] == 'lecture':
                for room_id, room in all_rooms.items():
                    # Check if room type indicates it's a lab
                    room_type = room.get('type', '').lower()
                    is_lab_room = 'lab' in room_type or 'computer' in room_type
                    
                    if is_lab_room:
                        for inst_id in all_instructors:
                            for day in all_days:
                                for timeslot in all_timeslots:
                                    if (task_id, inst_id, room_id, day, timeslot) in assign:
                                        model.Add(assign[(task_id, inst_id, room_id, day, timeslot)] == 0)

        # --- NEW CONSTRAINTS ---

        # 6. No Repeating Classes per Day for a Student Group (Lectures)
        for sg_id, group in all_student_groups.items():
            enrolled_courses = group.get('enrolledCourses', [])
            for course_id in enrolled_courses:
                # Get all lecture tasks for this course AND this group
                course_lec_tasks = [tid for tid, t in tasks.items() 
                                  if t['course_id'] == course_id and t['type'] == 'lecture' and t['group_id'] == sg_id]
                
                if len(course_lec_tasks) > 1:
                    for day in all_days:
                        # Sum of assignments for this course for this group on this day must be <= 1
                        daily_assignments = []
                        for task_id in course_lec_tasks:
                            for inst_id in all_instructors:
                                for room_id in all_rooms:
                                    for timeslot in all_timeslots:
                                        if (task_id, inst_id, room_id, day, timeslot) in assign:
                                            daily_assignments.append(assign[(task_id, inst_id, room_id, day, timeslot)])
                        
                        if daily_assignments:
                            model.Add(sum(daily_assignments) <= 1)

        # 7. Consecutive Labs
        # Labs must be 2 hours long and cannot span across breaks.
        
        # Map timeslot strings to indices for easier handling
        ts_to_index = {ts: i for i, ts in enumerate(all_timeslots)}
        
        for sg_id, group in all_student_groups.items():
            enrolled_courses = group.get('enrolledCourses', [])
            for course_id in enrolled_courses:
                course = all_courses.get(course_id)
                if not course: continue

                try:
                    lab_hours = int(course.get('labHours', 0))
                except (ValueError, TypeError):
                    lab_hours = 0
                    
                if lab_hours > 0:
                    # Tasks are now: {sg_id}_{c_id}_lab_{i}
                    for i in range(0, lab_hours, 2):
                        if i + 1 < lab_hours:
                            lab_task_1 = f'{sg_id}_{course_id}_lab_{i}'
                            lab_task_2 = f'{sg_id}_{course_id}_lab_{i+1}'
                            
                            if lab_task_1 in tasks and lab_task_2 in tasks:
                                for day in all_days:
                                    for inst_id in all_instructors: # Assuming same instructor for both hours
                                        for room_id in all_rooms:   # Assuming same room for both hours
                                            
                                            # For each starting slot t, if we assign lab_1 at t, we MUST assign lab_2 at t+1
                                            for t_idx in range(len(all_timeslots) - 1):
                                                t1 = all_timeslots[t_idx]
                                                t2 = all_timeslots[t_idx + 1]
                                                
                                                # Check if this pair is valid (continuous and not spanning break)
                                                # Valid pairs: (0,1), (2,3), (4,5), (5,6)
                                                is_valid_pair = False
                                                if t_idx == 0: is_valid_pair = True # 08:30 - 10:30
                                                elif t_idx == 2: is_valid_pair = True # 11:00 - 01:00
                                                elif t_idx >= 4: is_valid_pair = True # 02:00 - 04:00, 03:00 - 05:00
                                                
                                                if (lab_task_1, inst_id, room_id, day, t1) in assign and \
                                                   (lab_task_2, inst_id, room_id, day, t2) in assign:
                                                    
                                                    if is_valid_pair:
                                                        # If lab_1 is at t1, lab_2 MUST be at t2
                                                        model.Add(assign[(lab_task_2, inst_id, room_id, day, t2)] == 
                                                                  assign[(lab_task_1, inst_id, room_id, day, t1)])
                                                    else:
                                                        # Invalid pair (spans break), forbid starting at t1
                                                        model.Add(assign[(lab_task_1, inst_id, room_id, day, t1)] == 0)

        # --- SOFT CONSTRAINTS (OBJECTIVES) ---
        objectives = []

        # 6. Minimize Gaps for Students
        gap_priority = settings.get('gapPriority', 0.0)
        if gap_priority > 0:
            weight = int(gap_priority * 10) # 10 or 20
            
            # Map timeslots to indices
            ts_map = {ts: i for i, ts in enumerate(all_timeslots)}
            num_slots = len(all_timeslots)
            
            for sg_id, group in all_student_groups.items():
                # Filter tasks for this group
                group_tasks = [tid for tid, t in tasks.items() if t['group_id'] == sg_id]
                
                for day in all_days:
                    # Create boolean vars for "is slot t occupied for this group"
                    slot_active = [model.NewBoolVar(f'active_{sg_id}_{day}_{t}') for t in range(num_slots)]
                    
                    for t_idx, ts in enumerate(all_timeslots):
                        # Gather all possible assignments for this group in this slot
                        possible_assigns = []
                        for task_id in group_tasks:
                            for inst_id in all_instructors:
                                for room_id in all_rooms:
                                    if (task_id, inst_id, room_id, day, ts) in assign:
                                        possible_assigns.append(assign[(task_id, inst_id, room_id, day, ts)])
                        
                        # Link slot_active to assignments
                        if possible_assigns:
                            model.AddMaxEquality(slot_active[t_idx], possible_assigns)
                        else:
                            model.Add(slot_active[t_idx] == 0)
                    
                    # Calculate span: max_index - min_index
                    has_classes = model.NewBoolVar(f'has_classes_{sg_id}_{day}')
                    model.AddMaxEquality(has_classes, slot_active)
                    
                    min_slot = model.NewIntVar(0, num_slots, f'min_slot_{sg_id}_{day}')
                    max_slot = model.NewIntVar(0, num_slots, f'max_slot_{sg_id}_{day}')

                    for t in range(num_slots):
                        model.Add(min_slot <= t).OnlyEnforceIf(slot_active[t])
                        model.Add(max_slot >= t).OnlyEnforceIf(slot_active[t])
                    
                    total_active = sum(slot_active)
                    span = model.NewIntVar(0, num_slots, f'span_{sg_id}_{day}')
                    model.Add(span == max_slot - min_slot + 1).OnlyEnforceIf(has_classes)
                    model.Add(span == 0).OnlyEnforceIf(has_classes.Not())
                    
                    gaps = model.NewIntVar(0, num_slots, f'gaps_{sg_id}_{day}')
                    model.Add(gaps == span - total_active)
                    
                    objectives.append(gaps * weight)

        # 7. Fair Instructor Workload
        if settings.get('fairWorkload', False):
            weight = 5
            instructor_hours = []
            for inst_id in all_instructors:
                # Sum all assignments for this instructor
                inst_assigns = []
                for key, var in assign.items():
                    if key[1] == inst_id: # key is (task_id, inst_id, room_id, day, timeslot)
                        inst_assigns.append(var)
                
                hours = model.NewIntVar(0, len(all_timeslots) * len(all_days), f'hours_{inst_id}')
                model.Add(hours == sum(inst_assigns))
                instructor_hours.append(hours)
            
            if instructor_hours:
                min_h = model.NewIntVar(0, 100, 'min_hours')
                max_h = model.NewIntVar(0, 100, 'max_hours')
                
                model.AddMinEquality(min_h, instructor_hours)
                model.AddMaxEquality(max_h, instructor_hours)
                
                diff = model.NewIntVar(0, 100, 'diff_hours')
                model.Add(diff == max_h - min_h)
                
                objectives.append(diff * weight)

        # 8. Preferred Morning Classes
        preferred_courses = set(settings.get('preferredMorningCourses', []))
        if preferred_courses:
            weight = 2
            # Morning slots: Ends with AM
            
            for (task_id, inst_id, room_id, day, timeslot), var in assign.items():
                task_info = tasks[task_id]
                if task_info['course_id'] in preferred_courses:
                    if 'PM' in timeslot and not timeslot.startswith('12'): # 12 PM is noon, arguably morning/lunch, but let's say strictly AM
                         # Penalize if NOT in morning (so if it is PM, penalize)
                         # Actually, let's be stricter: Must be AM.
                         if 'AM' not in timeslot:
                            objectives.append(var * weight)

        # Minimize total penalty
        if objectives:
            model.Minimize(sum(objectives))
        
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
                    sg_id = task_info['group_id']
                    
                    # Get group name
                    group_name = all_student_groups[sg_id]['id'] # Or name if available

                    schedule.append({
                        'day': day,
                        'timeslot': timeslot,
                        'courseId': course_id,
                        'course': all_courses[course_id]['name'],
                        'instructor': all_instructors[inst_id]['name'],
                        'room': room_id,
                        'group': group_name,
                        'type': task_info['type'] # 'lecture' or 'lab'
                    })
            return jsonify({'status': 'success', 'schedule': schedule})
        else:
            return jsonify({'status': 'error', 'message': 'No solution found for the given constraints.'}), 400

    except Exception as e:
        import traceback
        traceback.print_exc()
        # This will now give a more descriptive error message in the app
        return jsonify({'status': 'error', 'message': f"Server crashed: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

