import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class ComprehensiveHealthReportScreen extends StatelessWidget {
  final String childName;
  final DateTime startDate;
  final DateTime endDate;

  const ComprehensiveHealthReportScreen({
    super.key,
    required this.childName,
    required this.startDate,
    required this.endDate,
  });

  // =========================
  // Date Formatter
  // =========================

  String formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // =========================
  // Report Period Type
  // =========================

  String getReportPeriodType() {
    final DateTime start = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final DateTime end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    final int totalDays = end.difference(start).inDays + 1;

    // =====================
    // Daily Report
    // =====================

    if (totalDays == 1) {
      return 'تقرير يومي';
    }

    // =====================
    // Weekly Report
    // =====================

    if (totalDays == 7) {
      return 'تقرير أسبوعي';
    }

    // =====================
    // Monthly Report
    // =====================

    // مثال:
    // 01/10/2026 إلى 01/11/2026

    final DateTime nextMonth = DateTime(
      start.year,
      start.month + 1,
      start.day,
    );

    if (end.year == nextMonth.year &&
        end.month == nextMonth.month &&
        end.day == nextMonth.day) {
      return 'تقرير شهري';
    }

    // =====================
    // Multiple Weeks
    // =====================

    if (totalDays > 7 && totalDays % 7 == 0) {
      final int weeks = totalDays ~/ 7;

      if (weeks == 2) {
        return 'تقرير لمدة أسبوعين';
      }

      return 'تقرير لمدة $weeks أسابيع';
    }

    // =====================
    // Custom Period
    // =====================

    if (totalDays == 2) {
      return 'تقرير لمدة يومين';
    }

    return 'تقرير لمدة $totalDays يوم';
  }

  // =========================
  // Messages
  // =========================

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;

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

  // =========================
  // Report Sections
  // =========================

  static const List<Map<String, String>> reportSections = [
    {
      'title': 'قراءات السكر',
      'description':
      'ستظهر قراءات السكر المسجلة ومتوسط القراءات وأعلى وأقل قراءة خلال الفترة المحددة.',
    },
    {
      'title': 'الوجبات والتغذية',
      'description':
      'ستظهر الوجبات المسجلة ومعلومات الكربوهيدرات المتاحة خلال الفترة المحددة.',
    },
    {
      'title': 'الأدوية',
      'description':
      'ستظهر أسماء الأدوية والجرعات والمواعيد المسجلة للطفل خلال الفترة المحددة.',
    },
    {
      'title': 'النشاط البدني',
      'description':
      'ستظهر الأنشطة المسجلة ومدتها ومستوى شدتها خلال الفترة المحددة.',
    },
    {
      'title': 'الفحوصات الطبية',
      'description':
      'ستظهر أسماء الفحوصات الطبية وتواريخها ونتائجها المسجلة خلال الفترة المحددة.',
    },
  ];

  // =========================
  // Section Icons
  // =========================

  IconData _sectionIcon(String title) {
    switch (title) {
      case 'قراءات السكر':
        return Icons.bloodtype_outlined;

      case 'الوجبات والتغذية':
        return Icons.restaurant_outlined;

      case 'الأدوية':
        return Icons.medication_outlined;

      case 'النشاط البدني':
        return Icons.directions_run_rounded;

      case 'الفحوصات الطبية':
        return Icons.medical_information_outlined;

      case 'النصائح الصحية':
        return Icons.health_and_safety_outlined;

      default:
        return Icons.description_outlined;
    }
  }

  // =========================
  // Export Comprehensive PDF
  // =========================

  Future<void> _exportPdf(BuildContext context) async {
    try {
      final fontData =
      await rootBundle.load('assets/fonts/arial.ttf');

      final arabicFont = pw.Font.ttf(fontData);

      final pdf = pw.Document();

      final String periodType = getReportPeriodType();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicFont,
          ),
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context pdfContext) {
            return [
              // =====================
              // PDF Header
              // =====================

              pw.Center(
                child: pw.Text(
                  'التقرير الصحي الشامل',
                  style: pw.TextStyle(
                    font: arabicFont,
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 24),

              // =====================
              // Child Information
              // =====================

              pw.Text(
                'اسم الطفل: $childName',
              ),

              pw.SizedBox(height: 10),

              // =====================
              // Report Period Type
              // =====================

              pw.Text(
                'نوع التقرير: $periodType',
              ),

              pw.SizedBox(height: 10),

              pw.Text(
                'فترة التقرير: '
                    '${formatDate(startDate)} - '
                    '${formatDate(endDate)}',
              ),

              pw.SizedBox(height: 24),

              // =====================
              // Health Summary
              // =====================

              pw.Text(
                'الملخص الصحي العام',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 12),

              pw.Text(
                'لا توجد بيانات صحية متاحة لإعداد الملخص الشامل حاليًا.',
              ),

              pw.SizedBox(height: 20),

              // =====================
              // Health Sections
              // =====================

              ...reportSections.expand((section) {
                return [
                  pw.Text(
                    section['title']!,
                    style: pw.TextStyle(
                      font: arabicFont,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.SizedBox(height: 8),

                  pw.Text(
                    section['description']!,
                  ),

                  pw.SizedBox(height: 18),
                ];
              }),

              pw.SizedBox(height: 12),

              // =====================
              // Medical Note
              // =====================

              pw.Text(
                'ملاحظة طبية',
                style: pw.TextStyle(
                  font: arabicFont,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 10),

              pw.Text(
                'هذا التقرير مخصص لتنظيم المعلومات الصحية ومتابعتها '
                    'ومشاركتها مع الطبيب. لا يُعد تشخيصًا طبيًا ولا يغني '
                    'عن مراجعة الطبيب المختص. لا ينبغي تعديل العلاج '
                    'أو جرعات الأدوية بناءً على هذا التقرير وحده.',
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        name: 'TinyGuide_Comprehensive_Health_Report.pdf',
        format: PdfPageFormat.a4,
        onLayout: (format) async => pdf.save(),
      );
    } catch (e) {
      if (!context.mounted) return;

      _showMessage(
        context,
        'تعذر إنشاء ملف PDF. تأكدي من وجود الخط وإعداداته.',
      );
    }
  }

  // =========================
  // Main Interface
  // =========================

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color primaryColor = theme.primaryColor;

    final Color textColor =
    isDark ? Colors.white : const Color(0xff2C4A5A);

    final Color secondaryTextColor = isDark
        ? Colors.white.withOpacity(0.60)
        : const Color(0xff78909A);

    final Color cardColor =
    isDark ? const Color(0xff1D292D) : Colors.white;

    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : const Color(0xffE2EEEE);

    final String periodType = getReportPeriodType();

    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isTablet =
                  constraints.maxWidth >= 600;

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
                    constraints:
                    const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        // =========================
                        // Header
                        // =========================

                        SizedBox(
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: Text(
                                  'التقرير الصحي الشامل',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isTablet ? 31 : 25,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),

                              Align(
                                alignment:
                                AlignmentDirectional.centerStart,
                                child: IconButton(
                                  onPressed: () =>
                                      Navigator.pop(context),
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: textColor,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'متابعة الحالة الصحية للطفل $childName خلال الفترة المحددة',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // =========================
                        // Report Period
                        // =========================

                        _card(
                          cardColor,
                          borderColor,
                          Row(
                            children: [
                              _icon(
                                Icons.date_range_rounded,
                                primaryColor,
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'فترة التقرير',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    // نوع التقرير
                                    Text(
                                      periodType,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    // التاريخ
                                    Text(
                                      '${formatDate(startDate)} - '
                                          '${formatDate(endDate)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // =========================
                        // General Health Summary
                        // =========================

                        Text(
                          'الملخص الصحي العام',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // =========================
                        // Empty State
                        // =========================

                        _card(
                          cardColor,
                          borderColor,
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              children: [
                                Icon(
                                  Icons.health_and_safety_outlined,
                                  size: 52,
                                  color: primaryColor,
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  'لا توجد بيانات صحية للعرض',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  'سيظهر الملخص الصحي الشامل بعد ربط بيانات الطفل المسجلة خلال الفترة المحددة.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.7,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // =========================
                        // Health Details
                        // =========================

                        Text(
                          'تفاصيل التقرير الصحي',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // =========================
                        // Health Sections
                        // =========================

                        ...reportSections.map((section) {
                          return Padding(
                            padding:
                            const EdgeInsets.only(bottom: 12),
                            child: _detailCard(
                              icon: _sectionIcon(
                                section['title']!,
                              ),
                              title: section['title']!,
                              description:
                              section['description']!,
                              primaryColor: primaryColor,
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              secondaryTextColor:
                              secondaryTextColor,
                            ),
                          );
                        }),

                        const SizedBox(height: 12),

                        // =========================
                        // Medical Note
                        // =========================

                        _card(
                          cardColor,
                          borderColor,
                          Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: primaryColor,
                                size: 22,
                              ),

                              const SizedBox(width: 9),

                              Expanded(
                                child: Text(
                                  'هذا التقرير مخصص لتنظيم المعلومات الصحية ومتابعتها ومشاركتها مع الطبيب. لا يُعد تشخيصًا طبيًا ولا يغني عن مراجعة الطبيب المختص. لا ينبغي تعديل العلاج أو جرعات الأدوية بناءً على هذا التقرير وحده.',
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

                        const SizedBox(height: 24),

                        // =========================
                        // Save Report
                        // =========================

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showMessage(
                                context,
                                'حفظ التقرير غير متاح حاليًا. سيتفعّل بعد ربط Laravel API.',
                              );
                            },
                            icon:
                            const Icon(Icons.save_outlined),
                            label: const Text(
                              'حفظ التقرير',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // =========================
                        // Download PDF
                        // =========================

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _exportPdf(context),
                            icon: const Icon(
                              Icons.picture_as_pdf_outlined,
                            ),
                            label: const Text(
                              'تنزيل PDF',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
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

  // =========================
  // Card
  // =========================

  Widget _card(
      Color cardColor,
      Color borderColor,
      Widget child,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }

  // =========================
  // Icon
  // =========================

  Widget _icon(
      IconData icon,
      Color primaryColor,
      ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: primaryColor,
        size: 25,
      ),
    );
  }

  // =========================
  // Detail Card
  // =========================

  Widget _detailCard({
    required IconData icon,
    required String title,
    required String description,
    required Color primaryColor,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return _card(
      cardColor,
      borderColor,
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _icon(icon, primaryColor),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.7,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}