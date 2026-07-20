import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:seba/screens/report/student_report_data.dart';

/// مسؤولة عن حاجة واحدة بس: تحويل [StudentReportData] لملف PDF منسّق.
/// مفصولة عن جلب البيانات (ReportDataService) وعن الشاشة اللي بتستدعيها،
/// عشان لو حبيت تغيّر شكل التقرير أو تضيف قسم جديد، تعدّل هنا بس.
///
/// ⚠️ يحتاج خط عربي (assets/fonts/Cairo-Regular.ttf و Cairo-Bold.ttf)
/// مضاف في pubspec.yaml تحت fonts، وإلا الحروف العربية هتظهر مربعات
/// فارغة في الـ PDF. راجع التعليمات في نهاية الرسالة.
class StudentReportPdfBuilder {
  static const _dateFormat = 'dd/MM/yyyy';

  static Future<pw.Document> build(StudentReportData data) async {
    final regularFontData = await rootBundle.load(
      'assets/fonts/Cairo/static/Cairo-Regular.ttf',
    );
    final boldFontData = await rootBundle.load(
      'assets/fonts/Cairo/static/Cairo-Bold.ttf',
    );

    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
    );

    doc.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildPageHeader(data, boldFont),
        footer: (context) => _buildPageFooter(context, regularFont),
        build: (context) => [
          _buildStudentInfoCard(data, regularFont, boldFont),
          pw.SizedBox(height: 16),
          _buildOverallSummary(data, regularFont, boldFont),
          pw.SizedBox(height: 20),
          for (final section in data.groupSections) ...[
            _buildGroupSection(section, regularFont, boldFont),
            pw.SizedBox(height: 20),
          ],
        ],
      ),
    );

    return doc;
  }

  // ================== الترويسة والتذييل ==================
  static pw.Widget _buildPageHeader(StudentReportData data, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'تقرير الطالب',
              style: pw.TextStyle(font: boldFont, fontSize: 20),
            ),
            pw.Text(
              DateFormat(_dateFormat).format(data.generatedAt),
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Divider(thickness: 1),
      ],
    );
  }

  static pw.Widget _buildPageFooter(pw.Context context, pw.Font font) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.Text(
          'صفحة ${context.pageNumber} من ${context.pagesCount}',
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  // ================== بيانات الطالب ==================
  static pw.Widget _buildStudentInfoCard(
    StudentReportData data,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final student = data.student;
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            student.name ?? '',
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 6),
          _infoRow(font, 'ولي الأمر', student.parentName ?? '—'),
          _infoRow(font, 'صلة القرابة', student.parentRelation ?? '—'),
          _infoRow(font, 'رقم الهاتف', student.phone ?? '—'),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(pw.Font font, String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: pw.TextStyle(font: font, fontSize: 11)),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: 11)),
        ],
      ),
    );
  }

  // ================== الملخص الإجمالي (كل المجموعات مع بعض) ==================
  static pw.Widget _buildOverallSummary(
    StudentReportData data,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Row(
      children: [
        _summaryBox(
          font,
          boldFont,
          'نسبة الحضور الكلية',
          '${(data.overallAttendanceRate * 100).toStringAsFixed(0)}%',
        ),
        pw.SizedBox(width: 8),
        _summaryBox(font, boldFont, 'أيام الحضور', '${data.totalPresent}'),
        pw.SizedBox(width: 8),
        _summaryBox(font, boldFont, 'أيام الغياب', '${data.totalAbsent}'),
        pw.SizedBox(width: 8),
        _summaryBox(
          font,
          boldFont,
          'متوسط الدرجات',
          '${data.overallAverageExamPercentage.toStringAsFixed(0)}%',
        ),
      ],
    );
  }

  static pw.Widget _summaryBox(
    pw.Font font,
    pw.Font boldFont,
    String label,
    String value,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          children: [
            pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 15)),
            pw.SizedBox(height: 4),
            pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                color: PdfColors.grey700,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ================== قسم كل مجموعة (مادة) ==================
  static pw.Widget _buildGroupSection(
    GroupReportSection section,
    pw.Font font,
    pw.Font boldFont,
  ) {
    final group = section.group;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          color: PdfColors.green100,
          width: double.infinity,
          child: pw.Text(
            '${group.subject ?? ''} - ${group.grade ?? ''}',
            style: pw.TextStyle(font: boldFont, fontSize: 13),
          ),
        ),
        pw.SizedBox(height: 8),

        pw.Text(
          'نسبة الحضور: ${(section.attendanceRate * 100).toStringAsFixed(0)}% '
          '(${section.presentCount} حضور، ${section.absentCount} غياب من ${section.totalAttendance})'
          '${section.totalExams > 0 ? ' | متوسط الدرجات: ${section.averageExamPercentage.toStringAsFixed(0)}%' : ''}',
          style: pw.TextStyle(
            font: font,
            fontSize: 10,
            color: PdfColors.grey800,
          ),
        ),
        pw.SizedBox(height: 10),

        if (section.attendanceRecords.isNotEmpty) ...[
          pw.Text(
            'سجل الحضور والغياب',
            style: pw.TextStyle(font: boldFont, fontSize: 11),
          ),
          pw.SizedBox(height: 4),
          _buildAttendanceTable(section.attendanceRecords, font, boldFont),
          pw.SizedBox(height: 10),
        ],

        if (section.examRecords.isNotEmpty) ...[
          pw.Text(
            'سجل الامتحانات',
            style: pw.TextStyle(font: boldFont, fontSize: 11),
          ),
          pw.SizedBox(height: 4),
          _buildExamsTable(section.examRecords, font, boldFont),
        ],
      ],
    );
  }

  static pw.Widget _buildAttendanceTable(
    List<AttendanceRecord> records,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignment: pw.Alignment.center,
      headers: ['التاريخ', 'الحالة'],
      data: records
          .map(
            (r) => [
              DateFormat(_dateFormat).format(r.date),
              r.isPresent ? 'حاضر' : 'غائب',
            ],
          )
          .toList(),
    );
  }

  static pw.Widget _buildExamsTable(
    List<ExamRecord> records,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignment: pw.Alignment.center,
      headers: ['التاريخ', 'الاختبار', 'الحالة', 'الدرجة', 'النسبة'],
      data: records
          .map(
            (r) => [
              DateFormat(_dateFormat).format(r.date),
              r.examName,
              r.isPresent ? 'حاضر' : 'غائب',
              '${r.currentDegree.toStringAsFixed(1)} / ${r.maxDegree.toStringAsFixed(1)}',
              '${r.percentage.toStringAsFixed(0)}%',
            ],
          )
          .toList(),
    );
  }
}
