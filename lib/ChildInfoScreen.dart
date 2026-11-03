
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'validators.dart';
import 'MainNavigationScreen.dart';
import 'ChildStore.dart';
import 'services/child_service.dart';

class ChildInfoScreen extends StatefulWidget {
  final bool showBackButton;
  final bool isEditMode;
  final bool returnToProfileAfterSave;

  // رقم الطفل الحقيقي في قاعدة البيانات
  final int? childId;

  final String? initialFirstName;
  final String? initialSecondName;
  final String? initialLastName;
  final String? initialGender;
  final DateTime? initialBirthDate;
  final String? initialDiabetesType;
  final DateTime? initialDiagnosisDate;
  final String? initialNotes;
  final String? initialImagePath;

  const ChildInfoScreen({
    super.key,
    this.showBackButton = false,
    this.isEditMode = false,
    this.returnToProfileAfterSave = false,
    this.childId,
    this.initialFirstName,
    this.initialSecondName,
    this.initialLastName,
    this.initialGender,
    this.initialBirthDate,
    this.initialDiabetesType,
    this.initialDiagnosisDate,
    this.initialNotes,
    this.initialImagePath,
  });

  @override
  State<ChildInfoScreen> createState() =>
      _ChildInfoScreenState();
}

class _ChildInfoScreenState extends State<ChildInfoScreen> {
  final GlobalKey<FormState> formKey =
  GlobalKey<FormState>();

  final GlobalKey imageKey = GlobalKey();

  final TextEditingController firstNameController =
  TextEditingController();

  final TextEditingController secondNameController =
  TextEditingController();

  final TextEditingController lastNameController =
  TextEditingController();

  final TextEditingController notesController =
  TextEditingController();

  final TextEditingController customDiabetesTypeController =
  TextEditingController();

  final FocusNode firstNameFocusNode = FocusNode();
  final FocusNode secondNameFocusNode = FocusNode();
  final FocusNode lastNameFocusNode = FocusNode();

  final FocusNode customDiabetesTypeFocusNode =
  FocusNode();

  final ImagePicker imagePicker = ImagePicker();

  XFile? selectedImage;

  String? selectedGender;
  String? selectedDiabetesType;

  DateTime? birthDate;
  DateTime? diagnosisDate;

  bool isOtherDiabetesType = false;
  bool isSaving = false;

  // هل اختار ولي الأمر صورة جديدة؟
  bool imageChanged = false;

  String? genderError;
  String? birthDateError;
  String? diabetesTypeError;
  String? diagnosisDateError;

  // =====================================
  // Initial Data
  // =====================================

  @override
  void initState() {
    super.initState();

    if (widget.isEditMode) {
      if (widget.initialImagePath != null &&
          widget.initialImagePath!.isNotEmpty &&
          File(widget.initialImagePath!).existsSync()) {
        selectedImage = XFile(widget.initialImagePath!);
      }

      firstNameController.text =
          widget.initialFirstName ?? '';

      secondNameController.text =
          widget.initialSecondName ?? '';

      lastNameController.text =
          widget.initialLastName ?? '';

      notesController.text =
          widget.initialNotes ?? '';

      selectedGender = widget.initialGender;
      birthDate = widget.initialBirthDate;
      diagnosisDate = widget.initialDiagnosisDate;

      final String type =
          widget.initialDiabetesType?.trim() ?? '';

      if (type == 'النوع الأول' ||
          type == 'النوع الثاني') {
        selectedDiabetesType = type;
      } else if (type.isNotEmpty) {
        isOtherDiabetesType = true;
        customDiabetesTypeController.text = type;
      }
    }
  }

  // =====================================
  // Validation
  // =====================================

  bool validateGender() {
    setState(() {
      genderError = selectedGender == null
          ? 'يجب اختيار جنس الطفل'
          : null;
    });

    return genderError == null;
  }

  bool validateBirthDate() {
    setState(() {
      if (birthDate == null) {
        birthDateError = 'يجب اختيار تاريخ الميلاد';
      } else if (!Validators.isChildAgeValid(birthDate!)) {
        birthDateError = 'العمر من سنة إلى 12 سنة';
      } else {
        birthDateError = null;
      }
    });

    return birthDateError == null;
  }

  bool validateDiabetesType() {
    setState(() {
      if (isOtherDiabetesType) {
        diabetesTypeError =
        customDiabetesTypeController.text.trim().isEmpty
            ? 'اكتب نوع السكري'
            : null;
      } else {
        diabetesTypeError = selectedDiabetesType == null
            ? 'يجب اختيار نوع السكري'
            : null;
      }
    });

    return diabetesTypeError == null;
  }

  bool validateDiagnosisDate() {
    setState(() {
      if (diagnosisDate == null) {
        diagnosisDateError = 'يجب اختيار تاريخ الإصابة';
        return;
      }

      if (birthDate == null) {
        diagnosisDateError = 'اختر تاريخ الميلاد أولاً';
        return;
      }

      if (diagnosisDate!.isBefore(birthDate!)) {
        diagnosisDateError =
        'التاريخ قبل الميلاد غير مسموح';
        return;
      }

      final now = DateTime.now();

      final today = DateTime(
        now.year,
        now.month,
        now.day,
      );

      if (diagnosisDate!.isAfter(today)) {
        diagnosisDateError =
        'لا يمكن اختيار تاريخ مستقبلي';
        return;
      }

      diagnosisDateError = null;
    });

    return diagnosisDateError == null;
  }

  // =====================================
  // Birth Date
  // =====================================

  Future<void> selectBirthDate() async {
    final earliestDate =
    Validators.earliestChildBirthDate();

    final latestDate =
    Validators.latestChildBirthDate();

    DateTime initialDate = birthDate ??
        DateTime(
          DateTime.now().year - 5,
          DateTime.now().month,
          DateTime.now().day,
        );

    if (initialDate.isBefore(earliestDate)) {
      initialDate = earliestDate;
    }

    if (initialDate.isAfter(latestDate)) {
      initialDate = latestDate;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: earliestDate,
      lastDate: latestDate,
      helpText: 'اختر تاريخ الميلاد',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      birthDate = selectedDate;
      birthDateError = null;

      if (diagnosisDate != null &&
          diagnosisDate!.isBefore(selectedDate)) {
        diagnosisDate = null;
        diagnosisDateError = null;
      }
    });
  }

  // =====================================
  // Diagnosis Date
  // =====================================

  Future<void> selectDiagnosisDate() async {
    if (birthDate == null) {
      setState(() {
        birthDateError = 'اختر تاريخ الميلاد أولاً';
      });

      showTemporaryMessage(
        'اختر تاريخ ميلاد الطفل أولاً',
      );

      return;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final firstAllowedDate = DateTime(
      birthDate!.year,
      birthDate!.month,
      birthDate!.day,
    );

    DateTime initialDate = diagnosisDate ?? today;

    if (initialDate.isBefore(firstAllowedDate)) {
      initialDate = firstAllowedDate;
    }

    if (initialDate.isAfter(today)) {
      initialDate = today;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstAllowedDate,
      lastDate: today,
      helpText: 'اختر تاريخ الإصابة بالمرض',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      diagnosisDate = selectedDate;
      diagnosisDateError = null;
    });
  }

  // =====================================
  // Diabetes Type
  // =====================================

  void selectOtherDiabetesType() {
    setState(() {
      selectedDiabetesType = null;
      isOtherDiabetesType = true;
      customDiabetesTypeController.clear();
      diabetesTypeError = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        customDiabetesTypeFocusNode.requestFocus();
      }
    });
  }

  void returnToDiabetesOptions() {
    FocusScope.of(context).unfocus();

    setState(() {
      isOtherDiabetesType = false;
      selectedDiabetesType = null;
      customDiabetesTypeController.clear();
      diabetesTypeError = null;
    });
  }

  String get finalDiabetesType {
    if (isOtherDiabetesType) {
      return customDiabetesTypeController.text.trim();
    }

    return selectedDiabetesType ?? '';
  }

  // =====================================
  // Image Options
  // =====================================

  Future<void> showImageOptions() async {
    if (isSaving) return;

    final imageBox =
    imageKey.currentContext?.findRenderObject()
    as RenderBox?;

    final overlayBox =
    Overlay.of(context).context.findRenderObject()
    as RenderBox?;

    if (imageBox == null || overlayBox == null) return;

    final imagePosition = imageBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );

    final imageRect = Rect.fromLTWH(
      imagePosition.dx,
      imagePosition.dy,
      imageBox.size.width,
      imageBox.size.height,
    );

    final overlayRect = Offset.zero & overlayBox.size;

    final theme = Theme.of(context);

    final String? option = await showMenu<String>(
      context: context,
      color: theme.cardColor,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      position: RelativeRect.fromRect(
        imageRect.shift(const Offset(-140, 50)),
        overlayRect,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'gallery',
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xff64C7C4),
                ),
                const SizedBox(width: 10),
                Text(
                  'اختيار من المعرض',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),

        PopupMenuItem<String>(
          value: 'camera',
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xff64C7C4),
                ),
                const SizedBox(width: 10),
                Text(
                  'استخدام الكاميرا',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!mounted || option == null) return;

    if (option == 'gallery') {
      await pickChildImage(ImageSource.gallery);
    } else if (option == 'camera') {
      await pickChildImage(ImageSource.camera);
    }
  }

  Future<void> pickChildImage(ImageSource source) async {
    if (isSaving) return;

    try {
      final XFile? image = await imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image == null || !mounted) return;

      setState(() {
        selectedImage = image;

        // صورة جديدة تم اختيارها
        imageChanged = true;
      });

      showTemporaryMessage(
        source == ImageSource.camera
            ? 'تم التقاط الصورة بنجاح'
            : 'تم اختيار الصورة بنجاح',
      );
    } catch (error) {
      debugPrint('Image selection error: $error');

      if (mounted) {
        showTemporaryMessage(
          source == ImageSource.camera
              ? 'تعذر فتح الكاميرا، تحققي من أذونات الجهاز'
              : 'تعذر فتح المعرض، حاولي مرة أخرى',
        );
      }
    }
  }

  // =====================================
  // Date Formatting
  // =====================================

  String formatDate(DateTime? date) {
    if (date == null) return '';

    final day =
    date.day.toString().padLeft(2, '0');

    final month =
    date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // =====================================
  // Messages
  // =====================================

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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // =====================================
  // Save Child Information
  // Laravel API + ChildStore
  // =====================================

  Future<void> saveChildInformation() async {
    if (isSaving) return;

    FocusScope.of(context).unfocus();

    final bool formIsValid =
        formKey.currentState?.validate() ?? false;

    final bool genderIsValid = validateGender();
    final bool birthDateIsValid = validateBirthDate();
    final bool diabetesTypeIsValid = validateDiabetesType();
    final bool diagnosisDateIsValid =
    validateDiagnosisDate();

    if (!formIsValid ||
        !genderIsValid ||
        !birthDateIsValid ||
        !diabetesTypeIsValid ||
        !diagnosisDateIsValid) {
      return;
    }

    final String firstName =
    firstNameController.text.trim();

    final String secondName =
    secondNameController.text.trim();

    final String lastName =
    lastNameController.text.trim();

    final String notes =
    notesController.text.trim();

    final childData = <String, dynamic>{
      'firstName': firstName,
      'middleName': secondName,
      'lastName': lastName,
      'gender': selectedGender!,
      'birthDate': birthDate!,
      'diabetesType': finalDiabetesType,
      'diagnosisDate': diagnosisDate!,
      'notes': notes,
      'imagePath': imageChanged
          ? selectedImage?.path
          : widget.initialImagePath,
    };

    // التأكد من معرف الطفل عند التعديل
    if (widget.isEditMode && widget.childId == null) {
      showTemporaryMessage(
        'تعذر تحديد الطفل المطلوب تعديله.',
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      // =====================================
      // تعديل طفل موجود في Laravel
      // =====================================

      if (widget.isEditMode) {
        await ChildService.updateChild(
          childId: widget.childId!,
          firstName: firstName,
          middleName: secondName,
          lastName: lastName,
          gender: selectedGender!,
          birthDate: birthDate!,
          diabetesType: finalDiabetesType,
          diagnosisDate: diagnosisDate!,
          notes: notes,
          imagePath: imageChanged
              ? selectedImage?.path
              : null,
        );

        if (!mounted) return;

        // الرجوع للملف الشخصي بعد نجاح الحفظ
        Navigator.pop(context, childData);
        return;
      }

      // =====================================
      // إضافة طفل جديد في Laravel
      // =====================================

      final Map<String, dynamic> result =
      await ChildService.addChild(
        firstName: firstName,
        middleName: secondName,
        lastName: lastName,
        gender: selectedGender!,
        birthDate: birthDate!,
        diabetesType: finalDiabetesType,
        diagnosisDate: diagnosisDate!,
        notes: notes,
        imagePath: selectedImage?.path,
      );

      if (!mounted) return;

      // جلب child_id الحقيقي من Laravel
      final savedChild =
      result['child'] as Map<String, dynamic>;

      final int? serverId = int.tryParse(
        savedChild['child_id'].toString(),
      );

      if (serverId == null) {
        throw Exception(
          'تم استلام بيانات طفل بدون معرّف صحيح.',
        );
      }

      // =====================================
      // حفظ الطفل في ChildStore
      // لتحديث الواجهات الحالية
      // =====================================

      final child = ChildModel(
        id: serverId,
        localId: 'server:$serverId',
        firstName: firstName,
        middleName: secondName,
        lastName: lastName,
        gender: selectedGender!,
        birthDate: birthDate!,
        imagePath: selectedImage?.path,
        diabetesType: finalDiabetesType,
        diagnosisDate: diagnosisDate,
        notes: notes,
      );

      ChildStore.instance.addChild(child);

      // =====================================
      // إضافة الطفل من الملف الشخصي
      // =====================================

      if (widget.returnToProfileAfterSave) {
        Navigator.pop(context, childData);
        return;
      }

      // =====================================
      // الانتقال إلى الواجهة الرئيسية
      // =====================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainNavigationScreen(
            childName: child.fullName,
            birthDate: child.birthDate,
            gender: child.gender,
            childImagePath: child.imagePath,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final String message = error
          .toString()
          .replaceFirst('Exception: ', '');

      showTemporaryMessage(message);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // =====================================
  // Dispose
  // =====================================

  @override
  void dispose() {
    firstNameController.dispose();
    secondNameController.dispose();
    lastNameController.dispose();
    notesController.dispose();

    customDiabetesTypeController.dispose();

    firstNameFocusNode.dispose();
    secondNameFocusNode.dispose();
    lastNameFocusNode.dispose();
    customDiabetesTypeFocusNode.dispose();

    super.dispose();
  }

  // =====================================
  // Main Screen
  // =====================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final primaryColor = theme.primaryColor;
    final darkColor = theme.colorScheme.onSurface;
    final fieldColor = theme.cardColor;

    final borderColor =
    darkColor.withOpacity(0.14);

    final hintColor =
    darkColor.withOpacity(0.52);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            final isVerySmall = screenWidth < 390;

            final isSmallScreen =
                screenWidth < 430 ||
                    screenHeight < 650;

            final isTablet = screenWidth >= 600;

            final horizontalPadding = isVerySmall
                ? 16.0
                : isTablet
                ? 40.0
                : 22.0;

            final imageSize = isSmallScreen
                ? 95.0
                : isTablet
                ? 125.0
                : 108.0;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                physics:
                const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isSmallScreen ? 14 : 18,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 680,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.center,
                        children: [
                          // =========================
                          // Title
                          // =========================

                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Center(
                                child: Text(
                                  widget.isEditMode
                                      ? 'تعديل بيانات الطفل'
                                      : 'معلومات الطفل',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: darkColor,
                                  ),
                                ),
                              ),

                              if (widget.showBackButton)
                                Align(
                                  alignment:
                                  AlignmentDirectional
                                      .centerStart,
                                  child: IconButton(
                                    onPressed: isSaving
                                        ? null
                                        : () {
                                      Navigator.pop(context);
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints:
                                    const BoxConstraints(
                                      minWidth: 44,
                                      minHeight: 44,
                                    ),
                                    icon: Icon(
                                      Icons
                                          .arrow_back_ios_new_rounded,
                                      color: darkColor,
                                      size: 22,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          SizedBox(
                            height: isSmallScreen ? 15 : 20,
                          ),

                          // =========================
                          // Profile Image
                          // =========================

                          InkWell(
                            key: imageKey,
                            onTap:
                            isSaving ? null : showImageOptions,
                            borderRadius:
                            BorderRadius.circular(
                              imageSize / 2,
                            ),
                            child: Stack(
                              alignment:
                              Alignment.bottomLeft,
                              children: [
                                Container(
                                  width: imageSize,
                                  height: imageSize,
                                  decoration: BoxDecoration(
                                    color: primaryColor
                                        .withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: primaryColor
                                          .withOpacity(0.35),
                                      width: 2,
                                    ),
                                  ),
                                  child: selectedImage != null
                                      ? ClipOval(
                                    child: Image.file(
                                      File(
                                        selectedImage!.path,
                                      ),
                                      width: imageSize,
                                      height: imageSize,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                          ) {
                                        return Icon(
                                          Icons.person_rounded,
                                          size:
                                          imageSize * 0.57,
                                          color: primaryColor,
                                        );
                                      },
                                    ),
                                  )
                                      : Icon(
                                    Icons.person_rounded,
                                    size: imageSize * 0.57,
                                    color: primaryColor,
                                  ),
                                ),

                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: fieldColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    size: 20,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 6),

                          SizedBox(
                            height: isSmallScreen ? 18 : 24,
                          ),

                          // =========================
                          // Names
                          // =========================

                          _buildNameFields(
                            isVerySmall: isVerySmall,
                            primaryColor: primaryColor,
                            borderColor: borderColor,
                            fieldColor: fieldColor,
                            textColor: darkColor,
                            hintColor: hintColor,
                          ),

                          const SizedBox(height: 16),

                          // =========================
                          // Gender
                          // =========================

                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding:
                                const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: fieldColor,
                                  borderRadius:
                                  BorderRadius.circular(14),
                                  border: Border.all(
                                    color: genderError == null
                                        ? borderColor
                                        : Colors.red,
                                    width: genderError == null
                                        ? 1.2
                                        : 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.wc_outlined,
                                      color: primaryColor,
                                      size: 21,
                                    ),

                                    const SizedBox(width: 4),

                                    Text(
                                      'الجنس',
                                      style: TextStyle(
                                        color: hintColor,
                                        fontSize: 13,
                                      ),
                                    ),

                                    const Spacer(),

                                    genderChoice(
                                      title: 'بنت',
                                      icon:
                                      Icons.face_3_rounded,
                                      value: 'بنت',
                                      primaryColor:
                                      primaryColor,
                                      textColor: darkColor,
                                    ),

                                    const SizedBox(width: 12),

                                    genderChoice(
                                      title: 'ولد',
                                      icon:
                                      Icons.face_6_rounded,
                                      value: 'ولد',
                                      primaryColor:
                                      primaryColor,
                                      textColor: darkColor,
                                    ),
                                  ],
                                ),
                              ),

                              if (genderError != null)
                                Padding(
                                  padding:
                                  const EdgeInsets.only(
                                    top: 6,
                                    right: 12,
                                  ),
                                  child: Text(
                                    genderError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // =========================
                          // Birth Date + Diabetes Type
                          // =========================

                          if (isVerySmall)
                            Column(
                              children: [
                                _buildBirthDateField(
                                  primaryColor:
                                  primaryColor,
                                  borderColor:
                                  borderColor,
                                  hintColor: hintColor,
                                  darkColor: darkColor,
                                  fieldColor: fieldColor,
                                ),

                                const SizedBox(height: 16),

                                _buildDiabetesField(
                                  primaryColor:
                                  primaryColor,
                                  borderColor:
                                  borderColor,
                                  hintColor: hintColor,
                                  darkColor: darkColor,
                                  fieldColor: fieldColor,
                                ),
                              ],
                            )
                          else
                            Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildBirthDateField(
                                    primaryColor:
                                    primaryColor,
                                    borderColor:
                                    borderColor,
                                    hintColor: hintColor,
                                    darkColor: darkColor,
                                    fieldColor: fieldColor,
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: _buildDiabetesField(
                                    primaryColor:
                                    primaryColor,
                                    borderColor:
                                    borderColor,
                                    hintColor: hintColor,
                                    darkColor: darkColor,
                                    fieldColor: fieldColor,
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 16),

                          // =========================
                          // Diagnosis Date
                          // =========================

                          InkWell(
                            onTap: isSaving
                                ? null
                                : selectDiagnosisDate,
                            borderRadius:
                            BorderRadius.circular(14),
                            child: InputDecorator(
                              decoration:
                              buildInputDecoration(
                                hint: '',
                                icon: Icons
                                    .event_note_outlined,
                                primaryColor: primaryColor,
                                borderColor: borderColor,
                                fieldColor: fieldColor,
                                hintColor: hintColor,
                                errorText:
                                diagnosisDateError,
                              ),
                              child: Text(
                                diagnosisDate == null
                                    ? 'تاريخ الإصابة بالمرض'
                                    : formatDate(
                                  diagnosisDate,
                                ),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color:
                                  diagnosisDate == null
                                      ? hintColor
                                      : darkColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // =========================
                          // Additional Notes
                          // =========================

                          TextFormField(
                            controller: notesController,
                            enabled: !isSaving,
                            textAlign: TextAlign.right,
                            textDirection:
                            TextDirection.rtl,
                            keyboardType:
                            TextInputType.multiline,
                            minLines: 1,
                            maxLines: 2,
                            style: TextStyle(
                              color: darkColor,
                              fontSize: 14,
                            ),
                            decoration:
                            buildInputDecoration(
                              hint: 'ملاحظات إضافية ',
                              icon: Icons.notes_rounded,
                              primaryColor: primaryColor,
                              borderColor: borderColor,
                              fieldColor: fieldColor,
                              hintColor: hintColor,
                              errorText: null,
                            ).copyWith(
                              contentPadding:
                              const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              alignLabelWithHint: true,
                            ),
                          ),

                          SizedBox(
                            height: isSmallScreen
                                ? 20
                                : 25,
                          ),

                          // =========================
                          // Save Button
                          // =========================

                          SizedBox(
                            width: double.infinity,
                            height: isSmallScreen
                                ? 52
                                : 56,
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : saveChildInformation,
                              child: isSaving
                                  ? const SizedBox(
                                width: 25,
                                height: 25,
                                child:
                                CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                                  : Text(
                                widget.isEditMode
                                    ? 'حفظ التعديلات'
                                    : 'حفظ المعلومات',
                                style: TextStyle(
                                  fontSize:
                                  isSmallScreen
                                      ? 16
                                      : 18,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          if (isSaving) ...[
                            const SizedBox(height: 12),

                            Text(
                              'جاري حفظ المعلومات...',
                              style: TextStyle(
                                fontSize: 14,
                                color: primaryColor,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),
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

  // =====================================
  // Gender Choice
  // =====================================

  Widget genderChoice({
    required String title,
    required IconData icon,
    required String value,
    required Color primaryColor,
    required Color textColor,
  }) {
    final bool isSelected =
        selectedGender == value;

    return InkWell(
      onTap: isSaving
          ? null
          : () {
        setState(() {
          selectedGender = value;
          genderError = null;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.10)
              : Colors.transparent,
          borderRadius:
          BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 19,
              color: isSelected
                  ? primaryColor
                  : textColor.withOpacity(0.65),
            ),

            const SizedBox(width: 4),

            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: isSelected
                    ? primaryColor
                    : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================
  // Name Fields
  // =====================================

  Widget _buildNameFields({
    required bool isVerySmall,
    required Color primaryColor,
    required Color borderColor,
    required Color fieldColor,
    required Color textColor,
    required Color hintColor,
  }) {
    final firstName = _buildNameField(
      controller: firstNameController,
      focusNode: firstNameFocusNode,
      hint: 'الاسم الأول',
      primaryColor: primaryColor,
      borderColor: borderColor,
      fieldColor: fieldColor,
      textColor: textColor,
      hintColor: hintColor,
      nextFocus: secondNameFocusNode,
    );

    final secondName = _buildNameField(
      controller: secondNameController,
      focusNode: secondNameFocusNode,
      hint: 'الاسم الثاني',
      primaryColor: primaryColor,
      borderColor: borderColor,
      fieldColor: fieldColor,
      textColor: textColor,
      hintColor: hintColor,
      nextFocus: lastNameFocusNode,
    );

    final lastName = _buildNameField(
      controller: lastNameController,
      focusNode: lastNameFocusNode,
      hint: 'اللقب',
      primaryColor: primaryColor,
      borderColor: borderColor,
      fieldColor: fieldColor,
      textColor: textColor,
      hintColor: hintColor,
    );

    if (isVerySmall) {
      return Column(
        children: [
          firstName,
          const SizedBox(height: 12),
          secondName,
          const SizedBox(height: 12),
          lastName,
        ],
      );
    }

    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Expanded(child: firstName),
        const SizedBox(width: 7),
        Expanded(child: secondName),
        const SizedBox(width: 7),
        Expanded(child: lastName),
      ],
    );
  }

  Widget _buildNameField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required Color primaryColor,
    required Color borderColor,
    required Color fieldColor,
    required Color textColor,
    required Color hintColor,
    FocusNode? nextFocus,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: !isSaving,
      keyboardType: TextInputType.name,
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        color: textColor,
      ),
      textInputAction: nextFocus == null
          ? TextInputAction.done
          : TextInputAction.next,
      autovalidateMode:
      AutovalidateMode.onUserInteraction,
      validator: Validators.arabicName,
      onFieldSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(
            nextFocus,
          );
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      decoration: nameInputDecoration(
        hint: hint,
        primaryColor: primaryColor,
        borderColor: borderColor,
        fieldColor: fieldColor,
        hintColor: hintColor,
      ),
    );
  }

  // =====================================
  // Birth Date Field
  // =====================================

  Widget _buildBirthDateField({
    required Color primaryColor,
    required Color borderColor,
    required Color hintColor,
    required Color darkColor,
    required Color fieldColor,
  }) {
    return InkWell(
      onTap: isSaving ? null : selectBirthDate,
      borderRadius:
      BorderRadius.circular(14),
      child: InputDecorator(
        decoration: buildInputDecoration(
          hint: '',
          icon: Icons.calendar_month_outlined,
          primaryColor: primaryColor,
          borderColor: borderColor,
          fieldColor: fieldColor,
          hintColor: hintColor,
          errorText: birthDateError,
        ),
        child: Text(
          birthDate == null
              ? 'تاريخ الميلاد'
              : formatDate(birthDate),
          textAlign: TextAlign.right,
          style: TextStyle(
            color: birthDate == null
                ? hintColor
                : darkColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // =====================================
  // Diabetes Field
  // =====================================

  Widget _buildDiabetesField({
    required Color primaryColor,
    required Color borderColor,
    required Color hintColor,
    required Color darkColor,
    required Color fieldColor,
  }) {
    if (isOtherDiabetesType) {
      return TextFormField(
        controller:
        customDiabetesTypeController,
        focusNode:
        customDiabetesTypeFocusNode,
        enabled: !isSaving,
        autofocus: true,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          color: darkColor,
        ),
        autovalidateMode:
        AutovalidateMode.onUserInteraction,
        validator: (value) {
          final text = value?.trim() ?? '';

          if (text.isEmpty) {
            return 'اكتب نوع السكري';
          }

          if (text.length < 2) {
            return 'النص قصير';
          }

          if (text.length > 30) {
            return 'النص طويل';
          }

          final regex = RegExp(
            r'^[A-Za-z\u0621-\u064A0-9 ]+$',
          );

          if (!regex.hasMatch(text)) {
            return 'أدخل حروف وأرقام فقط';
          }

          if (text.contains('  ')) {
            return 'النص غير صحيح';
          }

          return null;
        },
        onChanged: (value) {
          if (value.trim().isNotEmpty) {
            setState(() {
              diabetesTypeError = null;
            });
          }
        },
        decoration: buildInputDecoration(
          hint: 'اكتب نوع السكري',
          icon: Icons.water_drop_outlined,
          primaryColor: primaryColor,
          borderColor: borderColor,
          fieldColor: fieldColor,
          hintColor: hintColor,
          errorText: diabetesTypeError,
        ).copyWith(
          suffixIcon: IconButton(
            tooltip: 'الرجوع للخيارات',
            onPressed: isSaving
                ? null
                : returnToDiabetesOptions,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: darkColor,
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child:
      DropdownButtonFormField<String>(
        value: selectedDiabetesType,
        isExpanded: true,
        dropdownColor: fieldColor,
        style: TextStyle(
          color: darkColor,
          fontSize: 14,
        ),
        alignment:
        AlignmentDirectional.centerStart,
        decoration: buildInputDecoration(
          hint: 'نوع السكري',
          icon: Icons.water_drop_outlined,
          primaryColor: primaryColor,
          borderColor: borderColor,
          fieldColor: fieldColor,
          hintColor: hintColor,
          errorText: diabetesTypeError,
        ),
        hint: Text(
          'نوع السكري',
          textAlign: TextAlign.right,
          style: TextStyle(
            color: hintColor,
            fontSize: 14,
          ),
        ),
        items: const [
          DropdownMenuItem<String>(
            value: 'النوع الأول',
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('النوع الأول'),
            ),
          ),
          DropdownMenuItem<String>(
            value: 'النوع الثاني',
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('النوع الثاني'),
            ),
          ),
          DropdownMenuItem<String>(
            value: 'نوع آخر',
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('نوع آخر'),
            ),
          ),
        ],
        onChanged: isSaving
            ? null
            : (value) {
          if (value == 'نوع آخر') {
            selectOtherDiabetesType();
            return;
          }

          setState(() {
            selectedDiabetesType = value;
            diabetesTypeError = null;
          });
        },
      ),
    );
  }

  // =====================================
  // Name Input Decoration
  // =====================================

  InputDecoration nameInputDecoration({
    required String hint,
    required Color primaryColor,
    required Color borderColor,
    required Color fieldColor,
    required Color hintColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      hintStyle: TextStyle(
        color: hintColor,
        fontSize: 12,
      ),
      errorStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: fieldColor,
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 17,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
        borderSide: BorderSide(
          color: borderColor,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
        borderSide: BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.2,
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }

  // =====================================
  // General Input Decoration
  // =====================================

  InputDecoration buildInputDecoration({
    required String hint,
    required IconData icon,
    required Color primaryColor,
    required Color borderColor,
    required Color fieldColor,
    required Color hintColor,
    required String? errorText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      hintStyle: TextStyle(
        color: hintColor,
        fontSize: 14,
      ),
      errorText: errorText,
      errorStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        icon,
        color: primaryColor,
      ),
      filled: true,
      fillColor: fieldColor,
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: BorderSide(
          color: borderColor,
          width: 1.3,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.3,
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }
}
