import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemindersRecordsScreen extends StatefulWidget {
  const RemindersRecordsScreen({super.key});

  @override
  State<RemindersRecordsScreen> createState() =>
      _RemindersRecordsScreenState();
}

class _RemindersRecordsScreenState
    extends State<RemindersRecordsScreen> {
  // نفس مفتاح التخزين المستخدم في RemindersScreen.dart
  static const String remindersStorageKey = 'tinyguide_reminders_v1';

  List<ReminderRecord> allRecords = [];

  bool isLoading = true;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  // =========================
  // Date and time helpers
  // =========================

  String formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String formatTime(DateTime date) {
    final TimeOfDay time = TimeOfDay.fromDateTime(date);

    final int hour =
    time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final String minute = time.minute.toString().padLeft(2, '0');

    final String period =
    time.period == DayPeriod.am ? 'ص' : 'م';

    return '$hour:$minute $period';
  }

  // =========================
  // Load saved reminders
  // =========================

  Future<void> loadRecords() async {
    try {
      final SharedPreferences preferences =
      await SharedPreferences.getInstance();

      final String? savedData =
      preferences.getString(remindersStorageKey);

      if (savedData == null) {
        if (!mounted) return;

        setState(() {
          allRecords = [];
          isLoading = false;
        });

        return;
      }

      final dynamic decodedData = jsonDecode(savedData);

      if (decodedData is! List) {
        throw const FormatException('Invalid reminders data');
      }

      final List<ReminderRecord> loadedRecords = [];

      for (final dynamic item in decodedData) {
        if (item is! Map) {
          continue;
        }

        final Map<String, dynamic> reminder =
        Map<String, dynamic>.from(item);

        final String id = reminder['id']?.toString() ?? '';

        final String title =
            reminder['title']?.toString() ?? '';

        final String? dateValue =
        reminder['remind_at']?.toString();

        if (id.isEmpty ||
            title.isEmpty ||
            dateValue == null) {
          continue;
        }

        final DateTime? remindAt =
        DateTime.tryParse(dateValue);

        if (remindAt == null) {
          continue;
        }

        loadedRecords.add(
          ReminderRecord(
            id: id,
            title: title,
            remindAt: remindAt,
            isActive: reminder['is_active'] == true,
          ),
        );
      }

      // عرض جميع التذكيرات بدون فلترة.
      loadedRecords.sort(
            (first, second) =>
            first.remindAt.compareTo(second.remindAt),
      );

      if (!mounted) return;

      setState(() {
        allRecords = loadedRecords;
        isLoading = false;
      });
    } catch (error) {
      debugPrint('Load reminder records error: $error');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showTemporaryMessage(
        'تعذر تحميل سجلات التذكيرات',
      );
    }
  }

  // =========================
  // Messages
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
  // Confirm delete
  // =========================

  Future<void> confirmDelete(ReminderRecord record) async {
    if (isDeleting || isLoading) return;

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
                    color: Colors.red.withOpacity(
                      isDark ? 0.12 : 0.08,
                    ),
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
              'هل أنت متأكد من حذف سجل هذا التذكير؟',
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

    if (!mounted) return;

    if (shouldDelete == true) {
      await deleteRecord(record);
    }
  }

  // =========================
  // Delete saved reminder
  // =========================

  Future<void> deleteRecord(ReminderRecord record) async {
    if (isDeleting || isLoading) return;

    setState(() {
      isDeleting = true;
    });

    try {
      final SharedPreferences preferences =
      await SharedPreferences.getInstance();

      // نقرأ أحدث نسخة محفوظة قبل الحذف.
      final String? savedData =
      preferences.getString(remindersStorageKey);

      if (savedData == null) {
        if (!mounted) return;

        setState(() {
          allRecords.removeWhere(
                (item) => item.id == record.id,
          );
          isDeleting = false;
        });

        return;
      }

      final dynamic decodedData = jsonDecode(savedData);

      if (decodedData is! List) {
        throw const FormatException('Invalid reminders data');
      }

      final List<Map<String, dynamic>> savedReminders =
      decodedData.map<Map<String, dynamic>>((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();

      savedReminders.removeWhere(
            (item) => item['id']?.toString() == record.id,
      );

      final bool saved = await preferences.setString(
        remindersStorageKey,
        jsonEncode(savedReminders),
      );

      if (!mounted) return;

      if (!saved) {
        setState(() {
          isDeleting = false;
        });

        showTemporaryMessage(
          'تعذر حذف التذكير، حاولي مرة أخرى',
        );

        return;
      }

      setState(() {
        allRecords.removeWhere(
              (item) => item.id == record.id,
        );

        isDeleting = false;
      });

      showTemporaryMessage(
        'تم حذف سجل التذكير بنجاح',
      );
    } catch (error) {
      debugPrint('Delete reminder record error: $error');

      if (!mounted) return;

      setState(() {
        isDeleting = false;
      });

      showTemporaryMessage(
        'تعذر حذف التذكير، حاولي مرة أخرى',
      );
    }
  }

  // =========================
  // Main interface
  // =========================

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
                    constraints:
                    const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        // =====================
                        // Header
                        // =====================

                        SizedBox(
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: Text(
                                  'سجلات التذكيرات',
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

                        const SizedBox(height: 12),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                          ),
                          child: Text(
                            'عرض جميع التذكيرات المسجلة سابقًا والقادمة',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // =====================
                        // Records count
                        // =====================

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

                        // =====================
                        // Records list
                        // =====================

                        if (isLoading)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(30),
                              child: CircularProgressIndicator(
                                color: theme.primaryColor,
                              ),
                            ),
                          )
                        else if (allRecords.isEmpty)
                          _emptyState(context)
                        else
                          ...allRecords.asMap().entries.map((entry) {
                            final int index = entry.key;
                            final ReminderRecord record = entry.value;

                            return Column(
                              children: [
                                _reminderRecordCard(
                                  context,
                                  record: record,
                                ),

                                if (index != allRecords.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            );
                          }),

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
  // Reminder record card
  // =========================

  Widget _reminderRecordCard(
      BuildContext context, {
        required ReminderRecord record,
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
                  ? const Color(0xff4D9E99).withOpacity(0.18)
                  : const Color(0xffE9F6F5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xff4D9E99),
              size: 27,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // Reminder title
                Text(
                  record.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 7),

                // Reminder status
                Row(
                  children: [
                    Icon(
                      record.isActive
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      size: 15,
                      color: record.isActive
                          ? primaryColor
                          : textColor.withOpacity(0.55),
                    ),

                    const SizedBox(width: 4),

                    Text(
                      record.isActive
                          ? 'مفعّل'
                          : 'غير مفعّل',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: record.isActive
                            ? primaryColor
                            : textColor.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                // Date and time
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
                          formatDate(record.remindAt),
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
                          formatTime(record.remindAt),
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

          // Delete button
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
  // Empty state
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
            Icons.notifications_off_outlined,
            size: 38,
            color: primaryColor,
          ),

          const SizedBox(height: 12),

          Text(
            'لا توجد تذكيرات مسجلة حتى الآن',
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

// =========================
// Reminder record model
// =========================

class ReminderRecord {
  final String id;
  final String title;
  final DateTime remindAt;
  final bool isActive;

  const ReminderRecord({
    required this.id,
    required this.title,
    required this.remindAt,
    required this.isActive,
  });
}