import 'package:flutter/material.dart';
import 'package:timely_ai/features/PDF_creation/pdf_generation_service.dart';

class TimetableViewScreen extends StatelessWidget {
  final List<Map<String, dynamic>> schedule;

  const TimetableViewScreen({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generated Timetable')),
      body: ListView.builder(
        itemCount: schedule.length,
        itemBuilder: (context, index) {
          final item = schedule[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo[100],
                child: Text(item['day'].substring(0, 1)),
              ),
              title: Text('${item['course']} - ${item['instructor']}'),
              subtitle: Text('Day: ${item['day']}, Time: ${item['timeslot']}'),
            ),
          );
        },
      ),
      // --- Floating Action Button to generate the PDF ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Call our PDF generator service
          PdfGenerator.generateAndPreview(schedule);
        },
        label: const Text('Save as PDF'),
        icon: const Icon(Icons.picture_as_pdf),
      ),
    );
  }
}
