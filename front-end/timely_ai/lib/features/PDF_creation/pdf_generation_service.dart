import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> generateAndPreview(List<Map<String, dynamic>> schedule) async {
    final pdf = pw.Document();

    // Reorganize the data for a grid layout
    final Map<String, Map<String, String>> gridData = {};
    final Set<String> days = {};
    final Set<String> timeslots = {};

    for (var item in schedule) {
      final day = item['day'] as String;
      final timeslot = item['timeslot'] as String;
      final course = item['course'] as String;
      final instructor = item['instructor'] as String;

      days.add(day);
      timeslots.add(timeslot);

      if (!gridData.containsKey(day)) {
        gridData[day] = {};
      }
      gridData[day]![timeslot] = '$course\n($instructor)';
    }

    final sortedDays = days.toList()..sort();
    final sortedTimeslots = timeslots.toList()..sort();

    // Build the PDF document
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Generated Timetable - Timely.AI', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Time', ...sortedDays],
                data: List<List<String>>.generate(
                  sortedTimeslots.length,
                  (rowIndex) => [
                    sortedTimeslots[rowIndex],
                    ...List<String>.generate(
                      sortedDays.length,
                      (colIndex) => gridData[sortedDays[colIndex]]?[sortedTimeslots[rowIndex]] ?? '',
                    ),
                  ],
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellAlignment: pw.Alignment.center,
                cellStyle: const pw.TextStyle(fontSize: 10),
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  for (int i = 1; i <= sortedDays.length; i++) i: const pw.FlexColumnWidth(2),
                },
              ),
              pw.Spacer(),
              pw.Footer(
                title: pw.Text('Timely.AI - Automatic Timetable Generation', style: pw.TextStyle(color: PdfColors.grey)),
              ),
            ],
          );
        },
      ),
    );

    // Use the 'printing' package to show a preview screen
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
