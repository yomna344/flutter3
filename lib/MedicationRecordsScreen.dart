import 'package:flutter/material.dart';

class MedicationRecordsScreen extends StatefulWidget {
  const MedicationRecordsScreen({super.key});

  @override
  State<MedicationRecordsScreen> createState() =>
      _MedicationRecordsScreenState();
}

class _MedicationRecordsScreenState
    extends State<MedicationRecordsScreen> {

  final List<MedicationRecord> allRecords = [
    MedicationRecord(
      medicationName: 'الدواء الأول',
      dose: '5 مل',
      date: DateTime(2026, 9, 1),
      time: '08:00 ص',
      note: 'بعد الإفطار',
    ),
    MedicationRecord(
      medicationName: 'الدواء الثاني',
      dose: 'قرص واحد',
      date: DateTime(2026, 8, 31),
      time: '02:00 م',
      note: 'بعد الغداء',
    ),
    MedicationRecord(
      medicationName: 'الدواء الأول',
      dose: '5 مل',
      date: DateTime(2026, 8, 30),
      time: '08:00 م',
      note: 'بعد العشاء',
    ),
  ];

  String formatDate(DateTime date) {
    final String day =
    date.day.toString().padLeft(2, '0');

    final String month =
    date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> confirmDelete(
      MedicationRecord record,
      ) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final ThemeData theme = Theme.of(dialogContext);

        final bool isDark =
            theme.brightness == Brightness.dark;

        final Color textColor = isDark
            ? Colors.white
            : const Color(0xff2C4A5A);

        final Color cardColor = isDark
            ? const Color(0xff1D292D)
            : Colors.white;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'حذف السجل',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'هل أنت متأكد من حذف سجل هذا الدواء؟',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: textColor.withOpacity(0.70),
              ),
            ),
            actionsPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: Text(
                  'إلغاء',
                  style: TextStyle(
                    color: textColor.withOpacity(0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'نعم، حذف',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete == true && mounted) {
      deleteRecord(record);
    }
  }

  void deleteRecord(MedicationRecord record) {
    setState(() {
      allRecords.remove(record);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم حذف السجل بنجاح',
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color textColor = isDark
        ? Colors.white
        : const Color(0xff2C4A5A);

    final Color secondaryTextColor = isDark
        ? Colors.white.withOpacity(0.60)
        : const Color(0xff78909A);

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
                      maxWidth: 760,
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
                                  'سجلات الأدوية',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isTablet ? 31 : 27,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),

                              // سهم الرجوع
                              Align(
                                alignment:
                                AlignmentDirectional.centerStart,
                                child: IconButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                  splashRadius: 22,
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 22,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                          child: Text(
                            'عرض سجلات الأدوية التي تم تسجيلها سابقًا',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // =========================
                        // السجلات
                        // =========================

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'السجلات',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),

                            Text(
                              '${allRecords.length} سجل',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: secondaryTextColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (allRecords.isEmpty)
                          _emptyState(context)
                        else
                          ...allRecords.asMap().entries.map(
                                (entry) {
                              final int index = entry.key;
                              final MedicationRecord record =
                                  entry.value;

                              return Column(
                                children: [
                                  _medicationRecordCard(
                                    context,
                                    record: record,
                                  ),

                                  if (index != allRecords.length - 1)
                                    const SizedBox(height: 12),
                                ],
                              );
                            },
                          ),

                        const SizedBox(height: 24),
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
  // Medication Record Card
  // =========================

  Widget _medicationRecordCard(
      BuildContext context, {
        required MedicationRecord record,
      }) {
    final ThemeData theme = Theme.of(context);

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color primaryColor = theme.primaryColor;

    final Color textColor = isDark
        ? Colors.white
        : const Color(0xff2C4A5A);

    final Color cardColor = isDark
        ? const Color(0xff1D292D)
        : Colors.white;

    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : const Color(0xffE2EEEE);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xff7058A5).withOpacity(0.18)
                  : const Color(0xffF2EDFA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.medication_rounded,
              color: Color(0xff7058A5),
              size: 27,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  record.medicationName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'الجرعة: ${record.dose}',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: textColor.withOpacity(0.65),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  record.note,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.55),
                  ),
                ),

                const SizedBox(height: 7),

                Wrap(
                  spacing: 12,
                  runSpacing: 5,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: primaryColor,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          formatDate(record.date),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textColor.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: primaryColor,
                        ),

                        const SizedBox(width: 4),

                        Text(
                          record.time,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: textColor.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Material(
            color: Colors.red.withOpacity(
              isDark ? 0.12 : 0.08,
            ),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => confirmDelete(record),
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // Empty State
  // =========================

  Widget _emptyState(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color primaryColor = theme.primaryColor;

    final Color textColor = isDark
        ? Colors.white
        : const Color(0xff2C4A5A);

    final Color cardColor = isDark
        ? const Color(0xff1D292D)
        : Colors.white;

    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : const Color(0xffE2EEEE);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 32,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 38,
            color: primaryColor,
          ),

          const SizedBox(height: 12),

          Text(
            'لا توجد سجلات أدوية',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class MedicationRecord {
  final String medicationName;
  final String dose;
  final DateTime date;
  final String time;
  final String note;

  MedicationRecord({
    required this.medicationName,
    required this.dose,
    required this.date,
    required this.time,
    required this.note,
  });
}