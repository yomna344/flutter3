import 'package:flutter/material.dart';
import 'LoginScreen.dart';

class GuidanceScreen extends StatefulWidget {
  const GuidanceScreen({super.key});

  @override
  State<GuidanceScreen> createState() =>
      _GuidanceScreenState();
}

class _GuidanceScreenState extends State<GuidanceScreen> {
  final PageController _pageController = PageController();

  int currentPage = 0;

  final List<Map<String, dynamic>> guidancePages = [
    {
      'icon': Icons.child_care_rounded,
      'title': 'ابدأ بملف طفلك',
      'description':
      'أضف بيانات طفلك أولاً حتى تتمكن من تسجيل ومتابعة معلوماته الصحية بشكل منظم.',
      'color': const Color(0xff35A89C),
      'details': [
        'أدخل اسم الطفل وتاريخ ميلاده وجنسه.',
        'أضف المعلومات الصحية المطلوبة مثل نوع السكري.',
        'يمكنك اختيار الطفل الذي تريد متابعة بياناته عند استخدام التطبيق.',
      ],
    },
    {
      'icon': Icons.water_drop_rounded,
      'title': 'كيف تسجل قراءة السكر؟',
      'description':
      'سجل نتيجة جهاز قياس السكر لمتابعة قراءات طفلك والرجوع إليها لاحقاً.',
      'color': const Color(0xffD95C5C),
      'details': [
        'اختر نوع القراءة: قبل الوجبة أو بعد الوجبة أو صائم.',
        'أدخل مستوى السكر بوحدة mg/dL.',
        'حدد تاريخ ووقت إجراء القياس.',
        'حدد حالة الوجبة المرتبطة بالقراءة إذا كانت متاحة.',
      ],
    },
    {
      'icon': Icons.restaurant_rounded,
      'title': 'سجل الوجبات والأنشطة',
      'description':
      'يساعدك تسجيل وجبات طفلك وأنشطته اليومية على الاحتفاظ بمعلومات نمط حياته ومراجعتها لاحقاً.',
      'color': const Color(0xff469E55),
      'details': [
        'في الوجبات: اختر المجموعة الغذائية المناسبة للطعام الذي تناوله طفلك.',
        'يمكنك اختيار مجموعات مثل النشويات والكربوهيدرات والبروتينات والخضروات والفواكه والحليب ومشتقاته والدهون الصحية.',
        'حدد وقت الوجبة وأضف الملاحظات المتعلقة بها.',
        'في النشاط: اختر نوع النشاط الذي مارسه طفلك.',
        'حدد مدة النشاط وشدته: منخفض أو متوسط أو مرتفع.',
        'احرص على تسجيل الوجبات والأنشطة بانتظام لمراجعتها لاحقاً.',
      ],
    },
    {
      'icon': Icons.medical_services_rounded,
      'title': 'تابع العلاج والرعاية الطبية',
      'description':
      'نظم معلومات الأدوية والمواعيد والفحوصات الطبية الخاصة بطفلك.',
      'color': const Color(0xff6654B8),
      'details': [
        'أضف اسم الدواء والجرعة وعدد مرات الاستخدام حسب وصف الطبيب.',
        'يمكنك تفعيل التذكيرات لمساعدتك على تذكر مواعيد الأدوية.',
        'سجل مواعيد الزيارات الطبية القادمة.',
        'احتفظ بنتائج الفحوصات الطبية وملاحظاتها.',
      ],
    },
    {
      'icon': Icons.menu_book_rounded,
      'title': 'ارجع إلى سجلات طفلك',
      'description':
      'يمكنك الرجوع إلى المعلومات التي سجلتها سابقاً ومراجعة تاريخ المتابعة الصحية لطفلك.',
      'color': const Color(0xff35A89C),
      'details': [
        'راجع قراءات السكر السابقة وتواريخها.',
        'اعرض الوجبات والأنشطة المسجلة.',
        'تابع سجلات الأدوية والفحوصات والمواعيد.',
        'استخدم السجلات لمراجعة المعلومات ومناقشتها مع الطبيب.',
      ],
    },
  ];

  void nextPage() {
    if (currentPage < guidancePages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      goToLogin();
    }
  }

  void previousPage() {
    if (currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Color primaryColor = theme.primaryColor;
    final Color textColor = theme.colorScheme.onSurface;

    final Color secondaryColor =
    textColor.withOpacity(0.65);

    final bool isDark =
        theme.brightness == Brightness.dark;

    final double screenWidth =
        MediaQuery.of(context).size.width;

    final bool isTablet = screenWidth >= 600;

    return Scaffold(
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 45 : 20,
              vertical: 10,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                ),
                child: Column(
                  children: [
                    // Header
                    // Header
                    SizedBox(
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Text(
                              'دليل استخدام TinyGuide',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: goToLogin,
                              child: Text(
                                'تخطي',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Guidance Pages
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: guidancePages.length,
                        onPageChanged: (index) {
                          setState(() {
                            currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final page = guidancePages[index];

                          final Color pageColor =
                          page['color'] as Color;

                          final List<String> details =
                          List<String>.from(
                            page['details'],
                          );

                          return SingleChildScrollView(
                            physics:
                            const BouncingScrollPhysics(),
                            child: Padding(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 15,
                              ),
                              child: Column(
                                children: [
                                  // Icon
                                  Container(
                                    width: isTablet ? 175 : 145,
                                    height: isTablet ? 175 : 145,
                                    decoration: BoxDecoration(
                                      color: pageColor.withOpacity(
                                        isDark ? 0.16 : 0.10,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      page['icon'] as IconData,
                                      size: isTablet ? 85 : 72,
                                      color: pageColor,
                                    ),
                                  ),

                                  const SizedBox(height: 25),

                                  // Title
                                  Text(
                                    page['title'] as String,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isTablet ? 25 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Description
                                  Text(
                                    page['description'] as String,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.8,
                                      color: secondaryColor,
                                    ),
                                  ),

                                  const SizedBox(height: 25),

                                  // Practical Instructions
                                  Container(
                                    width: double.infinity,
                                    padding:
                                    const EdgeInsets.all(17),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius:
                                      BorderRadius.circular(18),
                                      border: Border.all(
                                        color: textColor.withOpacity(
                                          0.10,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'كيف تستخدم هذه الميزة؟',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                            FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        ...details.map((detail) {
                                          return Padding(
                                            padding:
                                            const EdgeInsets.only(
                                              bottom: 14,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Container(
                                                  width: 27,
                                                  height: 27,
                                                  decoration:
                                                  BoxDecoration(
                                                    color: pageColor
                                                        .withOpacity(
                                                      0.12,
                                                    ),
                                                    shape:
                                                    BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.check_rounded,
                                                    color: pageColor,
                                                    size: 18,
                                                  ),
                                                ),

                                                const SizedBox(
                                                  width: 10,
                                                ),

                                                Expanded(
                                                  child: Text(
                                                    detail,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      height: 1.7,
                                                      color:
                                                      secondaryColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Page Indicators
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: List.generate(
                        guidancePages.length,
                            (index) {
                          final bool selected =
                              currentPage == index;

                          return AnimatedContainer(
                            duration: const Duration(
                              milliseconds: 250,
                            ),
                            margin:
                            const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            width: selected ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: selected
                                  ? primaryColor
                                  : secondaryColor
                                  .withOpacity(0.25),
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${currentPage + 1} من ${guidancePages.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryColor,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Navigation Buttons
                    Row(
                      children: [
                        // Previous Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: currentPage > 0
                                ? previousPage
                                : null,
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              size: 19,
                            ),
                            label: const Text('السابق'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                              Colors.transparent,
                              disabledForegroundColor:
                              secondaryColor.withOpacity(0.30),
                              elevation: 0,
                              side: BorderSide(
                                color: currentPage > 0
                                    ? primaryColor
                                    : primaryColor.withOpacity(0.3),
                              ),
                              minimumSize:
                              const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Next Button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize:
                              const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              currentPage ==
                                  guidancePages.length - 1
                                  ? 'ابدأ الاستخدام'
                                  : 'التالي',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}