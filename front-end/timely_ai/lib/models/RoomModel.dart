class Room {
  final String id;
  final int capacity;
  final String type;
  final List<String> equipment; // NEW: Added equipment list

  Room({
    required this.id,
    required this.capacity,
    required this.type,
    this.equipment = const [], // NEW: Initialize as empty list
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'capacity': capacity,
      'type': type,
      'equipment': equipment, // NEW: Include in JSON
    };
  }
}

