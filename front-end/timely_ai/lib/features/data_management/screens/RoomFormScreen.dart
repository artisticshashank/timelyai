import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timely_ai/features/home/widget/TagInputField.dart';
import 'package:timely_ai/models/RoomModel.dart';


class RoomFormScreen extends StatefulWidget {
  final Room? initialRoom;

  const RoomFormScreen({super.key, this.initialRoom});

  @override
  State<RoomFormScreen> createState() => _RoomFormScreenState();
}

class _RoomFormScreenState extends State<RoomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _capacityController;
  late String _selectedType;
  late List<String> _equipment;

  final List<String> _roomTypes = ['Lecture Hall', 'Computer Lab', 'Seminar Room', 'Lab'];

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.initialRoom?.id ?? '');
    _capacityController = TextEditingController(text: widget.initialRoom?.capacity.toString() ?? '');
    _selectedType = widget.initialRoom?.type ?? _roomTypes[0];
    _equipment = List<String>.from(widget.initialRoom?.equipment ?? []);
  }

  @override
  void dispose() {
    _idController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final room = Room(
        id: _idController.text,
        capacity: int.parse(_capacityController.text),
        type: _selectedType,
        equipment: _equipment,
      );
      Navigator.of(context).pop(room);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialRoom == null ? 'Add Room' : 'Edit Room'),
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
              controller: _idController,
              decoration: const InputDecoration(labelText: 'Room ID / Name'),
              validator: (value) => value!.isEmpty ? 'Please enter an ID' : null,
            ),
            TextFormField(
              controller: _capacityController,
              decoration: const InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => value!.isEmpty ? 'Please enter a capacity' : null,
            ),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Room Type'),
              items: _roomTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            TagInputField(
              labelText: 'Available Equipment',
              initialTags: _equipment,
              onChanged: (newTags) {
                setState(() {
                  _equipment = newTags;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

