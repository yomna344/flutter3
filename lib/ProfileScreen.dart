
import 'dart:io';

import 'package:flutter/material.dart';

import 'ChildInfoScreen.dart';
import 'SettingScreen.dart';
import 'LoginScreen.dart';
import 'validators.dart';
import 'ChildStore.dart';

class ProfileScreen extends StatefulWidget {
  final String childName;
  final DateTime birthDate;
  final String gender;
  final String? childImagePath;

  final String? guardianFirstName;
  final String? guardianMiddleName;
  final String? guardianLastName;
  final String? guardianPhone;

  const ProfileScreen({
    super.key,
    required this.childName,
    required this.birthDate,
    required this.gender,
    this.childImagePath,
    this.guardianFirstName,
    this.guardianMiddleName,
    this.guardianLastName,
    this.guardianPhone,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GlobalKey<FormState> guardianFormKey =
  GlobalKey<FormState>();

  late final TextEditingController firstNameController;
  late final TextEditingController middleNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController phoneController;

  bool isEditingGuardian = false;
  bool isSavingGuardian = false;

  late String guardianFirstName;
  late String guardianMiddleName;
  late String guardianLastName;
  late String guardianPhone;

  ChildStore get store => ChildStore.instance;

  @override
  void initState() {
    super.initState();

    guardianFirstName =
        widget.guardianFirstName?.trim() ?? '';

    guardianMiddleName =
        widget.guardianMiddleName?.trim() ?? '';

    guardianLastName =
        widget.guardianLastName?.trim() ?? '';

    guardianPhone =
        widget.guardianPhone?.trim() ?? '';

    firstNameController =
        TextEditingController(text: guardianFirstName);

    middleNameController =
        TextEditingController(text: guardianMiddleName);

    lastNameController =
        TextEditingController(text: guardianLastName);

    phoneController =
        TextEditingController(text: guardianPhone);

    // لا ننشئ نسخة إضافية إذا كان الطفل موجودًا.
    ChildModel? existingChild;

    for (final child in store.children) {
      if (_sameChild(
        child,
        widget.childName,
        widget.gender,
        widget.birthDate,
      )) {
        existingChild = child;
        break;
      }
    }

    if (existingChild != null) {
      store.selectChild(existingChild.localId);
    } else if (store.children.isEmpty) {
      // توافق مؤقت مع الشاشات المحلية القديمة.
      store.addChild(
        ChildModel(
          localId:
          DateTime.now().microsecondsSinceEpoch.toString(),
          firstName: widget.childName,
          gender: widget.gender,
          birthDate: widget.birthDate,
          imagePath: widget.childImagePath,
        ),
      );
    }
  }

  // =====================================
  // مقارنة بيانات الأطفال
  // =====================================

  bool _sameChild(
      ChildModel child,
      String fullName,
      String gender,
      DateTime birthDate,
      ) {
    return child.fullName.trim().toLowerCase() ==
        fullName.trim().toLowerCase() &&
        child.gender.trim() == gender.trim() &&
        DateUtils.isSameDay(
          child.birthDate,
          birthDate,
        );
  }

  List<ChildModel> _uniqueChildren(
      List<ChildModel> source,
      ) {
    final unique = <ChildModel>[];

    for (final child in source) {
      final duplicate = unique.any(
            (existing) => _sameChild(
          existing,
          child.fullName,
          child.gender,
          child.birthDate,
        ),
      );

      if (!duplicate) {
        unique.add(child);
      }
    }

    return unique;
  }

  // =====================================
  // حساب العمر
  // =====================================

  int calculateAge(DateTime dateOfBirth) {
    final today = DateTime.now();

    int age = today.year - dateOfBirth.year;

    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month &&
            today.day < dateOfBirth.day)) {
      age--;
    }

    return age;
  }

  // =====================================
  // معلومات ولي الأمر
  // =====================================

  String get guardianFullName {
    final names = [
      guardianFirstName,
      guardianMiddleName,
      guardianLastName,
    ].where((name) => name.trim().isNotEmpty).toList();

    return names.isEmpty
        ? 'بيانات ولي الأمر'
        : names.join(' ');
  }

  String get guardianPhoneText {
    if (guardianPhone.isEmpty) {
      return 'رقم الهاتف سيظهر بعد ربط الحساب';
    }

    return '+${Validators.cleanPhoneNumber(guardianPhone)}';
  }

  // =====================================
  // الرسائل
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // =====================================
  // اختيار الطفل
  // =====================================

  void selectChild(ChildModel child) {
    if (store.selectedChild?.localId == child.localId) {
      return;
    }

    store.selectChild(child.localId);

    showTemporaryMessage(
      'تم اختيار ${child.fullName}',
    );
  }

  // =====================================
  // إضافة طفل
  // =====================================

  Future<void> addChild() async {
    final result =
    await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const ChildInfoScreen(
          showBackButton: true,
          returnToProfileAfterSave: true,
        ),
      ),
    );

    if (!mounted || result == null) return;

    // ChildInfoScreen يضيف الطفل إلى ChildStore.
    setState(() {});

    showTemporaryMessage(
      'تمت إضافة الطفل بنجاح',
    );
  }

  // =====================================
  // تعديل بيانات طفل
  // =====================================

  Future<void> editChild(ChildModel child) async {
    final result =
    await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ChildInfoScreen(
          childId: child.id,
          showBackButton: true,
          isEditMode: true,
          initialFirstName: child.firstName,
          initialSecondName: child.middleName,
          initialLastName: child.lastName,
          initialGender: child.gender,
          initialBirthDate: child.birthDate,
          initialDiabetesType: child.diabetesType,
          initialDiagnosisDate: child.diagnosisDate,
          initialNotes: child.notes,
          initialImagePath: child.imagePath,
        ),
      ),
    );

    if (!mounted || result == null) return;

    // يتم تحديث بيانات Flutter بعد نجاح Laravel.
    final updatedChild = ChildModel(
      id: child.id,
      localId: child.localId,
      firstName:
      (result['firstName'] ?? child.firstName).toString(),
      middleName:
      (result['middleName'] ?? child.middleName).toString(),
      lastName:
      (result['lastName'] ?? child.lastName).toString(),
      gender:
      (result['gender'] ?? child.gender).toString(),
      birthDate:
      result['birthDate'] as DateTime? ??
          child.birthDate,
      imagePath: result.containsKey('imagePath')
          ? result['imagePath'] as String?
          : child.imagePath,

      // الحفاظ على صورة Laravel أثناء تعديل البيانات.
      serverImagePath: child.serverImagePath,

      diabetesType:
      (result['diabetesType'] ?? child.diabetesType)
          .toString(),
      diagnosisDate:
      result['diagnosisDate'] as DateTime? ??
          child.diagnosisDate,
      notes:
      (result['notes'] ?? child.notes).toString(),
    );

    store.updateChild(updatedChild);

    setState(() {});

    showTemporaryMessage(
      'تم حفظ بيانات الطفل',
    );
  }

  // =====================================
  // تعديل بيانات ولي الأمر
  // =====================================

  void startEditingGuardian() {
    setState(() {
      firstNameController.text = guardianFirstName;
      middleNameController.text = guardianMiddleName;
      lastNameController.text = guardianLastName;
      phoneController.text = guardianPhone;
      isEditingGuardian = true;
    });
  }

  void cancelEditingGuardian() {
    FocusScope.of(context).unfocus();

    setState(() {
      firstNameController.text = guardianFirstName;
      middleNameController.text = guardianMiddleName;
      lastNameController.text = guardianLastName;
      phoneController.text = guardianPhone;
      isEditingGuardian = false;
    });
  }

  Future<void> saveGuardianInformation() async {
    if (isSavingGuardian) return;

    FocusScope.of(context).unfocus();

    if (!(guardianFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => isSavingGuardian = true);

    // بيانات ولي الأمر لم يتم ربط تعديلها بعد.
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      guardianFirstName = firstNameController.text.trim();
      guardianMiddleName = middleNameController.text.trim();
      guardianLastName = lastNameController.text.trim();

      guardianPhone =
          Validators.cleanPhoneNumber(phoneController.text);

      isSavingGuardian = false;
      isEditingGuardian = false;
    });

    showTemporaryMessage(
      'تم حفظ التغييرات',
    );
  }

  // =====================================
  // حقول ولي الأمر
  // =====================================

  Widget _nameField(
      TextEditingController controller,
      String hint,
      Color primaryColor,
      ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.name,
      textAlign: TextAlign.right,
      autovalidateMode:
      AutovalidateMode.onUserInteraction,
      validator: Validators.arabicName,
      decoration: _inputDecoration(
        hint,
        Icons.person_outline_rounded,
        primaryColor,
      ),
    );
  }

  InputDecoration _inputDecoration(
      String hint,
      IconData icon,
      Color primaryColor,
      ) {
    final textColor =
        Theme.of(context).colorScheme.onSurface;

    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      prefixIcon: Icon(
        icon,
        color: primaryColor,
      ),
      filled: true,
      fillColor: Theme.of(context).cardColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: textColor.withOpacity(0.15),
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
    );
  }

  // =====================================
  // الإعدادات
  // =====================================

  void openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  // =====================================
  // تسجيل الخروج
  // =====================================

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'تسجيل الخروج',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xff2C4A5A),
            ),
          ),
          content: const Text(
            'هل تريد تسجيل الخروج من الحساب؟',
            style: TextStyle(
              color: Color(0xff5C6E75),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    store.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  // =====================================
  // التخلص من Controllers
  // =====================================

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  // =====================================
  // واجهة الملف الشخصي
  // =====================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final primaryColor = theme.primaryColor;
    final textColor = theme.colorScheme.onSurface;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: AnimatedBuilder(
            animation: store,
            builder: (context, _) {
              final children =
              _uniqueChildren(store.children);

              final current = store.selectedChild;

              final width =
                  MediaQuery.of(context).size.width;

              final isVerySmall = width < 390;
              final isTablet = width >= 600;

              final horizontalPadding = isVerySmall
                  ? 15.0
                  : isTablet
                  ? 40.0
                  : 20.0;

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
                      CrossAxisAlignment.stretch,
                      children: [
                        // =====================================
                        // العنوان
                        // =====================================

                        Text(
                          'الملف الشخصي',
                          style: TextStyle(
                            fontSize: isTablet ? 31 : 27,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'إدارة حسابك وبيانات أطفالك',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor.withOpacity(0.65),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // =====================================
                        // بيانات ولي الأمر
                        // =====================================

                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: isEditingGuardian
                              ? Form(
                            key: guardianFormKey,
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تعديل بيانات ولي الأمر',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                if (isVerySmall) ...[
                                  _nameField(
                                    firstNameController,
                                    'الاسم الأول',
                                    primaryColor,
                                  ),
                                  const SizedBox(height: 12),
                                  _nameField(
                                    middleNameController,
                                    'الاسم الثاني',
                                    primaryColor,
                                  ),
                                  const SizedBox(height: 12),
                                  _nameField(
                                    lastNameController,
                                    'اللقب',
                                    primaryColor,
                                  ),
                                ] else
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _nameField(
                                          firstNameController,
                                          'الاسم الأول',
                                          primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: _nameField(
                                          middleNameController,
                                          'الاسم الثاني',
                                          primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: _nameField(
                                          lastNameController,
                                          'اللقب',
                                          primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),

                                const SizedBox(height: 14),

                                TextFormField(
                                  controller: phoneController,
                                  keyboardType:
                                  TextInputType.phone,
                                  textAlign: TextAlign.right,
                                  autovalidateMode:
                                  AutovalidateMode
                                      .onUserInteraction,
                                  validator:
                                  Validators.supportedPhone,
                                  decoration: _inputDecoration(
                                    'رقم الهاتف',
                                    Icons.phone_outlined,
                                    primaryColor,
                                  ),
                                ),

                                const SizedBox(height: 18),

                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: isSavingGuardian
                                            ? null
                                            : saveGuardianInformation,
                                        child: isSavingGuardian
                                            ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child:
                                          CircularProgressIndicator(
                                            strokeWidth: 2.3,
                                          ),
                                        )
                                            : const Text(
                                          'حفظ التغييرات',
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: isSavingGuardian
                                          ? null
                                          : cancelEditingGuardian,
                                      child: const Text('إلغاء'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                              : Row(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundColor:
                                primaryColor.withOpacity(0.12),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: primaryColor,
                                  size: 39,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      guardianFullName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      guardianPhoneText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textColor
                                            .withOpacity(0.65),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              IconButton(
                                onPressed: startEditingGuardian,
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),

                        // =====================================
                        // قسم الأطفال
                        // =====================================

                        Row(
                          children: [
                            Icon(
                              Icons.family_restroom_rounded,
                              color: primaryColor,
                              size: 23,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'أطفالي',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (children.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'لا توجد بيانات أطفال حتى الآن',
                              textAlign: TextAlign.center,
                            ),
                          ),

                        // =====================================
                        // بطاقات الأطفال
                        // =====================================

                        ...children.map((child) {
                          final isSelected =
                              current?.localId == child.localId;

                          final age =
                          calculateAge(child.birthDate);

                          return Container(
                            key: ValueKey(child.localId),
                            margin:
                            const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius:
                              BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : textColor.withOpacity(0.12),
                                width: isSelected ? 1.8 : 1.2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // صورة الطفل المحلية أو صورة Laravel
                                    Container(
                                      width: 65,
                                      height: 65,
                                      decoration: BoxDecoration(
                                        color: primaryColor
                                            .withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: _buildChildImage(
                                        child,
                                        primaryColor,
                                      ),
                                    ),

                                    const SizedBox(width: 13),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            child.fullName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight:
                                              FontWeight.bold,
                                            ),
                                          ),

                                          const SizedBox(height: 7),

                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 6,
                                            children: [
                                              _smallInfo(
                                                Icons
                                                    .calendar_month_outlined,
                                                '$age سنوات',
                                                primaryColor,
                                              ),

                                              _smallInfo(
                                                child.gender == 'بنت'
                                                    ? Icons.female
                                                    : Icons.male,
                                                child.gender,
                                                primaryColor,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    IconButton(
                                      tooltip: 'تعديل بيانات الطفل',
                                      onPressed: () => editChild(child),
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                SizedBox(
                                  width: double.infinity,
                                  child: isSelected
                                      ? OutlinedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                    ),
                                    label: const Text(
                                      'الطفل المحدد حاليًا',
                                    ),
                                  )
                                      : ElevatedButton.icon(
                                    onPressed: () =>
                                        selectChild(child),
                                    icon: const Icon(
                                      Icons.swap_horiz_rounded,
                                    ),
                                    label: const Text(
                                      'اختيار هذا الطفل',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 4),

                        OutlinedButton.icon(
                          onPressed: addChild,
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                          ),
                          label: const Text('إضافة طفل'),
                        ),

                        const SizedBox(height: 28),

                        // =====================================
                        // الإعدادات وتسجيل الخروج
                        // =====================================

                        _profileOption(
                          icon: Icons.settings_outlined,
                          title: 'الإعدادات',
                          subtitle:
                          'الوضع الداكن، الإشعارات، الأمان والخصوصية',
                          primaryColor: primaryColor,
                          onTap: openSettings,
                        ),

                        const SizedBox(height: 12),

                        _profileOption(
                          icon: Icons.logout_rounded,
                          title: 'تسجيل الخروج',
                          subtitle: '',
                          primaryColor: primaryColor,
                          isDanger: true,
                          onTap: logout,
                        ),

                        const SizedBox(height: 25),
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

  // =====================================
  // عرض صورة الطفل
  // =====================================

  Widget _buildChildImage(
      ChildModel child,
      Color primaryColor,
      ) {
    final String? localPath = child.imagePath;

    // أولًا: صورة محفوظة داخل الجهاز
    if (localPath != null &&
        localPath.trim().isNotEmpty &&
        File(localPath).existsSync()) {
      return ClipOval(
        child: Image.file(
          File(localPath),
          width: 65,
          height: 65,
          fit: BoxFit.cover,
          errorBuilder: (
              context,
              error,
              stackTrace,
              ) {
            return _childFallback(
              child,
              primaryColor,
            );
          },
        ),
      );
    }

    // ثانيًا: صورة محفوظة على Laravel
    final String? imageUrl = child.imageUrl;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 65,
          height: 65,
          fit: BoxFit.cover,
          loadingBuilder: (
              context,
              image,
              loadingProgress,
              ) {
            if (loadingProgress == null) {
              return image;
            }

            return Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryColor,
                ),
              ),
            );
          },
          errorBuilder: (
              context,
              error,
              stackTrace,
              ) {
            return _childFallback(
              child,
              primaryColor,
            );
          },
        ),
      );
    }

    // ثالثًا: الصورة الافتراضية
    return _childFallback(
      child,
      primaryColor,
    );
  }

  // =====================================
  // الصورة الافتراضية
  // =====================================

  Widget _childFallback(
      ChildModel child,
      Color primaryColor,
      ) {
    return Icon(
      child.gender == 'بنت'
          ? Icons.face_3_rounded
          : Icons.face_6_rounded,
      size: 36,
      color: primaryColor,
    );
  }

  // =====================================
  // معلومات الطفل المختصرة
  // =====================================

  Widget _smallInfo(
      IconData icon,
      String text,
      Color primaryColor,
      ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 17,
          color: primaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withOpacity(0.65),
          ),
        ),
      ],
    );
  }

  // =====================================
  // خيارات الملف الشخصي
  // =====================================

  Widget _profileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final textColor =
        Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: textColor.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isDanger
                    ? Colors.red.withOpacity(0.08)
                    : primaryColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color:
                isDanger ? Colors.red : primaryColor,
                size: 25,
              ),
            ),

            const SizedBox(width: 13),

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
                      color:
                      isDanger ? Colors.red : textColor,
                    ),
                  ),

                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                        textColor.withOpacity(0.55),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (!isDanger)
              Icon(
                Icons.arrow_back_ios_new_rounded,
                textDirection: TextDirection.ltr,
                size: 16,
                color:
                textColor.withOpacity(0.45),
              ),
          ],
        ),
      ),
    );
  }
}
