import 'package:flutter/material.dart';
import 'MealsAnalysisScreen.dart';
import 'MedicationReportScreen.dart';
import 'ActivityReportScreen.dart';
import 'ComprehensiveHealthReportScreen.dart';
import 'MedicalExamsReportScreen.dart';
import 'GlucoseReportScreen.dart';

class ReportGenerationScreen extends StatefulWidget {
  final String childName;

  const ReportGenerationScreen({
    super.key,
    required this.childName,
  });

  @override
  State<ReportGenerationScreen> createState() =>
      _ReportGenerationScreenState();
}

class _ReportGenerationScreenState
    extends State<ReportGenerationScreen> {
  String? selectedReportType;
  DateTime? startDate;
  DateTime? endDate;

  bool isGenerating = false;

  String? reportTypeError;
  String? startDateError;
  String? endDateError;

  // =========================
  // Report Menu
  // =========================

  final MenuController _menuController = MenuController();

  final ScrollController _reportScrollController =
  ScrollController();

  bool _showMoreReportsArrow = true;

  final List<String> reportTypes = const [
    'التقرير الصحي الشامل',
    'تقرير النشاط',
    'تقرير الفحوصات الطبية',
  ];

  @override
  void initState() {
    super.initState();

    _reportScrollController.addListener(
      _updateReportMenuArrow,
    );
  }

  // =========================
  // Update Scroll Arrow
  // =========================

  void _updateReportMenuArrow() {
    if (!_reportScrollController.hasClients) return;

    final bool hasMoreBelow =
        _reportScrollController.position.extentAfter > 2;

    if (_showMoreReportsArrow != hasMoreBelow) {
      if (!mounted) return;

      setState(() {
        _showMoreReportsArrow = hasMoreBelow;
      });
    }
  }

  // =========================
  // Date Formatter
  // =========================

  String formatDate(DateTime? date) {
    if (date == null) return '';

    final String day =
    date.day.toString().padLeft(2, '0');

    final String month =
    date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // =========================
  // Start Date
  // =========================

  Future<void> selectStartDate() async {
    final DateTime now = DateTime.now();

    final DateTime today =
    DateTime(now.year, now.month, now.day);

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: startDate ?? today,
      firstDate: DateTime(2020),
      lastDate: today,
      helpText: 'اختاري تاريخ البداية',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      startDate = selectedDate;
      startDateError = null;

      if (endDate != null &&
          endDate!.isBefore(selectedDate)) {
        endDate = null;
        endDateError = 'اختاري تاريخ النهاية من جديد';
      }
    });
  }

  // =========================
  // End Date
  // =========================

  Future<void> selectEndDate() async {
    if (startDate == null) {
      setState(() {
        startDateError = 'اختاري تاريخ البداية أولاً';
      });

      return;
    }

    final DateTime now = DateTime.now();

    final DateTime today =
    DateTime(now.year, now.month, now.day);

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: endDate ?? today,
      firstDate: startDate!,
      lastDate: today,
      helpText: 'اختاري تاريخ النهاية',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      endDate = selectedDate;
      endDateError = null;
    });
  }

  // =========================
  // Message
  // =========================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // =========================
  // Validate Inputs
  // =========================

  bool _validateInputs() {
    bool hasError = false;

    setState(() {
      reportTypeError = null;
      startDateError = null;
      endDateError = null;

      if (selectedReportType == null) {
        reportTypeError = 'يجب اختيار نوع التقرير';
        hasError = true;
      }

      if (startDate == null) {
        startDateError = 'يجب اختيار تاريخ البداية';
        hasError = true;
      }

      if (endDate == null) {
        endDateError = 'يجب اختيار تاريخ النهاية';
        hasError = true;
      }

      if (startDate != null &&
          endDate != null &&
          endDate!.isBefore(startDate!)) {
        endDateError =
        'تاريخ النهاية يجب أن يكون مساويًا لتاريخ البداية أو بعده';

        hasError = true;
      }
    });

    return !hasError;
  }

  // =========================
  // Open Selected Report
  // =========================

  Future<void> generateReport() async {
    FocusScope.of(context).unfocus();

    if (isGenerating) return;

    if (!_validateInputs()) return;

    final DateTime reportStartDate = startDate!;
    final DateTime reportEndDate = endDate!;
    final String reportType = selectedReportType!;

    Widget reportScreen;

    switch (reportType) {
      case 'التقرير الصحي الشامل':
        reportScreen = ComprehensiveHealthReportScreen(
          childName: widget.childName,
          startDate: reportStartDate,
          endDate: reportEndDate,
        );
        break;


      case 'تقرير النشاط':
        reportScreen = ActivityReportScreen(
          childName: widget.childName,
          startDate: reportStartDate,
          endDate: reportEndDate,
        );
        break;


      case 'تقرير الفحوصات الطبية':
        reportScreen = MedicalExamsReportScreen(
          childName: widget.childName,
          startDate: reportStartDate,
          endDate: reportEndDate,
        );
        break;

      default:
        _showMessage('نوع التقرير غير معروف.');
        return;
    }

    setState(() {
      isGenerating = true;
    });

    await Future<void>.delayed(Duration.zero);

    if (!mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => reportScreen,
        ),
      );
    } catch (_) {
      if (mounted) {
        _showMessage(
          'تعذر فتح التقرير. حاولي مرة أخرى.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isGenerating = false;
        });
      }
    }
  }

  // =========================
  // Dispose
  // =========================

  @override
  void dispose() {
    _reportScrollController.dispose();
    super.dispose();
  }

  // =========================
  // Build
  // =========================

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isDark =
        theme.brightness == Brightness.dark;

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
        : const Color(0xffD7E7E7);

    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;

              final bool isVerySmall = width < 390;
              final bool isTablet = width >= 600;

              final double horizontalPadding = isVerySmall
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
                      maxWidth: 700,
                    ),
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
                                  'إنشاء تقرير',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isTablet ? 31 : 27,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              Align(
                                alignment:
                                AlignmentDirectional.centerStart,
                                child: IconButton(
                                  onPressed: isGenerating
                                      ? null
                                      : () => Navigator.pop(context),
                                  padding: EdgeInsets.zero,
                                  constraints:
                                  const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                  splashRadius: 22,
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
                          'اختاري نوع التقرير والفترة المناسبة للطفل.',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // =========================
                        // Selected Child
                        // =========================

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius:
                            BorderRadius.circular(18),
                            border: Border.all(
                              color: borderColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: primaryColor
                                      .withOpacity(0.12),
                                  borderRadius:
                                  BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.child_care_rounded,
                                  color: primaryColor,
                                  size: 27,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    Text(
                                      widget.childName,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // =========================
                        // Report Type
                        // =========================

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius:
                            BorderRadius.circular(20),
                            border: Border.all(
                              color: borderColor,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'نوع التقرير',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),

                              const SizedBox(height: 12),

                              // =========================
                              // Scrollable Report Menu
                              // =========================

                              LayoutBuilder(
                                builder:
                                    (context, menuConstraints) {
                                  final double fieldWidth =
                                      menuConstraints.maxWidth;

                                  final double menuWidth =
                                  fieldWidth < 235
                                      ? fieldWidth
                                      : 235;

                                  return MenuAnchor(
                                    controller: _menuController,

                                    alignmentOffset: Offset(
                                      fieldWidth - menuWidth,
                                      4,
                                    ),

                                    style: MenuStyle(
                                      backgroundColor:
                                      WidgetStatePropertyAll(
                                        cardColor,
                                      ),
                                      elevation:
                                      const WidgetStatePropertyAll(6),
                                      padding:
                                      const WidgetStatePropertyAll(
                                        EdgeInsets.zero,
                                      ),
                                      shape:
                                      WidgetStatePropertyAll(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(14),
                                        ),
                                      ),
                                    ),

                                    menuChildren: [
                                      SizedBox(
                                        width: menuWidth,
                                        height: reportTypes.length * 48.0 + 8,
                                        child: Stack(
                                          children: [
                                            Scrollbar(
                                              controller:
                                              _reportScrollController,
                                              thumbVisibility: true,
                                              trackVisibility: true,
                                              interactive: true,

                                              child: ListView.builder(
                                                controller:
                                                _reportScrollController,
                                                physics:
                                                const ClampingScrollPhysics(),
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: 4,
                                                ),
                                                itemCount:
                                                reportTypes.length,

                                                itemBuilder:
                                                    (context, index) {
                                                  final String type =
                                                  reportTypes[index];

                                                  final bool isSelected =
                                                      selectedReportType ==
                                                          type;

                                                  return InkWell(
                                                    onTap: () {
                                                      _menuController.close();

                                                      setState(() {
                                                        selectedReportType =
                                                            type;
                                                        reportTypeError =
                                                        null;
                                                      });
                                                    },
                                                    child: Container(
                                                      height: 48,
                                                      padding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 14,
                                                      ),
                                                      alignment:
                                                      Alignment.centerRight,
                                                      child: Text(
                                                        type,
                                                        textAlign:
                                                        TextAlign.right,
                                                        textDirection:
                                                        TextDirection.rtl,
                                                        style: TextStyle(
                                                          color: isSelected
                                                              ? primaryColor
                                                              : textColor,
                                                          fontSize: 14,
                                                          fontWeight:
                                                          isSelected
                                                              ? FontWeight
                                                              .w600
                                                              : FontWeight
                                                              .normal,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),

                                            // Scroll indicator arrow

                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
                                              child: IgnorePointer(
                                                child: Container(
                                                  height: 30,
                                                  alignment:
                                                  Alignment.bottomLeft,
                                                  padding:
                                                  const EdgeInsets.only(
                                                    left: 12,
                                                    bottom: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                    LinearGradient(
                                                      begin:
                                                      Alignment.topCenter,
                                                      end:
                                                      Alignment.bottomCenter,
                                                      colors: [
                                                        cardColor
                                                            .withOpacity(0),
                                                        cardColor,
                                                      ],
                                                    ),
                                                  ),
                                                  child:

                                                  const SizedBox
                                                      .shrink(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    builder: (
                                        context,
                                        controller,
                                        child,
                                        ) {
                                      return GestureDetector(
                                        behavior:
                                        HitTestBehavior.opaque,

                                        onTap: isGenerating
                                            ? null
                                            : () {
                                          if (controller.isOpen) {
                                            controller.close();
                                          } else {
                                            controller.open();

                                            WidgetsBinding.instance
                                                .addPostFrameCallback(
                                                  (_) {
                                                if (mounted) {
                                                  _updateReportMenuArrow();
                                                }
                                              },
                                            );
                                          }
                                        },

                                        child: InputDecorator(
                                          decoration: _inputDecoration(
                                            context,
                                            icon: Icons
                                                .description_outlined,
                                            errorText: reportTypeError,
                                            cardColor: cardColor,
                                            borderColor: borderColor,
                                            primaryColor: primaryColor,
                                            secondaryTextColor:
                                            secondaryTextColor,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  selectedReportType ??
                                                      'اختاري نوع التقرير',
                                                  textAlign: TextAlign.right,
                                                  textDirection:
                                                  TextDirection.rtl,
                                                  style: TextStyle(
                                                    color:
                                                    selectedReportType ==
                                                        null
                                                        ? secondaryTextColor
                                                        : textColor,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                color: textColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // =========================
                        // Report Period
                        // =========================

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius:
                            BorderRadius.circular(20),
                            border: Border.all(
                              color: borderColor,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الفترة الزمنية',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'حددي تاريخ البداية والنهاية لعرض التقرير خلال الفترة المطلوبة.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.6,
                                  color: secondaryTextColor,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Start Date

                              InkWell(
                                onTap: isGenerating
                                    ? null
                                    : selectStartDate,
                                borderRadius:
                                BorderRadius.circular(14),
                                child: InputDecorator(
                                  decoration: _inputDecoration(
                                    context,
                                    icon: Icons
                                        .calendar_month_outlined,
                                    errorText: startDateError,
                                    cardColor: cardColor,
                                    borderColor: borderColor,
                                    primaryColor: primaryColor,
                                    secondaryTextColor:
                                    secondaryTextColor,
                                  ),
                                  child: Text(
                                    startDate == null
                                        ? 'من تاريخ'
                                        : formatDate(startDate),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: startDate == null
                                          ? secondaryTextColor
                                          : textColor,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // End Date

                              InkWell(
                                onTap: isGenerating
                                    ? null
                                    : selectEndDate,
                                borderRadius:
                                BorderRadius.circular(14),
                                child: InputDecorator(
                                  decoration: _inputDecoration(
                                    context,
                                    icon: Icons
                                        .event_available_outlined,
                                    errorText: endDateError,
                                    cardColor: cardColor,
                                    borderColor: borderColor,
                                    primaryColor: primaryColor,
                                    secondaryTextColor:
                                    secondaryTextColor,
                                  ),
                                  child: Text(
                                    endDate == null
                                        ? 'إلى تاريخ'
                                        : formatDate(endDate),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: endDate == null
                                          ? secondaryTextColor
                                          : textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // =========================
                        // Information Note
                        // =========================

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(
                              isDark ? 0.10 : 0.08,
                            ),
                            borderRadius:
                            BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: primaryColor,
                                size: 21,
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  'هذه المرحلة تجهز واجهات التقارير فقط. البيانات الحقيقية والحفظ في قاعدة البيانات سيتم ربطهما عبر Laravel لاحقًا.',
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
                        // Generate Button
                        // =========================

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: isGenerating
                                ? null
                                : generateReport,
                            icon: isGenerating
                                ? const SizedBox(
                              width: 21,
                              height: 21,
                              child:
                              CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                                : const Icon(
                              Icons.bar_chart_rounded,
                            ),
                            label: Text(
                              isGenerating
                                  ? 'جاري فتح التقرير...'
                                  : 'إنشاء التقرير',
                              style: const TextStyle(
                                fontSize: 16,
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
  // Input Decoration
  // =========================

  InputDecoration _inputDecoration(
      BuildContext context, {
        required IconData icon,
        required Color cardColor,
        required Color borderColor,
        required Color primaryColor,
        required Color secondaryTextColor,
        String? errorText,
      }) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      prefixIcon: Icon(
        icon,
        color: primaryColor,
      ),
      filled: true,
      fillColor: cardColor,
      errorText: errorText,
      errorStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.red,
      ),
      hintStyle: TextStyle(
        color: secondaryTextColor,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: borderColor,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : borderColor,
        ),
      ),
    );
  }
}