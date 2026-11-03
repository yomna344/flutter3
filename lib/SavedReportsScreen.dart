import 'package:flutter/material.dart';

import 'MealsAnalysisScreen.dart';
import 'MedicationReportScreen.dart';
import 'ActivityReportScreen.dart';
import 'HealthAdviceReportScreen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;


class SavedReportsScreen extends StatelessWidget {
  Future<void> exportReportPdf(
      BuildContext context,
      Map<String, dynamic> report,
      ) async {
    try {
      showMessage(context, 'جارٍ تجهيز ملف PDF...');

      final DateTime startDate = report['startDate'] as DateTime;
      final DateTime endDate = report['endDate'] as DateTime;
      final String title = report['title'] as String;

      final fontData = await rootBundle.load(
        'assets/fonts/arial.ttf',
      );

      final arabicFont = pw.Font.ttf(fontData);

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFont,
        ),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Center(
              child: pw.Text(
                'TinyGuide',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor(0.20, 0.66, 0.64),
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 25),
            pw.Text('اسم الطفل: $childName'),
            pw.SizedBox(height: 12),
            pw.Text('تاريخ البداية: ${formatDate(startDate)}'),
            pw.SizedBox(height: 12),
            pw.Text('تاريخ النهاية: ${formatDate(endDate)}'),
            pw.SizedBox(height: 12),
            pw.Text(
              'تاريخ إنشاء التقرير: '
                  '${formatDate(DateTime.now())}',
            ),
            pw.SizedBox(height: 25),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: const PdfColor(0.82, 0.88, 0.88),
                ),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Text(
                'هذا تقرير تجريبي لعرض واجهة TinyGuide. '
                    'بيانات التقرير غير محفوظة فعليًا في قاعدة البيانات، '
                    'ولا يتضمن هذا الملف إحصائيات صحية حقيقية.',
                style: const pw.TextStyle(
                  fontSize: 12,
                  lineSpacing: 5,
                ),
              ),
            ),
            pw.SizedBox(height: 25),
            pw.Center(
              child: pw.Text(
                'تم إنشاء هذا التقرير بواسطة TinyGuide',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        name: 'TinyGuide_Report.pdf',
        format: PdfPageFormat.a4,
        onLayout: (format) async => pdf.save(),
      );
    } catch (error) {
      if (!context.mounted) return;

      showMessage(context, 'تعذر إنشاء ملف PDF.');

      debugPrint('PDF export error: $error');
    }
  }
  final String childName;

  const SavedReportsScreen({
    super.key,
    required this.childName,
  });

  static const bool showDemoData = true;

  String formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  List<Map<String, dynamic>> get demoReports {
    final DateTime today = DateTime.now();
    final DateTime startDate = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 6));

    return [
      {
        'title': 'تحليل الوجبات',
        'type': 'meals',
        'icon': Icons.restaurant_rounded,
        'startDate': startDate,
        'endDate': today,
      },
      {
        'title': 'تقرير الأدوية',
        'type': 'medication',
        'icon': Icons.medication_rounded,
        'startDate': startDate,
        'endDate': today,
      },
      {
        'title': 'تقرير النشاط',
        'type': 'activity',
        'icon': Icons.directions_run_rounded,
        'startDate': startDate,
        'endDate': today,
      },
      {
        'title': 'النصائح الصحية',
        'type': 'advice',
        'icon': Icons.health_and_safety_outlined,
        'startDate': startDate,
        'endDate': today,
      },
    ];
  }

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void openReport(
      BuildContext context,
      Map<String, dynamic> report,
      ) {
    final DateTime startDate = report['startDate'] as DateTime;
    final DateTime endDate = report['endDate'] as DateTime;

    Widget screen;

    switch (report['type']) {
      case 'meals':
        screen = MealsAnalysisScreen(
          childName: childName,
          startDate: startDate,
          endDate: endDate,
        );
        break;

      case 'medication':
        screen = MedicationReportScreen(
          childName: childName,
          startDate: startDate,
          endDate: endDate,
        );
        break;


      case 'activity':
        screen = ActivityReportScreen(
          childName: childName,
          startDate: startDate,
          endDate: endDate,
        );
        break;

      case 'advice':
        screen = HealthAdviceReportScreen(
          childName: childName,
          startDate: startDate,
          endDate: endDate,
        );
        break;

      default:
        showMessage(context, 'نوع التقرير غير معروف.');
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = theme.primaryColor;
    final Color textColor = isDark
        ? Colors.white
        : const Color(0xff2C4A5A);
    final Color secondaryTextColor = isDark
        ? Colors.white.withOpacity(0.60)
        : const Color(0xff78909A);
    final Color cardColor = isDark
        ? const Color(0xff1D292D)
        : Colors.white;
    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : const Color(0xffE2EEEE);

    final List<Map<String, dynamic>> reports =
    showDemoData ? demoReports : [];

    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isTablet = constraints.maxWidth >= 600;
              final double horizontalPadding =
              constraints.maxWidth < 390
                  ? 14
                  : isTablet
                  ? 36
                  : 20;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 18,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 760,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        SizedBox(
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: Text(
                                  'التقارير المحفوظة',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isTablet ? 29 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              Align(
                                alignment:
                                AlignmentDirectional.centerStart,
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          'تقارير الطفل: $childName',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: secondaryTextColor,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Demo data notice
                        if (showDemoData)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(
                                isDark ? 0.12 : 0.08,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.science_outlined,
                                  color: primaryColor,
                                  size: 22,
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Text(
                                    'وضع تجريبي: العناصر التالية للعرض واختبار الواجهة فقط، وليست تقارير محفوظة فعليًا. ستأتي التقارير الحقيقية من Laravel لاحقًا.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.7,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        if (reports.isEmpty)
                          _buildEmptyState(
                            primaryColor: primaryColor,
                            cardColor: cardColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                          )
                        else
                          ...reports.map((report) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildReportCard(
                                context: context,
                                report: report,
                                primaryColor: primaryColor,
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                            );
                          }),

                        const SizedBox(height: 12),

                        Text(
                          'تنبيه: فتح العناصر التجريبية لا يعني أنها محفوظة في قاعدة البيانات. كما أن تنزيل PDF الفعلي يحتاج إلى تنفيذ وظيفة التصدير.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.7,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required Map<String, dynamic> report,
    required Color primaryColor,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final DateTime startDate = report['startDate'] as DateTime;
    final DateTime endDate = report['endDate'] as DateTime;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  report['icon'] as IconData,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report['title'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${formatDate(startDate)} - ${formatDate(endDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openReport(context, report),
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 18,
                  ),
                  label: const Text('فتح التقرير'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => exportReportPdf(context, report),
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 18,
                  ),
                  label: const Text('تنزيل PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required Color primaryColor,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 34,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 58,
            color: primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تقارير محفوظة',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر هنا التقارير التي يتم حفظها بعد ربط التطبيق بالخادم.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.7,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}