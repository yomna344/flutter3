
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'services/auth_service.dart';

import 'SignUpScreen.dart';
import 'ForgotPasswordScreen.dart';
import 'validators.dart';
import 'ChildSelectionScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController usernameController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  final FocusNode usernameFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  bool obscurePassword = true;
  bool rememberMe = false;
  bool isLoading = false;

  // =========================
  // Login with Laravel API
  // =========================

  Future<void> login() async {
    FocusScope.of(context).unfocus();

    final bool isValid =
        formKey.currentState?.validate() ?? false;

    if (!isValid || isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final result = await AuthService.login(
        phone: usernameController.text.trim(),
        password: passwordController.text,
      );

      final String token = result['token'] as String;

      const storage = FlutterSecureStorage();

      await storage.write(
        key: 'auth_token',
        value: token,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
          const ChildSelectionScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final String message = error
          .toString()
          .replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          behavior: SnackBarBehavior.floating,
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

  // =========================
  // Forgot Password
  // =========================

  void goToForgotPassword() {
    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const ForgotPasswordScreen(),
      ),
    );
  }

  // =========================
  // Sign Up
  // =========================

  void goToSignUp() {
    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const SignUpScreen(),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    usernameFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final bool isDark =
        theme.brightness == Brightness.dark;

    final Color primaryColor = theme.primaryColor;

    final Color backgroundColor = isDark
        ? theme.scaffoldBackgroundColor
        : Colors.white;

    final Color textColor = isDark
        ? Colors.white
        : const Color(0xff2C4A5A);

    final Color hintColor = isDark
        ? Colors.white.withOpacity(0.55)
        : const Color(0xff9AA7AB);

    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.16)
        : const Color(0xffD7E7E7);

    final Color fieldColor = isDark
        ? const Color(0xff1D292D)
        : Colors.white;

    final Color secondaryColor = isDark
        ? Colors.white.withOpacity(0.75)
        : const Color(0xff607D83);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth =
                constraints.maxWidth;

            final double screenHeight =
                constraints.maxHeight;

            final bool isSmallScreen =
                screenWidth < 360 ||
                    screenHeight < 650;

            final bool isTablet =
                screenWidth >= 600;

            final double horizontalPadding =
            isSmallScreen
                ? 18
                : isTablet
                ? 40
                : 28;

            final double imageHeight =
            isSmallScreen
                ? 155
                : isTablet
                ? 240
                : 205;

            final double titleSize =
            isSmallScreen
                ? 25
                : isTablet
                ? 32
                : 29;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                physics:
                const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isSmallScreen
                      ? 10
                      : 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                    const BoxConstraints(
                      maxWidth: 560,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                        children: [
                          // =========================
                          // Login Image
                          // =========================

                          Image.asset(
                            'images/logoprojj.png',
                            width:
                            double.infinity,
                            height: imageHeight,
                            fit: BoxFit.contain,
                          ),

                          SizedBox(
                            height: isSmallScreen
                                ? 10
                                : 18,
                          ),

                          // =========================
                          // Login Title
                          // =========================

                          Text(
                            'تسجيل الدخول',
                            textAlign:
                            TextAlign.center,
                            style: TextStyle(
                              fontSize:
                              titleSize,
                              fontWeight:
                              FontWeight.bold,
                              color: textColor,
                            ),
                          ),

                          SizedBox(
                            height: isSmallScreen
                                ? 25
                                : 32,
                          ),

                          // =========================
                          // Phone Number
                          // =========================

                          TextFormField(
                            controller:
                            usernameController,
                            focusNode:
                            usernameFocusNode,
                            keyboardType:
                            TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly,
                              LengthLimitingTextInputFormatter(
                                  9),
                            ],
                            textInputAction:
                            TextInputAction.next,
                            textCapitalization:
                            TextCapitalization
                                .none,
                            textAlign:
                            TextAlign.right,
                            textDirection:
                            TextDirection.rtl,
                            style: TextStyle(
                              color: textColor,
                            ),
                            cursorColor:
                            primaryColor,
                            validator:
                            Validators.supportedPhone,
                            onFieldSubmitted:
                                (_) {
                              FocusScope.of(
                                context,
                              ).requestFocus(
                                passwordFocusNode,
                              );
                            },
                            decoration:
                            _inputDecoration(
                              hint:
                              'رقم الهاتف ',
                              primaryColor:
                              primaryColor,
                              borderColor:
                              borderColor,
                              hintColor:
                              hintColor,
                              fieldColor:
                              fieldColor,
                              icon: Icons
                                  .person_outline_rounded,
                            ),
                          ),

                          SizedBox(
                            height: isSmallScreen
                                ? 14
                                : 18,
                          ),

                          // =========================
                          // Password
                          // =========================

                          TextFormField(
                            controller:
                            passwordController,
                            focusNode:
                            passwordFocusNode,
                            obscureText:
                            obscurePassword,
                            keyboardType:
                            TextInputType.number,
                            textInputAction:
                            TextInputAction.done,
                            textAlign:
                            TextAlign.right,
                            maxLength: 6,
                            style: TextStyle(
                              color: textColor,
                            ),
                            cursorColor:
                            primaryColor,
                            validator:
                            Validators
                                .sixDigitPassword,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly,
                              LengthLimitingTextInputFormatter(
                                  6),
                            ],
                            onFieldSubmitted:
                                (_) => login(),
                            decoration:
                            _inputDecoration(
                              hint:
                              'كلمة المرور',
                              primaryColor:
                              primaryColor,
                              borderColor:
                              borderColor,
                              hintColor:
                              hintColor,
                              fieldColor:
                              fieldColor,
                              icon: Icons
                                  .lock_outline_rounded,
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    obscurePassword =
                                    !obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  obscurePassword
                                      ? Icons
                                      .visibility_off_outlined
                                      : Icons
                                      .visibility_outlined,
                                  color:
                                  secondaryColor,
                                ),
                              ),
                            ).copyWith(
                              counterText: '',
                            ),
                          ),

                          SizedBox(
                            height: isSmallScreen
                                ? 2
                                : 6,
                          ),

                          // =========================
                          // Remember Me & Forgot Password
                          // =========================

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                            children: [
                              Flexible(
                                child:
                                TextButton(
                                  onPressed:
                                  goToForgotPassword,
                                  style:
                                  TextButton
                                      .styleFrom(
                                    padding:
                                    EdgeInsets
                                        .zero,
                                    minimumSize:
                                    const Size(
                                        0, 40),
                                    tapTargetSize:
                                    MaterialTapTargetSize
                                        .shrinkWrap,
                                  ),
                                  child: Text(
                                    'نسيت كلمة المرور؟',
                                    style:
                                    TextStyle(
                                      color:
                                      primaryColor,
                                      fontSize:
                                      isSmallScreen
                                          ? 12
                                          : 14,
                                      fontWeight:
                                      FontWeight
                                          .w600,
                                    ),
                                  ),
                                ),
                              ),

                              Flexible(
                                child: InkWell(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                      10),
                                  onTap: () {
                                    setState(() {
                                      rememberMe =
                                      !rememberMe;
                                    });
                                  },
                                  child: Row(
                                    mainAxisSize:
                                    MainAxisSize
                                        .min,
                                    children: [
                                      Checkbox(
                                        value:
                                        rememberMe,
                                        activeColor:
                                        primaryColor,
                                        checkColor:
                                        Colors.white,
                                        side:
                                        BorderSide(
                                          color:
                                          isDark
                                              ? Colors.white70
                                              : const Color(
                                            0xff607D83,
                                          ),
                                          width:
                                          1.5,
                                        ),
                                        visualDensity:
                                        VisualDensity
                                            .compact,
                                        onChanged:
                                            (value) {
                                          setState(
                                                  () {
                                                rememberMe =
                                                    value ??
                                                        false;
                                              });
                                        },
                                      ),
                                      Text(
                                        'تذكرني',
                                        style:
                                        TextStyle(
                                          fontSize:
                                          isSmallScreen
                                              ? 12
                                              : 14,
                                          color:
                                          textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(
                            height: isSmallScreen
                                ? 10
                                : 16,
                          ),

                          // =========================
                          // Login Button
                          // =========================

                          SizedBox(
                            width:
                            double.infinity,
                            height: isSmallScreen
                                ? 52
                                : 56,
                            child:
                            ElevatedButton(
                              onPressed:
                              isLoading
                                  ? null
                                  : login,
                              style:
                              ElevatedButton
                                  .styleFrom(
                                backgroundColor:
                                primaryColor,
                                foregroundColor:
                                Colors.white,
                                elevation: 0,
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                      15),
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth:
                                  2.5,
                                  color:
                                  Colors.white,
                                ),
                              )
                                  : Text(
                                'تسجيل الدخول',
                                style:
                                TextStyle(
                                  fontSize:
                                  isSmallScreen
                                      ? 16
                                      : 18,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            height: isSmallScreen
                                ? 24
                                : 30,
                          ),

                          // =========================
                          // Create Account
                          // =========================

                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              primaryColor
                                  .withOpacity(
                                isDark
                                    ? 0.10
                                    : 0.055,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                  16),
                              border:
                              Border.all(
                                color:
                                borderColor,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'ليس لديك حساب؟',
                                    style:
                                    TextStyle(
                                      fontSize:
                                      isSmallScreen
                                          ? 13
                                          : 15,
                                      color:
                                      textColor,
                                      fontWeight:
                                      FontWeight
                                          .w500,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                    width: 6),

                                OutlinedButton
                                    .icon(
                                  onPressed:
                                  goToSignUp,
                                  icon:
                                  const Icon(
                                    Icons
                                        .person_add_alt_1_rounded,
                                    size: 17,
                                  ),
                                  label:
                                  const Text(
                                    'إنشاء حساب',
                                  ),
                                  style:
                                  OutlinedButton
                                      .styleFrom(
                                    foregroundColor:
                                    primaryColor,
                                    backgroundColor:
                                    fieldColor,
                                    side:
                                    BorderSide(
                                      color:
                                      primaryColor
                                          .withOpacity(
                                          0.4),
                                    ),
                                    padding:
                                    const EdgeInsets
                                        .symmetric(
                                      horizontal:
                                      10,
                                      vertical:
                                      11,
                                    ),
                                    visualDensity:
                                    VisualDensity
                                        .compact,
                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                          12),
                                    ),
                                    textStyle:
                                    const TextStyle(
                                      fontSize:
                                      12,
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                              height: 25),
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

  // =========================
  // Input Decoration
  // =========================

  InputDecoration _inputDecoration({
    required String hint,
    required Color primaryColor,
    required Color borderColor,
    required Color hintColor,
    required Color fieldColor,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintTextDirection: TextDirection.rtl,
      hintStyle: TextStyle(
        color: hintColor,
        fontSize: 16,
      ),
      errorStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(
        icon,
        color: primaryColor,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: fieldColor,
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(15),
        borderSide: BorderSide(
          color: borderColor,
          width: 1.3,
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(15),
        borderSide: BorderSide(
          color: primaryColor,
          width: 1.8,
        ),
      ),
      errorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.3,
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.8,
        ),
      ),
    );
  }
}
