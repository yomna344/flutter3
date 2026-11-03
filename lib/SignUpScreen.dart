
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'LoginScreen.dart';
import 'ChildInfoScreen.dart';
import 'validators.dart';
import 'services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController =
  TextEditingController();

  final TextEditingController secondNameController =
  TextEditingController();

  final TextEditingController lastNameController =
  TextEditingController();

  final TextEditingController phoneController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  final FocusNode firstNameFocusNode = FocusNode();
  final FocusNode secondNameFocusNode = FocusNode();
  final FocusNode lastNameFocusNode = FocusNode();
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  bool obscurePassword = true;
  bool isPasswordFocused = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    passwordFocusNode.addListener(() {
      if (!mounted) return;

      setState(() {
        isPasswordFocused = passwordFocusNode.hasFocus;
      });
    });
  }

  // =====================================
  // إنشاء حساب ولي الأمر عبر Laravel
  // =====================================

  Future<void> createAccount() async {
    FocusScope.of(context).unfocus();

    if (isLoading) return;

    final bool isValid =
        formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    setState(() {
      isLoading = true;
    });

    try {
      // إرسال بيانات التسجيل إلى Laravel
      final Map<String, dynamic> result =
      await AuthService.register(
        firstName: firstNameController.text.trim(),
        middleName: secondNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
      );

      // استلام Token بعد نجاح التسجيل
      final String token = result['token'] as String;

      // حفظ Token بأمان
      const FlutterSecureStorage storage =
      FlutterSecureStorage();

      await storage.write(
        key: 'auth_token',
        value: token,
      );

      if (!mounted) return;

      // الانتقال بعد نجاح التسجيل الحقيقي
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ChildInfoScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final String message = error
          .toString()
          .replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // =====================================
  // الانتقال إلى تسجيل الدخول
  // =====================================

  void goToLogin() {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    firstNameController.dispose();
    secondNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    passwordController.dispose();

    firstNameFocusNode.dispose();
    secondNameFocusNode.dispose();
    lastNameFocusNode.dispose();
    phoneFocusNode.dispose();
    passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color primaryColor = theme.primaryColor;

    final Color textColor = isDark
        ? Colors.white
        : const Color(0xff2C4A5A);

    final Color hintColor = isDark
        ? Colors.white60
        : const Color(0xff9AA7AB);

    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.18)
        : const Color(0xffD7E7E7);

    final Color fieldColor = isDark
        ? const Color(0xff1D292D)
        : Colors.white;

    final Color secondaryColor = isDark
        ? const Color(0xff1D292D)
        : Colors.white;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth = constraints.maxWidth;
            final double screenHeight = constraints.maxHeight;

            final bool isSmallScreen =
                screenWidth < 360 || screenHeight < 650;

            final bool isTablet = screenWidth >= 600;

            final double horizontalPadding = isSmallScreen
                ? 16
                : isTablet
                ? 40
                : 22;

            final double imageHeight = isSmallScreen
                ? 125
                : isTablet
                ? 190
                : 160;

            final double titleSize = isSmallScreen
                ? 24
                : isTablet
                ? 32
                : 28;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isSmallScreen ? 10 : 14,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 460,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.center,
                        children: [
                          // =========================
                          // Image
                          // =========================

                          Image.asset(
                            'images/logoprojj.png',
                            width: double.infinity,
                            height: imageHeight,
                            fit: BoxFit.contain,
                          ),

                          SizedBox(
                            height: isSmallScreen ? 8 : 14,
                          ),

                          // =========================
                          // Title
                          // =========================

                          Text(
                            'إنشاء حساب جديد',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: titleSize,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),

                          SizedBox(
                            height: isSmallScreen ? 18 : 25,
                          ),

                          // =========================
                          // Names
                          // =========================

                          Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: firstNameController,
                                  focusNode: firstNameFocusNode,
                                  enabled: !isLoading,
                                  style: TextStyle(
                                    color: textColor,
                                  ),
                                  cursorColor: primaryColor,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.name,
                                  textInputAction: TextInputAction.next,
                                  autovalidateMode:
                                  AutovalidateMode
                                      .onUserInteraction,
                                  validator: Validators.arabicName,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context)
                                        .requestFocus(
                                      secondNameFocusNode,
                                    );
                                  },
                                  decoration: nameInputDecoration(
                                    hint: 'الاسم الأول',
                                    primaryColor: primaryColor,
                                    borderColor: borderColor,
                                    fieldColor: fieldColor,
                                    hintColor: hintColor,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 7),

                              Expanded(
                                child: TextFormField(
                                  controller: secondNameController,
                                  focusNode: secondNameFocusNode,
                                  enabled: !isLoading,
                                  style: TextStyle(
                                    color: textColor,
                                  ),
                                  cursorColor: primaryColor,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.name,
                                  textInputAction: TextInputAction.next,
                                  autovalidateMode:
                                  AutovalidateMode
                                      .onUserInteraction,
                                  validator: Validators.arabicName,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context)
                                        .requestFocus(
                                      lastNameFocusNode,
                                    );
                                  },
                                  decoration: nameInputDecoration(
                                    hint: 'الاسم الثاني',
                                    primaryColor: primaryColor,
                                    borderColor: borderColor,
                                    fieldColor: fieldColor,
                                    hintColor: hintColor,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 7),

                              Expanded(
                                child: TextFormField(
                                  controller: lastNameController,
                                  focusNode: lastNameFocusNode,
                                  enabled: !isLoading,
                                  style: TextStyle(
                                    color: textColor,
                                  ),
                                  cursorColor: primaryColor,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.name,
                                  textInputAction: TextInputAction.next,
                                  autovalidateMode:
                                  AutovalidateMode
                                      .onUserInteraction,
                                  validator: Validators.arabicName,
                                  onFieldSubmitted: (_) {
                                    FocusScope.of(context)
                                        .requestFocus(
                                      phoneFocusNode,
                                    );
                                  },
                                  decoration: nameInputDecoration(
                                    hint: 'اللقب',
                                    primaryColor: primaryColor,
                                    borderColor: borderColor,
                                    fieldColor: fieldColor,
                                    hintColor: hintColor,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // نفس المسافة في التصميم الأصلي
                          // لا يوجد حقل Username

                          const SizedBox(height: 16),

                          // =========================
                          // Phone - Yemen only
                          // =========================

                          TextFormField(
                            controller: phoneController,
                            focusNode: phoneFocusNode,
                            enabled: !isLoading,
                            style: TextStyle(
                              color: textColor,
                            ),
                            cursorColor: primaryColor,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                            textInputAction: TextInputAction.next,
                            validator: Validators.supportedPhone,
                            autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(9),
                            ],
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(
                                passwordFocusNode,
                              );
                            },
                            decoration: InputDecoration(
                              hintText: 'رقم الهاتف',
                              hintTextDirection: TextDirection.rtl,
                              hintStyle: TextStyle(
                                color: hintColor,
                                fontSize: 16,
                              ),
                              errorStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: primaryColor,
                              ),

                              // علم اليمن ومفتاح الدولة ثابتان
                              suffixIcon: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Center(
                                  widthFactor: 1,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '+967',
                                        textDirection:
                                        TextDirection.ltr,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                          FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        '🇾🇪',
                                        style: TextStyle(
                                          fontSize: 25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              filled: true,
                              fillColor: fieldColor,
                              contentPadding:
                              const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
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
                            ),
                          ),

                          const SizedBox(height: 16),

                          // =========================
                          // Password
                          // =========================

                          TextFormField(
                            controller: passwordController,
                            focusNode: passwordFocusNode,
                            enabled: !isLoading,
                            style: TextStyle(
                              color: textColor,
                            ),
                            cursorColor: primaryColor,
                            obscureText: obscurePassword,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.right,
                            textInputAction: TextInputAction.done,
                            maxLength: 6,
                            validator: Validators.sixDigitPassword,
                            autovalidateMode:
                            AutovalidateMode.onUserInteraction,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            onFieldSubmitted: (_) {
                              createAccount();
                            },
                            decoration: InputDecoration(
                              hintText: 'كلمة المرور',
                              counterText: '',
                              helperText: isPasswordFocused
                                  ? 'أدخل 6 أرقام'
                                  : null,
                              helperStyle: TextStyle(
                                color: primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              errorStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              hintStyle: TextStyle(
                                color: hintColor,
                                fontSize: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: primaryColor,
                              ),
                              suffixIcon: IconButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                  setState(() {
                                    obscurePassword =
                                    !obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  obscurePassword
                                      ? Icons
                                      .visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xff607D83),
                                ),
                              ),
                              filled: true,
                              fillColor: fieldColor,
                              contentPadding:
                              const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
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
                            ),
                          ),

                          SizedBox(
                            height: isSmallScreen ? 16 : 22,
                          ),

                          // =========================
                          // Create Account
                          // =========================

                          SizedBox(
                            width: double.infinity,
                            height: isSmallScreen ? 52 : 56,
                            child: ElevatedButton(
                              onPressed:
                              isLoading ? null : createAccount,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                primaryColor.withOpacity(0.55),
                                disabledForegroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(15),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                                  : Text(
                                'إنشاء حساب',
                                style: TextStyle(
                                  fontSize:
                                  isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // =========================
                          // Login Link
                          // =========================

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              borderRadius:
                              BorderRadius.circular(18),
                              border: Border.all(
                                color: borderColor,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'لديك حساب بالفعل؟',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize:
                                      isSmallScreen ? 14 : 16,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap:
                                  isLoading ? null : goToLogin,
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  child: Padding(
                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.login,
                                          color: primaryColor,
                                          size: 21,
                                        ),
                                        const SizedBox(width: 5),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 17,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: borderColor,
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }
}
