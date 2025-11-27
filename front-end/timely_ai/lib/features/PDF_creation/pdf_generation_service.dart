import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:timely_ai/models/CourseModel.dart';
import 'package:timely_ai/models/InstructorModel.dart';

class PdfGenerator {
  static Future<void> generateAndPreview({
    required List<Map<String, dynamic>> schedule,
    required List<Course> courses,
    required List<Instructor> instructors,
    String title = 'Timetable',
    String subtitle = '',
  }) async {
    final pdf = pw.Document();

    // Reorganize the data for a grid layout
    final Map<String, Map<String, Map<String, dynamic>>> gridData = {};
    final Set<String> days = {
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    };
    final Set<String> timeslots = {};

    // Extract unique timeslots and sort them
    for (var item in schedule) {
      timeslots.add(item['timeslot'] as String);
    }
    // Custom sort for timeslots to ensure AM/PM order
    final sortedTimeslots = timeslots.toList()
      ..sort((a, b) {
        // Simple parser for "08:00 AM" format
        int parseTime(String t) {
          final parts = t.split(' ');
          final timeParts = parts[0].split(':');
          int hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          final isPM = parts[1] == 'PM';
          if (isPM && hour != 12) hour += 12;
          if (!isPM && hour == 12) hour = 0;
          return hour * 60 + minute;
        }

        return parseTime(a).compareTo(parseTime(b));
      });

    // Populate grid data
    for (var item in schedule) {
      final day = item['day'] as String;
      final timeslot = item['timeslot'] as String;

      if (!gridData.containsKey(day)) {
        gridData[day] = {};
      }
      gridData[day]![timeslot] = item;
    }

    // Prepare Subject Details Data
    final uniqueCourseIds = schedule
        .map((e) => e['courseId'] as String)
        .toSet();
    final subjectDetails = <List<String>>[];

    for (final courseId in uniqueCourseIds) {
      final course = courses.firstWhere(
        (c) => c.id == courseId,
        orElse: () => Course(
          id: courseId,
          name: 'Unknown',
          lectureHours: 0,
          labHours: 0,
          qualifiedInstructors: [],
        ),
      );

      // Find instructor(s) for this course in this schedule
      final courseInstructors = schedule
          .where((item) => item['courseId'] == courseId)
          .map((item) => item['instructor'] as String)
          .toSet()
          .join(', ');

      subjectDetails.add([
        course.id,
        course.name,
        course.ltp,
        course.credits.toString(),
        courseInstructors,
      ]);
    }

    // Build the PDF document
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(
                'TIMELY.AI UNIVERSITY',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'DEPARTMENT OF COMPUTER SCIENCE & ENGINEERING',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Timetable for Academic Year 2025-26',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 10),
              if (subtitle.isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(5),
                  decoration: pw.BoxDecoration(border: pw.Border.all()),
                  child: pw.Text(
                    subtitle,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              pw.SizedBox(height: 10),

              // Timetable Grid (Custom Implementation for Merging)
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.black, width: 1),
                    left: pw.BorderSide(color: PdfColors.black, width: 1),
                  ),
                ),
                child: pw.Column(
                  children: [
                    // Header Row
                    pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2, // Day column width
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey300,
                              border: pw.Border(
                                right: pw.BorderSide(
                                  color: PdfColors.black,
                                  width: 1,
                                ),
                                bottom: pw.BorderSide(
                                  color: PdfColors.black,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: pw.Text(
                              'Day / Time',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ),
                        ...sortedTimeslots.map(
                          (time) => pw.Expanded(
                            flex: 3, // Time slot width
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(5),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey300,
                                border: pw.Border(
                                  right: pw.BorderSide(
                                    color: PdfColors.black,
                                    width: 1,
                                  ),
                                  bottom: pw.BorderSide(
                                    color: PdfColors.black,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: pw.Text(
                                time,
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Data Rows
                    ...days.map((day) {
                      // Prepare row cells with merging logic
                      final List<pw.Widget> rowCells = [];

                      // Add Day Cell
                      rowCells.add(
                        pw.Expanded(
                          flex: 2,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            alignment: pw.Alignment.center,
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                right: pw.BorderSide(
                                  color: PdfColors.black,
                                  width: 1,
                                ),
                                bottom: pw.BorderSide(
                                  color: PdfColors.black,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: pw.Text(
                              day,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );

                      int i = 0;
                      while (i < sortedTimeslots.length) {
                        final time = sortedTimeslots[i];
                        final item = gridData[day]?[time];

                        // Check for potential merge
                        int span = 1;
                        if (item != null && item['type'] == 'lab') {
                          // Look ahead for same course/group/lab type
                          for (int j = i + 1; j < sortedTimeslots.length; j++) {
                            final nextTime = sortedTimeslots[j];
                            final nextItem = gridData[day]?[nextTime];

                            if (nextItem != null &&
                                nextItem['courseId'] == item['courseId'] &&
                                nextItem['group'] == item['group'] &&
                                nextItem['type'] == 'lab') {
                              span++;
                            } else {
                              break;
                            }
                          }
                        }

                        // Build Cell
                        rowCells.add(
                          pw.Expanded(
                            flex: 3 * span,
                            child: pw.Container(
                              height: 50, // Fixed height for uniformity
                              padding: const pw.EdgeInsets.all(5),
                              alignment: pw.Alignment.center,
                              decoration: pw.BoxDecoration(
                                color: item != null && item['type'] == 'lab'
                                    ? PdfColors.purple50
                                    : (item != null ? PdfColors.blue50 : null),
                                border: pw.Border(
                                  right: pw.BorderSide(
                                    color: PdfColors.black,
                                    width: 1,
                                  ),
                                  bottom: pw.BorderSide(
                                    color: PdfColors.black,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: item != null
                                  ? pw.Column(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.center,
                                      children: [
                                        pw.Text(
                                          item['course'] ?? '',
                                          style: pw.TextStyle(
                                            fontWeight: pw.FontWeight.bold,
                                            fontSize: 10,
                                            color: PdfColors.black,
                                          ),
                                          textAlign: pw.TextAlign.center,
                                        ),
                                        pw.Text(
                                          item['room'] ?? '',
                                          style: const pw.TextStyle(
                                            fontSize: 8,
                                            color: PdfColors.grey800,
                                          ),
                                          textAlign: pw.TextAlign.center,
                                        ),
                                        pw.Text(
                                          '(${item['instructor']})',
                                          style: const pw.TextStyle(
                                            fontSize: 8,
                                            color: PdfColors.grey800,
                                          ),
                                          textAlign: pw.TextAlign.center,
                                        ),
                                        if (span >
                                            1) // Show duration for merged cells
                                          pw.Text(
                                            '${span} Hours',
                                            style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                              color: PdfColors.purple800,
                                            ),
                                          ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                        );

                        i += span;
                      }

                      return pw.Row(children: rowCells);
                    }),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Subject Details Table
              pw.Table.fromTextArray(
                headers: [
                  'Subject Code',
                  'Subject Title',
                  'L-T-P',
                  'Credits',
                  'Name of the Faculty Member',
                ],
                data: subjectDetails,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.orangeAccent,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 10),
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(4),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(3),
                },
              ),

              pw.Spacer(),
              pw.Footer(
                title: pw.Text(
                  'Generated by Timely.AI',
                  style: const pw.TextStyle(color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Use the 'printing' package to show a preview screen
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
