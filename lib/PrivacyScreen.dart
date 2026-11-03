import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primaryColor = theme.primaryColor;
    final Color textColor = theme.colorScheme.onSurface;
    final Color secondaryTextColor =
    textColor.withOpacity(0.65);

    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 700,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'الخصوصية',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Privacy Icon
                    Center(
                      child: Container(
                        width: 105,
                        height: 105,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.privacy_tip_outlined,
                          size: 55,
                          color: primaryColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        'خصوصيتك تهمنا',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Center(
                      child: Text(
                        'نحرص على توضيح كيفية التعامل مع بيانات ولي الأمر والبيانات الصحية للطفل داخل تطبيق TinyGuide.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: secondaryTextColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    _privacyCard(
                      context,
                      icon: Icons.lock_outline_rounded,
                      title: 'حماية البيانات',
                      description:
                      'تُتاح بيانات الحساب والطفل وفق صلاحيات الوصول المعتمدة في النظام، بهدف حماية المعلومات من الوصول غير المصرح به.',
                    ),

                    const SizedBox(height: 14),

                    _privacyCard(
                      context,
                      icon: Icons.health_and_safety_outlined,
                      title: 'البيانات الصحية',
                      description:
                      'تشمل البيانات الصحية قراءات السكر والوجبات والأنشطة والأدوية والفحوصات والمواعيد. وتُستخدم لدعم متابعة الحالة الصحية للطفل.',
                    ),

                    const SizedBox(height: 14),

                    _privacyCard(
                      context,
                      icon: Icons.analytics_outlined,
                      title: 'استخدام البيانات والتحليل',
                      description:
                      'قد تُستخدم البيانات المسجلة لإنشاء التقارير الصحية وتحليل الأنماط وتقديم إرشادات توعوية تساعد ولي الأمر على متابعة صحة الطفل.',
                    ),

                    const SizedBox(height: 14),

                    _privacyCard(
                      context,
                      icon: Icons.notifications_none_rounded,
                      title: 'الإشعارات والتذكيرات',
                      description:
                      'يستخدم التطبيق الإشعارات والتذكيرات لتنبيه ولي الأمر بالمواعيد والتنبيهات التي قام بإعدادها، ويمكن التحكم فيها من إعدادات الجهاز والتطبيق عند توفر ذلك.',
                    ),

                    const SizedBox(height: 14),

                    _privacyCard(
                      context,
                      icon: Icons.cloud_outlined,
                      title: 'تخزين البيانات',
                      description:
                      'تُدار بيانات التطبيق وفق آلية التخزين والصلاحيات المعتمدة في النظام. وسيتم توضيح تفاصيل التخزين والحماية بعد اكتمال ربط الخادم.',
                    ),

                    const SizedBox(height: 14),

                    _privacyCard(
                      context,
                      icon: Icons.share_outlined,
                      title: 'مشاركة البيانات',
                      description:
                      'يمكن لولي الأمر تنزيل التقارير الصحية ومشاركتها مع الطبيب عند الحاجة. ولا يعني إنشاء التقرير إرساله تلقائيًا إلى أي جهة طبية.',
                    ),

                    const SizedBox(height: 14),

                    _privacyCard(
                      context,
                      icon: Icons.manage_accounts_outlined,
                      title: 'حقوق ولي الأمر',
                      description:
                      'يحق لولي الأمر الاطلاع على بيانات الطفل وتحديث المعلومات المسجلة، وطلب حذف الحساب والبيانات وفق الإجراءات والسياسات المعتمدة في النظام.',
                    ),

                    const SizedBox(height: 25),

                    // Important Note
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: primaryColor,
                            size: 21,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'تطبيق TinyGuide أداة للمتابعة والتوعية الصحية، ولا يُعد بديلاً عن استشارة الطبيب أو التشخيص الطبي.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.7,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Text(
                        'سيتم استكمال وتحديث تفاصيل سياسة الخصوصية عند اكتمال ربط النظام بالخادم.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.6,
                          color: textColor.withOpacity(0.55),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _privacyCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
      }) {
    final theme = Theme.of(context);
    final Color primaryColor = theme.primaryColor;
    final Color textColor = theme.colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: textColor.withOpacity(0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.12),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    color: textColor.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}