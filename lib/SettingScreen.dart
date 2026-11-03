import 'package:flutter/material.dart';
import 'main.dart';
import 'ChangePasswordScreen.dart';
import 'PrivacyScreen.dart';
import 'AboutScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    loadNotificationSettings();
  }

  Future<void> loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      notificationsEnabled =
          prefs.getBool('notificationsEnabled') ?? true;
    });
  }

  Future<void> saveNotificationSettings(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('notificationsEnabled', value);

    if (!mounted) return;

    setState(() {
      notificationsEnabled = value;
    });
  }

  bool get isDarkMode => themeNotifier.value == ThemeMode.dark;

  void openChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  void openPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyScreen(),
      ),
    );
  }

  void openAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Color primaryColor = theme.primaryColor;
    final Color textColor = theme.colorScheme.onSurface;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;

            final bool isVerySmall = width < 390;
            final bool isTablet = width >= 600;

            final double horizontalPadding = isVerySmall
                ? 15
                : isTablet
                ? 40
                : 20;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(
                          isTablet: isTablet,
                        ),

                        const SizedBox(height: 28),

                        _buildSectionTitle(
                          'المظهر',
                          primaryColor,
                        ),

                        const SizedBox(height: 12),

                        _buildSwitchOption(
                          icon: Icons.dark_mode_outlined,
                          title: 'الوضع الداكن',
                          subtitle:
                          'تغيير مظهر التطبيق إلى الوضع الداكن',
                          value: isDarkMode,
                          onChanged: (value) {
                            themeNotifier.value = value
                                ? ThemeMode.dark
                                : ThemeMode.light;

                            setState(() {});
                          },
                        ),

                        const SizedBox(height: 26),

                        _buildSectionTitle(
                          'الإشعارات',
                          primaryColor,
                        ),

                        const SizedBox(height: 12),

                        _buildSwitchOption(
                          icon: Icons.notifications_outlined,
                          title: 'الإشعارات',
                          subtitle:
                          'السماح بتنبيهات ومواعيد الطفل',
                          value: notificationsEnabled,
                          onChanged: (value) {
                            saveNotificationSettings(value);
                          },
                        ),

                        const SizedBox(height: 26),

                        _buildSectionTitle(
                          'الأمان والخصوصية',
                          primaryColor,
                        ),

                        const SizedBox(height: 12),

                        _buildOption(
                          icon: Icons.lock_outline_rounded,
                          title: 'تغيير كلمة المرور',
                          subtitle: 'تحديث كلمة مرور الحساب',
                          onTap: openChangePassword,
                        ),

                        const SizedBox(height: 12),

                        _buildOption(
                          icon: Icons.privacy_tip_outlined,
                          title: 'الخصوصية',
                          subtitle:
                          'معلومات حماية وخصوصية البيانات',
                          onTap: openPrivacy,
                        ),

                        const SizedBox(height: 26),

                        _buildSectionTitle(
                          'عن التطبيق',
                          primaryColor,
                        ),

                        const SizedBox(height: 12),

                        _buildOption(
                          icon: Icons.info_outline_rounded,
                          title: 'حول التطبيق',
                          subtitle: 'معلومات وإصدار التطبيق',
                          onTap: openAbout,
                        ),

                        const SizedBox(height: 30),

                        Center(
                          child: Text(
                            'الإصدار 1.0.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withOpacity(0.50),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
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
  // Header
  // =========================

  Widget _buildHeader({
    required bool isTablet,
  }) {
    final Color textColor =
        Theme.of(context).colorScheme.onSurface;

    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'رجوع',
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 22,
          ),
        ),

        const SizedBox(width: 5),

        Expanded(
          child: Text(
            'الإعدادات',
            style: TextStyle(
              fontSize: isTablet ? 31 : 27,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // Section Title
  // =========================

  Widget _buildSectionTitle(
      String title,
      Color primaryColor,
      ) {
    final Color textColor =
        Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(width: 8),

        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // =========================
  // Normal Option
  // =========================

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final ThemeData theme = Theme.of(context);

    final Color primaryColor = theme.primaryColor;
    final Color textColor = theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: theme.cardColor,
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
                color: primaryColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 25,
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),

            // السهم يشير لليسار
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: textColor.withOpacity(0.45),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // Switch Option
  // =========================

  Widget _buildSwitchOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final ThemeData theme = Theme.of(context);

    final Color primaryColor = theme.primaryColor;
    final Color textColor = theme.colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: textColor.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: primaryColor,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }
}