import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timely_ai/models/RoomModel.dart';
import 'package:timely_ai/shared/widgets/glass_card.dart';
import 'package:timely_ai/shared/widgets/saas_scaffold.dart';

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
  late TextEditingController _equipmentController;
  late String _selectedType;
  late List<String> _equipment;

  final List<String> _roomTypes = [
    'Lecture Hall',
    'Computer Lab',
    'Hardware Lab',
    'Seminar Room',
    'Lab',
  ];

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.initialRoom?.id ?? '');
    _capacityController = TextEditingController(
      text: widget.initialRoom?.capacity.toString() ?? '',
    );
    _equipmentController = TextEditingController();
    _selectedType = widget.initialRoom?.type ?? _roomTypes[0];
    _equipment = List<String>.from(widget.initialRoom?.equipment ?? []);
  }

  @override
  void dispose() {
    _idController.dispose();
    _capacityController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  void _addEquipment() {
    final text = _equipmentController.text.trim();
    if (text.isNotEmpty && !_equipment.contains(text)) {
      setState(() {
        _equipment.add(text);
        _equipmentController.clear();
      });
    }
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
    return SaaSScaffold(
      title: widget.initialRoom == null ? 'Add New Room' : 'Edit Room',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Enter room details and available equipment',
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
                  _buildLabel('Room ID / Name *'),
                  TextFormField(
                    controller: _idController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Room A101'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter an ID' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Capacity *'),
                  TextFormField(
                    controller: _capacityController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('30'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a capacity' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Room Type *'),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Select Type'),
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Equipment Card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Available Equipment'),
                  const Text(
                    'Type equipment name and press Enter or click Add',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _equipmentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('e.g., Projector'),
                          onFieldSubmitted: (_) => _addEquipment(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _addEquipment,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  if (_equipment.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _equipment.map((e) {
                        return Chip(
                          label: Text(
                            e,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.white.withOpacity(0.1),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white54,
                          ),
                          onDeleted: () {
                            setState(() {
                              _equipment.remove(e);
                            });
                          },
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                  ],
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
                    'Save Room',
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
        borderSide: const BorderSide(color: Color(0xFFFF4E50)), // Neon Red
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
