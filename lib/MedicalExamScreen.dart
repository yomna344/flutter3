import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicalExamScreen extends StatefulWidget {
  final String childName;
  final DateTime birthDate;
  final String gender;
  final String? childImagePath;

  const MedicalExamScreen({
    super.key,
    required this.childName,
    required this.birthDate,
    required this.gender,
    this.childImagePath,
  });

  @override
  State<MedicalExamScreen> createState() => _MedicalExamScreenState();
}

class _MedicalExamScreenState extends State<MedicalExamScreen> {
  final ImagePicker imagePicker = ImagePicker();

  bool isPickingAttachment = false;
  bool isSavingAttachment = false;
  bool showAttachmentError = false;

  String? selectedAttachmentType;
  XFile? selectedImage;
  PlatformFile? selectedFile;

  static const String recordsStorageKey = 'tinyguide_medical_exam_records';

  bool get hasAttachment =>
      selectedImage != null || selectedFile != null;

  Future<void> showAttachmentOptions(
      TapDownDetails details,
      ) async {
    if (isPickingAttachment || isSavingAttachment) return;

    final ThemeData theme = Theme.of(context);

    final RenderObject? renderObject =
    Overlay.of(context).context.findRenderObject();

    if (renderObject is! RenderBox) {
      showTemporaryMessage('تعذر فتح قائمة المرفقات');
      return;
    }

    final RenderBox overlay = renderObject;
    final Offset position = details.globalPosition;

    final String? option = await showMenu<String>(
      context: context,
      color: theme.cardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
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
                Expanded(
                  child: Text(
                    'اختيار صورة من المعرض',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
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
                Expanded(
                  child: Text(
                    'التقاط صورة بالكاميرا',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'file',
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                const Icon(
                  Icons.insert_drive_file_outlined,
                  color: Color(0xff64C7C4),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'اختيار ملف PDF أو صورة',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!mounted || option == null) return;

    switch (option) {
      case 'gallery':
        await pickImageFromGallery();
        break;
      case 'camera':
        await takePicture();
        break;
      case 'file':
        await pickFile();
        break;
    }
  }

  Future<void> pickImageFromGallery() async {
    if (isPickingAttachment || isSavingAttachment) return;

    setState(() {
      isPickingAttachment = true;
    });

    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (!mounted || image == null) return;

      setState(() {
        selectedImage = image;
        selectedFile = null;
        selectedAttachmentType = 'gallery';
        showAttachmentError = false;
      });

      showTemporaryMessage('تم اختيار الصورة بنجاح');
    } catch (e) {
      debugPrint('Gallery error: $e');

      if (mounted) {
        showTemporaryMessage(
          'تعذر فتح المعرض. حاولي مرة أخرى.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPickingAttachment = false;
        });
      }
    }
  }

  Future<void> takePicture() async {
    if (isPickingAttachment || isSavingAttachment) return;

    setState(() {
      isPickingAttachment = true;
    });

    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (!mounted || image == null) return;

      setState(() {
        selectedImage = image;
        selectedFile = null;
        selectedAttachmentType = 'camera';
        showAttachmentError = false;
      });

      showTemporaryMessage('تم التقاط الصورة بنجاح');
    } catch (e) {
      debugPrint('Camera error: $e');

      if (mounted) {
        showTemporaryMessage(
          'تعذر تشغيل الكاميرا. حاولي مرة أخرى.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPickingAttachment = false;
        });
      }
    }
  }

  Future<void> pickFile() async {
    if (isPickingAttachment || isSavingAttachment) return;

    setState(() {
      isPickingAttachment = true;
    });

    try {
      final FilePickerResult? result =
      await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'webp',
        ],
        allowMultiple: false,
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        return;
      }

      final PlatformFile file = result.files.first;

      setState(() {
        selectedFile = file;
        selectedImage = null;
        selectedAttachmentType = 'file';
        showAttachmentError = false;
      });

      showTemporaryMessage('تم اختيار الملف بنجاح');
    } catch (e) {
      debugPrint('File picker error: $e');

      if (mounted) {
        showTemporaryMessage(
          'تعذر فتح الملفات. حاولي مرة أخرى.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPickingAttachment = false;
        });
      }
    }
  }

  void removeAttachment() {
    if (isPickingAttachment || isSavingAttachment) return;

    setState(() {
      selectedAttachmentType = null;
      selectedImage = null;
      selectedFile = null;
      showAttachmentError = false;
    });

    showTemporaryMessage('تم إلغاء المرفق');
  }

  String attachmentText() {
    if (selectedImage != null) {
      return selectedImage!.name;
    }

    if (selectedFile != null) {
      return selectedFile!.name;
    }

    return 'اضغط لإرفاق صورة أو ملف';
  }

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

  bool isAllowedAttachment(String name) {
    final String extension = name.split('.').last.toLowerCase();

    return [
      'pdf',
      'jpg',
      'jpeg',
      'png',
      'webp',
    ].contains(extension);
  }

  String attachmentKind(String name) {
    final String extension = name.split('.').last.toLowerCase();

    return extension == 'pdf' ? 'pdf' : 'image';
  }

  Future<void> saveMedicalExam() async {
    if (isPickingAttachment || isSavingAttachment) return;

    if (!hasAttachment) {
      setState(() {
        showAttachmentError = true;
      });

      showTemporaryMessage(
        'يرجى إرفاق صورة أو ملف للفحص الطبي أولاً',
      );
      return;
    }

    final String originalName =
        selectedImage?.name ?? selectedFile!.name;

    final String? sourcePath =
        selectedImage?.path ?? selectedFile?.path;

    if (!isAllowedAttachment(originalName)) {
      showTemporaryMessage(
        'يسمح بإرفاق الصور وملفات PDF فقط',
      );
      return;
    }

    if (sourcePath == null || sourcePath.isEmpty) {
      showTemporaryMessage(
        'تعذر الوصول إلى الملف المحدد',
      );
      return;
    }

    setState(() {
      isSavingAttachment = true;
      showAttachmentError = false;
    });

    File? copiedFile;

    try {
      final File sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        throw Exception('Source file not found');
      }

      final Directory appDirectory =
      await getApplicationDocumentsDirectory();

      final Directory examsDirectory = Directory(
        '${appDirectory.path}${Platform.pathSeparator}medical_exams',
      );

      if (!await examsDirectory.exists()) {
        await examsDirectory.create(recursive: true);
      }

      final DateTime savedAt = DateTime.now();

      final String extension =
      originalName.split('.').last.toLowerCase();

      final String uniqueId =
          '${savedAt.microsecondsSinceEpoch}';

      final String storedFileName = '$uniqueId.$extension';

      final String destinationPath =
          '${examsDirectory.path}${Platform.pathSeparator}$storedFileName';

      copiedFile = await sourceFile.copy(destinationPath);

      final SharedPreferences preferences =
      await SharedPreferences.getInstance();

      final List<String> savedRecords =
          preferences.getStringList(recordsStorageKey) ?? [];

      final Map<String, dynamic> newRecord = {
        'id': uniqueId,
        'childName': widget.childName,
        'fileName': originalName,
        'filePath': copiedFile.path,
        'fileType': attachmentKind(originalName),
        'savedAt': savedAt.toIso8601String(),
      };

      savedRecords.insert(0, jsonEncode(newRecord));

      final bool savedSuccessfully =
      await preferences.setStringList(
        recordsStorageKey,
        savedRecords,
      );

      if (!savedSuccessfully) {
        throw Exception('Failed to save record metadata');
      }

      if (!mounted) return;

      setState(() {
        selectedImage = null;
        selectedFile = null;
        selectedAttachmentType = null;
        showAttachmentError = false;
      });

      showTemporaryMessage('تم حفظ المرفق بنجاح');

      // نرجع للشاشة السابقة بعد نجاح الحفظ.
      // شاشة السجلات ستقرأ البيانات المحفوظة في الخطوة التالية.
      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Save medical exam error: $e');

      // إذا فشل تسجيل بيانات المرفق، نحذف النسخة التي أنشأناها.
      if (copiedFile != null && await copiedFile.exists()) {
        try {
          await copiedFile.delete();
        } catch (deleteError) {
          debugPrint('Cleanup error: $deleteError');
        }
      }

      if (mounted) {
        showTemporaryMessage(
          'تعذر حفظ المرفق. حاولي مرة أخرى.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSavingAttachment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Color primaryColor = theme.primaryColor;
    final Color darkColor = theme.colorScheme.onSurface;
    final Color cardColor = theme.cardColor;

    final bool isDark = theme.brightness == Brightness.dark;

    final Color borderColor = isDark
        ? darkColor.withOpacity(0.14)
        : const Color(0xffD7E7E7);

    final Color hintColor = isDark
        ? darkColor.withOpacity(0.52)
        : const Color(0xff8A989D);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double screenWidth = constraints.maxWidth;
            final double screenHeight = constraints.maxHeight;

            final bool isVerySmall = screenWidth < 390;

            final bool isSmallScreen =
                screenWidth < 430 || screenHeight < 650;

            final bool isTablet = screenWidth >= 600;

            final double horizontalPadding = isVerySmall
                ? 14
                : isTablet
                ? 36
                : 20;

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
                    child: Column(
                      children: [
                        // Header
                        SizedBox(
                          height: 48,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                'تسجيل فحص طبي',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isVerySmall ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: darkColor,
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
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
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
                                    onPressed: isPickingAttachment ||
                                        isSavingAttachment
                                        ? null
                                        : saveMedicalExam,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isVerySmall ? 14 : 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: isSavingAttachment
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : Text(
                                      'حفظ',
                                      style: TextStyle(
                                        fontSize:
                                        isVerySmall ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: isSmallScreen ? 35 : 45,
                        ),

                        // عنوان بيانات الفحص
                        Row(
                          children: [
                            Icon(
                              Icons.assignment_turned_in_outlined,
                              color: primaryColor,
                              size: 25,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'بيانات الفحص الطبي',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // المرفق
                        GestureDetector(
                          onTapDown: isPickingAttachment ||
                              isSavingAttachment
                              ? null
                              : showAttachmentOptions,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: showAttachmentError
                                    ? Colors.red
                                    : selectedAttachmentType == null
                                    ? borderColor
                                    : primaryColor,
                                width: 1.3,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selectedImage != null
                                      ? Icons.image_outlined
                                      : selectedFile != null
                                      ? Icons
                                      .insert_drive_file_outlined
                                      : Icons.cloud_upload_outlined,
                                  size: 27,
                                  color: primaryColor,
                                ),

                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'المرفق',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: darkColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        isSavingAttachment
                                            ? 'جارٍ حفظ المرفق...'
                                            : isPickingAttachment
                                            ? 'جارٍ فتح المرفقات...'
                                            : attachmentText(),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: hintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (isPickingAttachment ||
                                    isSavingAttachment)
                                  SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primaryColor,
                                    ),
                                  )
                                else if (hasAttachment)
                                  IconButton(
                                    onPressed: removeAttachment,
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xffC85C55),
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: darkColor,
                                  ),
                              ],
                            ),
                          ),
                        ),

                        if (showAttachmentError) ...[
                          const SizedBox(height: 7),
                          Align(
                            alignment:
                            AlignmentDirectional.centerStart,
                            child: Text(
                              'المرفق مطلوب',
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],

                        // معاينة الصورة
                        if (selectedImage != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius:
                              BorderRadius.circular(14),
                              border: Border.all(
                                color: borderColor,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius:
                              BorderRadius.circular(10),
                              child: Image.file(
                                File(selectedImage!.path),
                                height: 180,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, error, stackTrace) {
                                  return const SizedBox(
                                    height: 100,
                                    child: Center(
                                      child: Text(
                                        'تعذر عرض معاينة الصورة',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],

                        // تفاصيل الملف
                        if (selectedFile != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius:
                              BorderRadius.circular(14),
                              border: Border.all(
                                color: borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  color: primaryColor,
                                  size: 30,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedFile!.name,
                                        maxLines: 2,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: darkColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                                        style: TextStyle(
                                          color: hintColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 50),

                        // التنبيه
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xff18272A)
                                : const Color(0xffEEF7FA),
                            borderRadius:
                            BorderRadius.circular(13),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  'يرجى إرفاق صورة واضحة أو ملف يحتوي على نتائج الفحص الطبي',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: darkColor,
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
            );
          },
        ),
      ),
    );
  }
}