
import 'package:flutter/material.dart';

import 'ChildStore.dart';
import 'services/meal_service.dart';

class MealScreen extends StatefulWidget {
  final String childName;
  final DateTime birthDate;
  final String gender;
  final String? childImagePath;

  // عند فتح الشاشة من قراءة السكر نرجع الوجبة الجديدة.
  final bool returnMealOnSave;

  const MealScreen({
    super.key,
    required this.childName,
    required this.birthDate,
    required this.gender,
    this.childImagePath,
    this.returnMealOnSave = false,
  });

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealEntry {
  final int mealId;
  final String type;
  final Map<String, List<String>> foods;
  final DateTime dateTime;
  final String? notes;

  const _MealEntry({
    required this.mealId,
    required this.type,
    required this.foods,
    required this.dateTime,
    this.notes,
  });

  String get summary =>
      foods.values.expand((items) => items).join('، ');
}

class _MealScreenState extends State<MealScreen> {
  final _notesController = TextEditingController();
  final _typeKey = GlobalKey();

  static const mealTypes = [
    'الإفطار',
    'الغداء',
    'العشاء',
    'وجبة خفيفة',
  ];

  static const Map<String, List<String>> foodGroups = {
    'النشويات والكربوهيدرات': [
      'أرز',
      'خبز',
      'بطاطس',
      'معكرونة',
    ],
    'البروتينات': [
      'دجاج',
      'سمك',
      'لحم',
      'بيض',
      'بقوليات',
    ],
    'الخضروات': [
      'خيار',
      'طماطم',
      'جزر',
      'سلطة',
    ],
    'الفواكه': [
      'تفاح',
      'موز',
      'برتقال',
    ],
    'الحليب ومشتقاته': [
      'حليب',
      'زبادي',
      'جبن',
    ],
    'الدهون الصحية': [
      'زيت الزيتون',
      'أفوكادو',
      'مكسرات',
    ],
  };

  final Map<String, Set<String>> _selectedFoods = {};
  final Map<String, List<String>> _customFoods = {};
  final List<_MealEntry> _sessionMeals = [];

  String? _mealType;
  DateTime? _mealDate;
  TimeOfDay? _mealTime;

  String? _typeError;
  String? _foodError;
  String? _dateError;
  String? _timeError;

  bool _showNotes = false;
  bool _showMeals = false;
  bool _isSaving = false;

  Color _border(ThemeData theme) {
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface.withOpacity(0.18)
        : const Color(0xffD7E7E7);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _dateText(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _timeText(TimeOfDay time) {
    final hour =
    time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period =
    time.period == DayPeriod.am ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  bool _isFuture() {
    if (_mealDate == null || _mealTime == null) {
      return false;
    }

    final date = _mealDate!;

    return DateTime(
      date.year,
      date.month,
      date.day,
      _mealTime!.hour,
      _mealTime!.minute,
    ).isAfter(DateTime.now());
  }

  Map<String, List<String>> _chosenFoods() {
    final result = <String, List<String>>{};

    for (final group in foodGroups.keys) {
      final foods = <String>[
        ...?_selectedFoods[group],
        ...?_customFoods[group],
      ];

      if (foods.isNotEmpty) {
        result[group] = foods;
      }
    }

    return result;
  }

  List<String> get _foodNames =>
      _chosenFoods().values.expand((foods) => foods).toList();

  String _formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _formatApiTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _chooseMealType() async {
    final box = _typeKey.currentContext
        ?.findRenderObject() as RenderBox?;

    final overlay = Overlay.of(context)
        .context
        .findRenderObject() as RenderBox?;

    if (box == null || overlay == null) return;

    final offset = box.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    final rect = Rect.fromLTWH(
      offset.dx,
      offset.dy + box.size.height + 4,
      box.size.width,
      0,
    );

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        rect,
        Offset.zero & overlay.size,
      ),
      constraints: BoxConstraints(
        minWidth: box.size.width,
        maxWidth: box.size.width,
      ),
      items: mealTypes.map((type) {
        return PopupMenuItem<String>(
          value: type,
          height: 46,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(type),
          ),
        );
      }).toList(),
    );

    if (!mounted || selected == null) return;

    setState(() {
      _mealType = selected;
      _typeError = null;
    });
  }

  Future<void> _pickDate() async {
    final today = _dateOnly(DateTime.now());
    final birth = _dateOnly(widget.birthDate);

    if (birth.isAfter(today)) {
      _message('تاريخ ميلاد الطفل غير صحيح');
      return;
    }

    var initial = _mealDate ?? today;

    if (initial.isBefore(birth)) initial = birth;
    if (initial.isAfter(today)) initial = today;

    final chosen = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: birth,
      lastDate: today,
      helpText: 'اختيار تاريخ الوجبة',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (!mounted || chosen == null) return;

    setState(() {
      _mealDate = chosen;
      _dateError = null;
      _timeError = _isFuture()
          ? 'لا يمكن اختيار وقت مستقبلي'
          : null;
    });
  }

  Future<void> _pickTime() async {
    final chosen = await showTimePicker(
      context: context,
      initialTime: _mealTime ?? TimeOfDay.now(),
      helpText: 'اختيار وقت الوجبة',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (!mounted || chosen == null) return;

    setState(() {
      _mealTime = chosen;
      _timeError = _isFuture()
          ? 'لا يمكن اختيار وقت مستقبلي'
          : null;
    });
  }

  Future<void> _openFoodPicker() async {
    final draftSelected = <String, Set<String>>{
      for (final group in foodGroups.keys)
        group: {...?_selectedFoods[group]},
    };

    final draftCustom = <String, List<String>>{
      for (final group in foodGroups.keys)
        group: [...?_customFoods[group]],
    };

    final otherController = TextEditingController();

    String? activeGroup;
    String? otherError;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, updateSheet) {
            final theme = Theme.of(sheetContext);
            final primary = theme.primaryColor;
            final dark = theme.colorScheme.onSurface;
            final border = _border(theme);

            final chosen = <String>[];

            for (final group in foodGroups.keys) {
              chosen.addAll(draftSelected[group]!);
              chosen.addAll(draftCustom[group]!);
            }

            void addOther() {
              final group = activeGroup;

              if (group == null) {
                updateSheet(() {
                  otherError = 'اختاري المجموعة الغذائية أولًا';
                });
                return;
              }

              final value = otherController.text.trim();

              if (value.isEmpty) {
                updateSheet(() {
                  otherError = 'اكتبي اسم الطعام أولًا';
                });
                return;
              }

              if (value.length > 50) {
                updateSheet(() {
                  otherError = 'الحد الأقصى 50 حرفًا';
                });
                return;
              }

              if (foodGroups[group]!.contains(value) ||
                  draftCustom[group]!.contains(value)) {
                updateSheet(() {
                  otherError = 'هذا الطعام موجود مسبقًا';
                });
                return;
              }

              updateSheet(() {
                draftCustom[group]!.add(value);
                otherController.clear();
                otherError = null;
              });
            }

            void removeFood(String group, String food) {
              updateSheet(() {
                draftSelected[group]!.remove(food);
                draftCustom[group]!.remove(food);
              });
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext)
                      .viewInsets.bottom,
                ),
                child: FractionallySizedBox(
                  heightFactor: 0.80,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: border,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16, 10, 16, 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.layers_outlined,
                              color: primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'اختيار الأطعمة',
                                style: TextStyle(
                                  color: dark,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.pop(sheetContext, false),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          children: [
                            Text(
                              'المجموعة الغذائية',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: dark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              key: ValueKey(activeGroup),
                              value: activeGroup,
                              isExpanded: true,
                              dropdownColor: theme.cardColor,
                              alignment:
                              AlignmentDirectional.centerStart,
                              decoration: _decoration(
                                'اختاري المجموعة الغذائية',
                                Icons.category_outlined,
                                primary,
                                border,
                                theme.cardColor,
                              ),
                              hint: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'اختاري المجموعة الغذائية',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: dark.withOpacity(0.55),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              items: foodGroups.keys.map((group) {
                                return DropdownMenuItem<String>(
                                  value: group,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      group,
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (group) {
                                if (group == null) return;

                                updateSheet(() {
                                  activeGroup = group;
                                  otherController.clear();
                                  otherError = null;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            if (activeGroup == null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.045),
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(color: border),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.touch_app_outlined,
                                      color: primary,
                                      size: 27,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'اختاري مجموعة غذائية لعرض الأطعمة المتاحة',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: dark.withOpacity(0.7),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else ...[
                              Text(
                                'الأطعمة المتاحة',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: dark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 5,
                                children:
                                foodGroups[activeGroup]!.map((food) {
                                  final selected =
                                  draftSelected[activeGroup]!
                                      .contains(food);

                                  return FilterChip(
                                    label: Text(food),
                                    selected: selected,
                                    selectedColor:
                                    primary.withOpacity(0.16),
                                    checkmarkColor: primary,
                                    onSelected: (value) {
                                      updateSheet(() {
                                        if (value) {
                                          draftSelected[activeGroup]!
                                              .add(food);
                                        } else {
                                          draftSelected[activeGroup]!
                                              .remove(food);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                'أخرى',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: dark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: otherController,
                                      maxLength: 50,
                                      textAlign: TextAlign.right,
                                      decoration: _decoration(
                                        'اسم طعام غير موجود',
                                        Icons.add,
                                        primary,
                                        border,
                                        theme.cardColor,
                                      ).copyWith(counterText: ''),
                                      onSubmitted: (_) => addOther(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    onPressed: addOther,
                                    tooltip: 'إضافة الطعام',
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                              if (otherError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    otherError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    'الأطعمة المختارة',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: dark,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${chosen.length} أطعمة',
                                  style: TextStyle(
                                    color: dark.withOpacity(0.65),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (chosen.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Text(
                                  'لم تختاري أي طعام بعد',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: dark.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 145,
                                ),
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.045),
                                  border: Border.all(color: border),
                                  borderRadius:
                                  BorderRadius.circular(12),
                                ),
                                child: SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 5,
                                    children: [
                                      for (final group in foodGroups.keys)
                                        for (final food in <String>[
                                          ...draftSelected[group]!,
                                          ...draftCustom[group]!,
                                        ])
                                          InputChip(
                                            label: Text(food),
                                            onDeleted: () =>
                                                removeFood(group, food),
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16, 8, 16, 16,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(sheetContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'تم الاختيار (${chosen.length})',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback(
          (_) => otherController.dispose(),
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _selectedFoods
        ..clear()
        ..addAll(draftSelected);

      _customFoods
        ..clear()
        ..addAll(draftCustom);

      _foodError = _foodNames.isEmpty
          ? 'اختاري طعامًا واحدًا على الأقل'
          : null;
    });
  }

  void _resetForm() {
    _notesController.clear();

    setState(() {
      _mealType = null;
      _mealDate = null;
      _mealTime = null;

      _selectedFoods.clear();
      _customFoods.clear();

      _typeError = null;
      _foodError = null;
      _dateError = null;
      _timeError = null;

      _showNotes = false;
    });
  }

  // =====================================
  // حفظ الوجبة في Laravel
  // =====================================

  Future<void> _save() async {
    if (_isSaving) return;

    FocusScope.of(context).unfocus();

    final chosenFoods = _chosenFoods();

    setState(() {
      _typeError = _mealType == null ? 'مطلوب' : null;
      _foodError = chosenFoods.isEmpty
          ? 'اختاري طعامًا واحدًا على الأقل'
          : null;
      _dateError = _mealDate == null ? 'مطلوب' : null;
      _timeError = _mealTime == null
          ? 'مطلوب'
          : _isFuture()
          ? 'لا يمكن اختيار وقت مستقبلي'
          : null;
    });

    if (_typeError != null ||
        _foodError != null ||
        _dateError != null ||
        _timeError != null) {
      return;
    }

    final int? childId =
        ChildStore.instance.selectedChild?.id;

    if (childId == null) {
      _message('يرجى اختيار طفل محفوظ في الحساب أولًا.');
      return;
    }

    final date = _mealDate!;
    final time = _mealTime!;
    final notes = _notesController.text.trim();

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await MealService.saveMeal(
        childId: childId,
        mealType: _mealType!,
        ingredients: chosenFoods,
        mealDate: _formatApiDate(dateTime),
        mealTime: _formatApiTime(dateTime),
        notes: notes.isEmpty ? null : notes,
      );

      final idValue = response['meal_id'];

      final int? mealId = idValue is int
          ? idValue
          : int.tryParse(idValue?.toString() ?? '');

      if (mealId == null || mealId <= 0) {
        throw Exception(
          'تعذر الحصول على رقم الوجبة المحفوظة.',
        );
      }

      if (!mounted) return;

      final entry = _MealEntry(
        mealId: mealId,
        type: _mealType!,
        foods: chosenFoods,
        dateTime: dateTime,
        notes: notes.isEmpty ? null : notes,
      );

      // إرجاع الوجبة إلى شاشة السكر بعد نجاح الحفظ
      if (widget.returnMealOnSave) {
        Navigator.pop(context, {
          'meal_id': entry.mealId,
          'meal_type': entry.type,
          'foods': entry.foods,
          'meal_date': _formatApiDate(entry.dateTime),
          'meal_time': _formatApiTime(entry.dateTime),
          'notes': entry.notes,
        });
        return;
      }

      // قائمة الوجبات المحفوظة خلال فتح الصفحة
      setState(() {
        _sessionMeals.insert(0, entry);
      });

      _resetForm();
      _message('تم حفظ الوجبة بنجاح.');
    } catch (error) {
      if (!mounted) return;

      _message(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted && _isSaving) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // التعديل والحذف يحتاجان مسارات API مستقلة.
  // لا نغيّر القائمة محليًا ونوهم المستخدم أن MySQL تغيّرت.

  void _edit(int index) {
    _message(
      'تعديل الوجبة في MySQL سيتاح بعد ربط التحديث مع Laravel.',
    );
  }

  void _delete(int index) {
    _message(
      'حذف الوجبة من MySQL سيتاح بعد ربط الحذف مع Laravel.',
    );
  }

  InputDecoration _decoration(
      String hint,
      IconData icon,
      Color primary,
      Color border,
      Color fill, {
        String? error,
      }) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      errorText: error,
      prefixIcon: Icon(
        icon,
        color: primary,
        size: 20,
      ),
      filled: true,
      fillColor: fill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: border,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: primary,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _field({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    required Color primary,
    required Color border,
    required Color fill,
    required Color dark,
    String? error,
    bool placeholder = false,
    Key? key,
    int maxLines = 1,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _decoration(
          '',
          icon,
          primary,
          border,
          fill,
          error: error,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            text,
            textAlign: TextAlign.right,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: placeholder
                  ? dark.withOpacity(0.55)
                  : dark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _foldable({
    required String title,
    required IconData icon,
    required bool expanded,
    required VoidCallback onTap,
    required Color primary,
    required Color border,
    required Color fill,
    required Color dark,
    String? subtitle,
    Widget? content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: Icon(icon, color: primary, size: 21),
            title: Text(
              title,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: dark,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: subtitle == null
                ? null
                : Text(
              subtitle,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Icon(
              expanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: primary,
            ),
            onTap: onTap,
          ),
          if (expanded && content != null) content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final dark = theme.colorScheme.onSurface;
    final fill = theme.cardColor;
    final border = _border(theme);

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final verySmall = constraints.maxWidth < 390;

              final horizontal = verySmall
                  ? 14.0
                  : constraints.maxWidth >= 600
                  ? 36.0
                  : 20.0;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontal,
                  vertical: 14,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 720,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 46,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                'تسجيل وجبة',
                                style: TextStyle(
                                  fontSize: verySmall ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: dark,
                                ),
                              ),
                              Align(
                                alignment:
                                AlignmentDirectional.centerStart,
                                child: IconButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => Navigator.pop(context),
                                  icon: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: dark,
                                  ),
                                ),
                              ),
                              Align(
                                alignment:
                                AlignmentDirectional.centerEnd,
                                child: ElevatedButton(
                                  onPressed:
                                  _isSaving ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Text('حفظ'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant_rounded,
                              color: primary,
                              size: 22,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'إضافة وجبة جديدة',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: dark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _field(
                          key: _typeKey,
                          text: _mealType ?? 'نوع الوجبة',
                          placeholder: _mealType == null,
                          icon: Icons.list_rounded,
                          onTap: _chooseMealType,
                          primary: primary,
                          border: border,
                          fill: fill,
                          dark: dark,
                          error: _typeError,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          text: _foodNames.isEmpty
                              ? 'اختيار الأطعمة'
                              : _foodNames.join('، '),
                          placeholder: _foodNames.isEmpty,
                          icon: Icons.layers_outlined,
                          onTap: _openFoodPicker,
                          primary: primary,
                          border: border,
                          fill: fill,
                          dark: dark,
                          error: _foodError,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        if (verySmall) ...[
                          _field(
                            text: _mealDate == null
                                ? 'تاريخ الوجبة'
                                : _dateText(_mealDate!),
                            placeholder: _mealDate == null,
                            icon: Icons.calendar_month_outlined,
                            onTap: _pickDate,
                            primary: primary,
                            border: border,
                            fill: fill,
                            dark: dark,
                            error: _dateError,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            text: _mealTime == null
                                ? 'وقت الوجبة'
                                : _timeText(_mealTime!),
                            placeholder: _mealTime == null,
                            icon: Icons.access_time_rounded,
                            onTap: _pickTime,
                            primary: primary,
                            border: border,
                            fill: fill,
                            dark: dark,
                            error: _timeError,
                          ),
                        ] else
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  text: _mealDate == null
                                      ? 'تاريخ الوجبة'
                                      : _dateText(_mealDate!),
                                  placeholder: _mealDate == null,
                                  icon:
                                  Icons.calendar_month_outlined,
                                  onTap: _pickDate,
                                  primary: primary,
                                  border: border,
                                  fill: fill,
                                  dark: dark,
                                  error: _dateError,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _field(
                                  text: _mealTime == null
                                      ? 'وقت الوجبة'
                                      : _timeText(_mealTime!),
                                  placeholder: _mealTime == null,
                                  icon: Icons.access_time_rounded,
                                  onTap: _pickTime,
                                  primary: primary,
                                  border: border,
                                  fill: fill,
                                  dark: dark,
                                  error: _timeError,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        _foldable(
                          title: 'إضافة ملاحظة (اختياري)',
                          icon: Icons.edit_note_rounded,
                          expanded: _showNotes,
                          onTap: () {
                            setState(() {
                              _showNotes = !_showNotes;
                            });
                          },
                          primary: primary,
                          border: border,
                          fill: fill,
                          dark: dark,
                          content: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              12, 0, 12, 12,
                            ),
                            child: TextField(
                              controller: _notesController,
                              maxLength: 200,
                              minLines: 2,
                              maxLines: 4,
                              textAlign: TextAlign.right,
                              decoration: _decoration(
                                'مثلاً: الطفل لم يأكل الوجبة كاملة',
                                Icons.notes,
                                primary,
                                border,
                                fill,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _foldable(
                          title: 'الوجبات المسجلة',
                          icon: Icons.restaurant_menu_rounded,
                          subtitle:
                          '(${_sessionMeals.length}) — المحفوظة خلال فتح الصفحة',
                          expanded: _showMeals,
                          onTap: () {
                            setState(() {
                              _showMeals = !_showMeals;
                            });
                          },
                          primary: primary,
                          border: border,
                          fill: fill,
                          dark: dark,
                          content: Column(
                            children: [
                              const Divider(height: 1),
                              if (_sessionMeals.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'لا توجد وجبات محفوظة خلال فتح الصفحة بعد',
                                  ),
                                ),
                              ...List.generate(
                                _sessionMeals.length,
                                    (index) {
                                  final meal = _sessionMeals[index];

                                  return Column(
                                    children: [
                                      ListTile(
                                        title: Text(
                                          meal.type,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontWeight:
                                            FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${meal.summary}\n'
                                              '${_dateText(meal.dateTime)} - '
                                              '${_timeText(TimeOfDay.fromDateTime(meal.dateTime))}'
                                              '${meal.notes == null ? '' : '\nملاحظة: ${meal.notes}'}',
                                          textAlign: TextAlign.right,
                                        ),
                                        isThreeLine: true,
                                        trailing:
                                        PopupMenuButton<String>(
                                          tooltip: 'خيارات الوجبة',
                                          onSelected: (action) {
                                            if (action == 'edit') {
                                              _edit(index);
                                            }
                                            if (action == 'delete') {
                                              _delete(index);
                                            }
                                          },
                                          itemBuilder: (_) => const [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text('تعديل'),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text('حذف'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (index !=
                                          _sessionMeals.length - 1)
                                        const Divider(height: 1),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? primary.withOpacity(0.08)
                                : const Color(0xffEEF7FA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: primary,
                                size: 19,
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  'يرجى التأكد من صحة البيانات قبل الحفظ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: dark,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
