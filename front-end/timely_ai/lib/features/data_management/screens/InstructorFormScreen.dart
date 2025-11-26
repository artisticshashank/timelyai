import 'package:flutter/material.dart';
import 'package:timely_ai/models/InstructorModel.dart';

class InstructorFormScreen extends StatefulWidget {
  final Instructor? initialInstructor;

  const InstructorFormScreen({super.key, this.initialInstructor});

  @override
  State<InstructorFormScreen> createState() => _InstructorFormScreenState();
}

class _InstructorFormScreenState extends State<InstructorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late Map<String, List<int>> _availability;

  @override
  void initState() {
    super.initState();
    _name = widget.initialInstructor?.name ?? '';
    // Create a deep copy to avoid modifying the original map
    _availability = widget.initialInstructor != null
        ? Map<String, List<int>>.from(widget.initialInstructor!.availability.map((key, value) => MapEntry(key, List<int>.from(value))))
        : {
            'Monday': [1, 1, 1, 1],
            'Tuesday': [1, 1, 1, 1],
            'Wednesday': [1, 1, 1, 1],
            'Thursday': [1, 1, 1, 1],
            'Friday': [1, 1, 1, 1],
          };
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newInstructor = Instructor(
        id: widget.initialInstructor?.id ?? 'inst_${DateTime.now().millisecondsSinceEpoch}',
        name: _name,
        availability: _availability,
      );
      Navigator.of(context).pop(newInstructor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    final timeslots = ['09-10', '10-11', '11-12', '13-14'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialInstructor == null ? 'Add Instructor' : 'Edit Instructor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitForm,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Instructor Name', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.isEmpty) ? 'Please enter a name' : null,
              onSaved: (value) => _name = value!,
            ),
            const SizedBox(height: 24),
            Text('Availability', style: Theme.of(context).textTheme.titleLarge),
            const Text('Tap to toggle between available (blue) and unavailable (grey).'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Day')),
                  ...timeslots.map((time) => DataColumn(label: Text(time))),
                ],
                rows: days.map((day) {
                  return DataRow(cells: [
                    DataCell(Text(day)),
                    ...List.generate(timeslots.length, (index) {
                      return DataCell(
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _availability[day]![index] = _availability[day]![index] == 1 ? 0 : 1;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            color: _availability[day]![index] == 1 ? Colors.blue.shade100 : Colors.grey.shade300,
                          ),
                        ),
                      );
                    }),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
