import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicalExamRecordsScreen extends StatefulWidget {
  const MedicalExamRecordsScreen({super.key});

  @override
  State<MedicalExamRecordsScreen> createState() =>
      _MedicalExamRecordsScreenState();
}

class _MedicalExamRecordsScreenState
    extends State<MedicalExamRecordsScreen> {
  static const String recordsStorageKey =
      'tinyguide_medical_exam_records';

  bool isLoading = true;
  bool isDeleting = false;

  List<MedicalExamRecord> allRecords = [];

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  // =========================
  // Load Records
  // =========================

  Future<void> loadRecords() async {
    try {
      final SharedPreferences preferences =
      await SharedPreferences.getInstance();

      final List<String> savedRecords =
          preferences.getStringList(recordsStorageKey) ?? [];

      final List<MedicalExamRecord> records = [];

      for (final String item in savedRecords) {
        try {
          final Map<String, dynamic> data =
          Map<String, dynamic>.from(jsonDecode(item));

          final MedicalExamRecord record =
          MedicalExamRecord.fromJson(data);

          records.add(record);
        } catch (e) {
          debugPrint('Invalid medical exam record: $e');
        }
      }

      records.sort(
            (a, b) => b.date.compareTo(a.date),
      );

      if (!mounted) return;

      setState(() {
        allRecords = records;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Load medical exams error: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showTemporaryMessage('تعذر تحميل سجلات الفحوصات');
    }
  }

  // =========================
  // Format Date & Time
  // =========================

  String formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String formatTime(DateTime date) {
    final int hour = date.hour % 12 == 0
        ? 12
        : date.hour % 12;

    final String minute =
    date.minute.toString().padLeft(2, '0');

    final String period = date.hour < 12 ? 'ص' : 'م';

    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  // =========================
  // Temporary Message
  // =========================

  void showTemporaryMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // =========================
  // Open Attachment
  // =========================

  Future<void> openAttachment(
      MedicalExamRecord record,
      ) async {
    try {
      final File file = File(record.filePath);

      if (!await file.exists()) {
        showTemporaryMessage(
          'الملف غير موجود على الجهاز',
        );
        return;
      }

      final OpenResult result =
      await OpenFilex.open(record.filePath);

      if (!mounted) return;

      if (result.type != ResultType.done) {
        showTemporaryMessage(
          'تعذر فتح المرفق. تأكدي من وجود تطبيق يدعم نوع الملف.',
        );
      }
    } catch (e) {
      debugPrint('Open attachment error: $e');

      showTemporaryMessage(
        'حدث خطأ أثناء فتح المرفق',
      );
    }
  }

  // =========================
  // Confirm Delete
  // =========================

  Future<void> confirmDelete(
      MedicalExamRecord record,
      ) async {
    if (isDeleting) return;

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
              'هل أنت متأكد من حذف هذا المرفق؟',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: textColor.withOpacity(0.70),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16,
            ),
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
      await deleteRecord(record);
    }
  }

  // =========================
  // Delete Record
  // =========================

  Future<void> deleteRecord(
      MedicalExamRecord record,
      ) async {
    if (isDeleting) return;

    setState(() {
      isDeleting = true;
    });

    try {
      final SharedPreferences preferences =
      await SharedPreferences.getInstance();

      final List<String> savedRecords =
          preferences.getStringList(recordsStorageKey) ?? [];

      final List<String> updatedRecords = [];

      for (final String item in savedRecords) {
        try {
          final Map<String, dynamic> data =
          Map<String, dynamic>.from(jsonDecode(item));

          if (data['id'] != record.id) {
            updatedRecords.add(item);
          }
        } catch (_) {
          // نحافظ على أي سجل لم نتمكن من قراءته.
          updatedRecords.add(item);
        }
      }

      final bool savedSuccessfully =
      await preferences.setStringList(
        recordsStorageKey,
        updatedRecords,
      );

      if (!savedSuccessfully) {
        throw Exception('Failed to update records');
      }

      final File file = File(record.filePath);

      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('Delete attachment file error: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        allRecords.removeWhere(
              (item) => item.id == record.id,
        );
      });

      showTemporaryMessage('تم حذف السجل بنجاح');
    } catch (e) {
      debugPrint('Delete medical exam error: $e');

      showTemporaryMessage(
        'تعذر حذف السجل. حاولي مرة أخرى.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  // =========================
  // Build Screen
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
                                  'سجلات الفحوصات',
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
                            'عرض الفحوصات الطبية التي تم تسجيلها سابقًا',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // =========================
                        // Records
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

                        if (isLoading)
                          Padding(
                            padding: const EdgeInsets.all(35),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            ),
                          )
                        else if (allRecords.isEmpty)
                          _emptyState(context)
                        else
                          ...allRecords.asMap().entries.map(
                                (entry) {
                              final int index = entry.key;
                              final MedicalExamRecord record =
                                  entry.value;

                              return Column(
                                children: [
                                  _examRecordCard(
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
  // Exam Record Card
  // =========================

  Widget _examRecordCard(
      BuildContext context, {
        required MedicalExamRecord record,
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
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xff4F829E).withOpacity(0.18)
                  : const Color(0xffEAF4FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              record.fileType == 'pdf'
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_outlined,
              color: const Color(0xff4F829E),
              size: 27,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: InkWell(
              onTap: () => openAttachment(record),
              borderRadius: BorderRadius.circular(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    record.fileType == 'pdf'
                        ? 'ملف PDF'
                        : 'صورة فحص طبي',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: textColor.withOpacity(0.65),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'الطفل: ${record.childName}',
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
                            formatTime(record.date),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textColor.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  Text(
                    'اضغطي على المرفق لفتحه',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          Material(
            color: Colors.red.withOpacity(
              isDark ? 0.12 : 0.08,
            ),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: isDeleting
                  ? null
                  : () => confirmDelete(record),
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
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.biotech_outlined,
            size: 38,
            color: primaryColor,
          ),

          const SizedBox(height: 12),

          Text(
            'لا توجد فحوصات',
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

class MedicalExamRecord {
  final String id;
  final String childName;
  final String fileName;
  final String filePath;
  final String fileType;
  final DateTime date;

  MedicalExamRecord({
    required this.id,
    required this.childName,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.date,
  });

  factory MedicalExamRecord.fromJson(
      Map<String, dynamic> json,
      ) {
    return MedicalExamRecord(
      id: json['id']?.toString() ?? '',
      childName: json['childName']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      filePath: json['filePath']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? '',
      date: DateTime.parse(json['savedAt'].toString()),
    );
  }
}