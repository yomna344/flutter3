import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'validators.dart';
import 'MealScreen.dart';

class GlucoseReadingScreen extends StatefulWidget {
  final String childName;
  final DateTime birthDate;
  final String gender;
  final String? childImagePath;

  const GlucoseReadingScreen({
    super.key,
    required this.childName,
    required this.birthDate,
    required this.gender,
    this.childImagePath,
  });

  @override
  State<GlucoseReadingScreen> createState() =>
      _GlucoseReadingScreenState();
}

class _GlucoseReadingScreenState
    extends State<GlucoseReadingScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController glucoseLevelController =
  TextEditingController();

  String? selectedReadingType;
  String? selectedMealStatus;

  // بيانات الوجبة التي تم تسجيلها من شاشة الوجبات.
  Map<String, dynamic>? selectedMealData;

  DateTime? readingDate;
  TimeOfDay? readingTime;

  String? readingTypeError;
  String? readingDateError;
  String? readingTimeError;
  String? mealStatusError;
  String? mealEntryError;

  bool isSaving = false;

  final List<String> readingTypes = [
    'قبل الوجبة',
    'بعد الوجبة',
    'صائم',
  ];

  final List<String> mealStatuses = [
    'الوجبة مسجلة في التطبيق',
    'الوجبة غير مسجلة في التطبيق',
  ];

  bool get needsMealStatus =>
      selectedReadingType == 'بعد الوجبة';

  bool get isMealNotRegistered =>
      selectedMealStatus == 'الوجبة غير مسجلة في التطبيق';

  bool get isMealRegistered =>
      selectedMealStatus == 'الوجبة مسجلة في التطبيق';

  DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String formatApiDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String formatApiTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
  }

  String formatTime(TimeOfDay? time) {
    if (time == null) return '';

    final hour =
    time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'ص' : 'م';

    return '$hour:$minute $period';
  }

  bool isToday(DateTime date) {
    return dateOnly(date) == dateOnly(DateTime.now());
  }

  bool isFutureTimeToday() {
    if (readingDate == null ||
        readingTime == null ||
        !isToday(readingDate!)) {
      return false;
    }

    final now = DateTime.now();

    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      readingTime!.hour,
      readingTime!.minute,
    );

    return selectedDateTime.isAfter(now);
  }

  // فتح شاشة تسجيل الوجبة واستقبال بياناتها.
  Future<void> openMealScreen() async {
    if (isSaving) return;

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => MealScreen(
          childName: widget.childName,
          birthDate: widget.birthDate,
          gender: widget.gender,
          childImagePath: widget.childImagePath,
          returnMealOnSave: true,
        ),
      ),
    );

    if (!mounted) return;

    if (result == null) {
      return;
    }

    setState(() {
      selectedMealData = result;
      mealEntryError = null;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'تم تسجيل الوجبة بنجاح. يمكنك الآن حفظ قراءة السكر.',
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> selectReadingDate() async {
    final today = dateOnly(DateTime.now());
    final childBirthDate = dateOnly(widget.birthDate);

    if (childBirthDate.isAfter(today)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تاريخ ميلاد الطفل غير صحيح',
            textAlign: TextAlign.center,
          ),
        ),
      );
      return;
    }

    DateTime initialDate = readingDate ?? today;

    if (initialDate.isBefore(childBirthDate)) {
      initialDate = childBirthDate;
    }

    if (initialDate.isAfter(today)) {
      initialDate = today;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: childBirthDate,
      lastDate: today,
      helpText: 'اختيار تاريخ القراءة',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (!mounted || selectedDate == null) return;

    setState(() {
      readingDate = selectedDate;
      readingDateError = null;

      if (readingTime != null && isFutureTimeToday()) {
        readingTime = null;
        readingTimeError = null;
      }
    });
  }

  Future<void> selectReadingTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: readingTime ?? TimeOfDay.now(),
      helpText: 'اختيار وقت القراءة',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (!mounted || selectedTime == null) return;

    setState(() {
      readingTime = selectedTime;

      if (readingDate != null && isFutureTimeToday()) {
        readingTimeError = 'لا يمكن اختيار وقت مستقبلي';
      } else {
        readingTimeError = null;
      }
    });
  }

  // التحقق من جميع البيانات قبل الحفظ.
  bool validateInformation() {
    final formIsValid =
        formKey.currentState?.validate() ?? false;

    setState(() {
      readingTypeError =
      selectedReadingType == null ? 'مطلوب' : null;

      readingDateError =
      readingDate == null ? 'مطلوب' : null;

      if (readingTime == null) {
        readingTimeError = 'مطلوب';
      } else if (isFutureTimeToday()) {
        readingTimeError = 'لا يمكن اختيار وقت مستقبلي';
      } else {
        readingTimeError = null;
      }

      mealStatusError =
      needsMealStatus && selectedMealStatus == null
          ? 'مطلوب'
          : null;

      // منع الحفظ إذا اختارت الوجبة غير مسجلة
      // ولم تسجل وجبة جديدة.
      mealEntryError =
      needsMealStatus &&
          isMealNotRegistered &&
          selectedMealData == null
          ? 'يجب تسجيل الوجبة أولًا قبل حفظ قراءة السكر'
          : null;
    });

    return formIsValid &&
        readingTypeError == null &&
        readingDateError == null &&
        readingTimeError == null &&
        mealStatusError == null &&
        mealEntryError == null;
  }

  Future<void> saveReading() async {
    if (isSaving) return;

    FocusScope.of(context).unfocus();

    if (!validateInformation()) return;

    setState(() {
      isSaving = true;
    });

    final glucoseLevel = double.parse(
      glucoseLevelController.text.trim(),
    );

    final readingData = <String, dynamic>{
      'reading_type': selectedReadingType,
      'glucose_level': glucoseLevel,
      'unit': 'mg/dL',
      'reading_date': formatApiDate(readingDate!),
      'reading_time': formatApiTime(readingTime!),

      'meal_status': needsMealStatus
          ? selectedMealStatus
          : null,

      // إذا كانت الوجبة غير مسجلة،
      // نرسل بيانات الوجبة الجديدة.
      'meal_data': needsMealStatus && isMealNotRegistered
          ? selectedMealData
          : null,
    };

    /*
      الربط المستقبلي مع Laravel:

      1- إذا كانت الوجبة مسجلة:
         يتم التعامل معها كوجبة موجودة،
         ولا نطلب تسجيلها مرة أخرى.

      2- إذا كانت الوجبة غير مسجلة:
         يجب تسجيل الوجبة أولًا.
         ثم تُرسل بياناتها مع قراءة السكر.

      3- لا يتم إنشاء وجبة وهمية.

      الحفظ الحالي تجريبي وليس حفظًا دائمًا.
    */

    debugPrint('Glucose reading preview: $readingData');

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'تم التحقق من بيانات القراءة. '
                'الحفظ الفعلي سيتاح بعد ربط Laravel.',
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
  }

  @override
  void dispose() {
    glucoseLevelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final primaryColor = theme.primaryColor;
    final darkColor = theme.colorScheme.onSurface;
    final cardColor = theme.cardColor;
    final isDark = theme.brightness == Brightness.dark;

    final hintColor = isDark
        ? darkColor.withOpacity(0.52)
        : const Color(0xff8A989D);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            final isVerySmall = screenWidth < 390;
            final isSmallScreen =
                screenWidth < 430 || screenHeight < 650;
            final isTablet = screenWidth >= 600;

            final horizontalPadding = isVerySmall
                ? 14.0
                : isTablet
                ? 36.0
                : 20.0;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isSmallScreen ? 12 : 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 720,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                        children: [
                          // العنوان وزر الحفظ.
                          SizedBox(
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Padding(
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 75,
                                  ),
                                  child: Text(
                                    'تسجيل قراءة السكر',
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize:
                                      isVerySmall ? 17 : 21,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment:
                                  AlignmentDirectional.centerStart,
                                  child: IconButton(
                                    onPressed: isSaving
                                        ? null
                                        : () => Navigator.pop(context),
                                    icon: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: darkColor,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment:
                                  AlignmentDirectional.centerEnd,
                                  child: SizedBox(
                                    height: 44,
                                    child: ElevatedButton(
                                      onPressed:
                                      isSaving ? null : saveReading,
                                      style:
                                      ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                          isVerySmall ? 14 : 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: isSaving
                                          ? const SizedBox(
                                        width: 21,
                                        height: 21,
                                        child:
                                        CircularProgressIndicator(
                                          strokeWidth: 2.3,
                                          color: Colors.white,
                                        ),
                                      )
                                          : Text(
                                        'حفظ',
                                        style: TextStyle(
                                          fontSize:
                                          isVerySmall ? 14 : 16,
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: isSmallScreen ? 16 : 22,
                          ),

                          Text(
                            'سجّل مستوى السكر لطفلك للحفاظ على متابعة دقيقة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: hintColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          SizedBox(
                            height: isSmallScreen ? 30 : 40,
                          ),

                          // صندوق النصائح.
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xff2A281E)
                                  : const Color(0xffFFF9E8),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xff5B5130)
                                    : const Color(0xffF1E4B8),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: Color(0xffD7A82C),
                                  size: 25,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'نصائح مهمة',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: darkColor,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        '• لقياس السكر بعد الوجبة، يُستخدم غالبًا توقيت ساعتين من بداية الأكل، وفق خطة الطبيب.\n'
                                            '• خذ عينة الدم من جانب الإصبع.\n'
                                            '• اتبع تعليمات جهاز القياس بشأن القطرة الأولى أو الثانية.\n'
                                            '• تأكد أن اليد نظيفة وجافة قبل القياس، دون بقايا ماء أو كحول.',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.7,
                                          color: isDark
                                              ? darkColor.withOpacity(0.70)
                                              : const Color(0xff66777D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Icon(
                                Icons.monitor_heart_outlined,
                                color: primaryColor,
                                size: 25,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'بيانات قراءة السكر',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: darkColor,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          _buildReadingTypeField(
                            primaryColor: primaryColor,
                            textColor: darkColor,
                          ),

                          const SizedBox(height: 22),

                          // مستوى السكر والتاريخ.
                          if (isVerySmall)
                            Column(
                              children: [
                                _buildGlucoseField(
                                  primaryColor: primaryColor,
                                  cardColor: cardColor,
                                  textColor: darkColor,
                                ),
                                const SizedBox(height: 16),
                                _buildDateField(
                                  primaryColor: primaryColor,
                                  hintColor: hintColor,
                                  darkColor: darkColor,
                                  cardColor: cardColor,
                                ),
                              ],
                            )
                          else
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildGlucoseField(
                                    primaryColor: primaryColor,
                                    cardColor: cardColor,
                                    textColor: darkColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateField(
                                    primaryColor: primaryColor,
                                    hintColor: hintColor,
                                    darkColor: darkColor,
                                    cardColor: cardColor,
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 20),

                          _buildTimeField(
                            primaryColor: primaryColor,
                            hintColor: hintColor,
                            darkColor: darkColor,
                            cardColor: cardColor,
                          ),

                          // قسم الوجبة يظهر بعد الوجبة فقط.
                          if (needsMealStatus) ...[
                            const SizedBox(height: 22),
                            _buildMealStatusField(
                              primaryColor: primaryColor,
                              cardColor: cardColor,
                              textColor: darkColor,
                            ),

                            if (selectedMealStatus != null) ...[
                              const SizedBox(height: 10),
                              _buildMealInformation(
                                primaryColor: primaryColor,
                                textColor: darkColor,
                                isRegistered: isMealRegistered,
                              ),
                            ],
                          ],

                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReadingTypeField({
    required Color primaryColor,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('نوع القراءة', textColor),
        const SizedBox(height: 10),
        Row(
          children: readingTypes.map((type) {
            final isSelected = selectedReadingType == type;

            return Expanded(
              child: InkWell(
                onTap: isSaving
                    ? null
                    : () {
                  setState(() {
                    selectedReadingType = type;
                    readingTypeError = null;
                    selectedMealStatus = null;
                    selectedMealData = null;
                    mealStatusError = null;
                    mealEntryError = null;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          type,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 21,
                        color: isSelected
                            ? primaryColor
                            : textColor.withOpacity(0.35),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (readingTypeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              readingTypeError!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGlucoseField({
    required Color primaryColor,
    required Color cardColor,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('مستوى السكر (mg/dL)', textColor),
        const SizedBox(height: 8),
        TextFormField(
          controller: glucoseLevelController,
          enabled: !isSaving,
          textAlign: TextAlign.right,
          textDirection: TextDirection.ltr,
          style: TextStyle(color: textColor),
          keyboardType:
          const TextInputType.numberWithOptions(
            decimal: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'^\d{0,3}(\.\d{0,1})?'),
            ),
          ],
          autovalidateMode:
          AutovalidateMode.onUserInteraction,
          validator: Validators.glucoseReading,
          decoration: glucoseInputDecoration(
            hint: 'مثلاً 120',
            primaryColor: primaryColor,
            fieldColor: cardColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required Color primaryColor,
    required Color hintColor,
    required Color darkColor,
    required Color cardColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('تاريخ القراءة', darkColor),
        const SizedBox(height: 8),
        InkWell(
          onTap: isSaving ? null : selectReadingDate,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: glucoseInputDecoration(
              primaryColor: primaryColor,
              fieldColor: cardColor,
              errorText: readingDateError,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    readingDate == null
                        ? 'اختاري التاريخ'
                        : formatDate(readingDate),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      color: readingDate == null
                          ? hintColor
                          : darkColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.calendar_today_outlined,
                  color: primaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField({
    required Color primaryColor,
    required Color hintColor,
    required Color darkColor,
    required Color cardColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('وقت القراءة', darkColor),
        const SizedBox(height: 8),
        InkWell(
          onTap: isSaving ? null : selectReadingTime,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: glucoseInputDecoration(
              primaryColor: primaryColor,
              fieldColor: cardColor,
              errorText: readingTimeError,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    readingTime == null
                        ? 'مثلاً 04:00 م'
                        : formatTime(readingTime),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      color: readingTime == null
                          ? hintColor
                          : darkColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.access_time_rounded,
                  color: primaryColor,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealStatusField({
    required Color primaryColor,
    required Color cardColor,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('حالة تسجيل الوجبة', textColor),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: DropdownButtonFormField<String>(
            key: const ValueKey('meal_status_dropdown'),
            value: selectedMealStatus,
            isExpanded: true,
            dropdownColor: cardColor,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: textColor,
            ),
            style: TextStyle(
              color: textColor,
              fontSize: 13,
            ),
            decoration: glucoseInputDecoration(
              hint: '',
              primaryColor: primaryColor,
              fieldColor: cardColor,
              errorText: mealStatusError,
            ),
            hint: const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'اختاري حالة الوجبة',
                textDirection: TextDirection.rtl,
              ),
            ),
            selectedItemBuilder: (context) {
              return mealStatuses.map((status) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    status,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList();
            },
            items: mealStatuses.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    status,
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
            onChanged: isSaving
                ? null
                : (value) {
              setState(() {
                if (selectedMealStatus != value) {
                  selectedMealData = null;
                }

                selectedMealStatus = value;
                mealStatusError = null;
                mealEntryError = null;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMealInformation({
    required Color primaryColor,
    required Color textColor,
    required bool isRegistered,
  }) {
    // الوجبة مسجلة: لا نعرض زر تسجيل مرة أخرى.
    if (isRegistered) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: primaryColor,
              size: 21,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                'تم اختيار أن الوجبة مسجلة في التطبيق.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: textColor.withOpacity(0.75),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // الوجبة غير مسجلة: نطلب تسجيلها أولًا.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.045),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: primaryColor.withOpacity(0.18),
        ),
      ),
      child: Column(
        children: [
          if (selectedMealData == null) ...[

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : openMealScreen,
                icon: const Icon(Icons.add_rounded),
                label: const Text('تسجيل وجبة جديدة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تم تسجيل الوجبة',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'نوع الوجبة: ${selectedMealData!['meal_type'] ?? ''}',
                style: TextStyle(
                  color: textColor.withOpacity(0.75),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الأطعمة: ${_mealFoodsText()}',
                style: TextStyle(
                  color: textColor.withOpacity(0.75),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: isSaving ? null : openMealScreen,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('تعديل الوجبة'),
            ),
          ],

          if (mealEntryError != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                mealEntryError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _mealFoodsText() {
    if (selectedMealData == null) return '';

    final foods = selectedMealData!['foods'];

    if (foods is Map) {
      return foods.values
          .whereType<List>()
          .expand((items) => items)
          .join('، ');
    }

    return '';
  }

  Widget _fieldLabel(String label, Color textColor) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textColor.withOpacity(0.85),
      ),
    );
  }

  InputDecoration glucoseInputDecoration({
    required Color primaryColor,
    required Color fieldColor,
    String? hint,
    String? errorText,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    final borderColor = isDark
        ? textColor.withOpacity(0.18)
        : const Color(0xffD7E0E2);

    final hintColor = isDark
        ? textColor.withOpacity(0.52)
        : const Color(0xff8A989D);

    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      hintStyle: TextStyle(
        color: hintColor,
        fontSize: 13,
      ),
      errorText: errorText,
      errorStyle: const TextStyle(fontSize: 11),
      filled: true,
      fillColor: fieldColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 19,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: borderColor,
          width: 1.3,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: primaryColor,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.3,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.8,
        ),
      ),
    );
  }
}