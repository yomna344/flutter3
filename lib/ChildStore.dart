
import 'package:flutter/foundation.dart';

import 'services/child_service.dart';
import 'services/api_config.dart';

// =====================================
// Child Model
// =====================================

class ChildModel {
  // رقم الطفل الحقيقي في MySQL
  final int? id;

  // معرف الطفل داخل Flutter
  final String localId;

  String firstName;
  String middleName;
  String lastName;
  String gender;
  DateTime birthDate;

  // مسار الصورة المحلية داخل الجهاز
  String? imagePath;

  // مسار الصورة المحفوظة في Laravel
  String? serverImagePath;

  String diabetesType;
  DateTime? diagnosisDate;
  String notes;

  ChildModel({
    this.id,
    required this.localId,
    required this.firstName,
    this.middleName = '',
    this.lastName = '',
    required this.gender,
    required this.birthDate,
    this.imagePath,
    this.serverImagePath,
    this.diabetesType = '',
    this.diagnosisDate,
    this.notes = '',
  });

  // =====================================
  // الاسم الكامل
  // =====================================

  String get fullName => [
    firstName,
    middleName,
    lastName,
  ].where((name) => name.trim().isNotEmpty).join(' ');

  // =====================================
  // رابط صورة الطفل في Laravel
  // =====================================

  String? get imageUrl {
    final String path =
        serverImagePath?.trim() ?? '';

    if (path.isEmpty) {
      return null;
    }

    // في حالة رجوع رابط كامل من Laravel
    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }

    // المسار المحفوظ غالبًا:
    // children/image-name.jpg
    String cleanPath = path.replaceFirst(
      RegExp(r'^/+'),
      '',
    );

    // منع تكرار storage إذا كان موجودًا
    if (cleanPath.startsWith('storage/')) {
      cleanPath = cleanPath.substring(
        'storage/'.length,
      );
    }

    // مثال:
    // http://192.168.1.103:8000/storage/children/image.jpg
    final Uri baseUri =
    Uri.parse(ApiConfig.baseUrl);

    return baseUri
        .resolve(
      '/storage/${Uri.encodeFull(cleanPath)}',
    )
        .toString();
  }

  // =====================================
  // هل توجد صورة على Laravel؟
  // =====================================

  bool get hasServerImage =>
      imageUrl != null;

  // =====================================
  // منع تكرار البيانات المحلية
  // =====================================

  String get _identityKey => [
    firstName.trim().toLowerCase(),
    middleName.trim().toLowerCase(),
    lastName.trim().toLowerCase(),
    gender.trim(),
    '${birthDate.year}-${birthDate.month}-${birthDate.day}',
  ].join('|');

  // =====================================
  // تحويل البيانات المحلية القديمة
  // =====================================

  factory ChildModel.fromMap(
      Map<String, dynamic> data,
      ) {
    return ChildModel(
      id: _parseId(
        data['child_id'] ?? data['id'],
      ),

      localId: data['localId']?.toString() ??
          DateTime.now()
              .microsecondsSinceEpoch
              .toString(),

      firstName:
      (data['firstName'] ?? '').toString(),

      middleName:
      (data['middleName'] ?? '').toString(),

      lastName:
      (data['lastName'] ?? '').toString(),

      gender:
      (data['gender'] ?? '').toString(),

      birthDate: data['birthDate'] is DateTime
          ? data['birthDate'] as DateTime
          : DateTime.parse(
        data['birthDate'].toString(),
      ),

      imagePath: data['imagePath']?.toString(),

      serverImagePath:
      data['serverImagePath']?.toString() ??
          data['image_path']?.toString(),

      diabetesType:
      (data['diabetesType'] ?? '').toString(),

      diagnosisDate:
      data['diagnosisDate'] is DateTime
          ? data['diagnosisDate'] as DateTime
          : data['diagnosisDate'] == null
          ? null
          : DateTime.parse(
        data['diagnosisDate'].toString(),
      ),

      notes: (data['notes'] ?? '').toString(),
    );
  }

  // =====================================
  // تحويل بيانات Laravel إلى ChildModel
  // =====================================

  factory ChildModel.fromApiMap(
      Map<String, dynamic> data,
      ) {
    final int? childId =
    _parseId(data['child_id']);

    if (childId == null) {
      throw const FormatException(
        'معرف الطفل غير موجود في استجابة Laravel.',
      );
    }

    // Laravel يحفظ الاسم كاملًا في name
    final String fullName =
    (data['name'] ?? '').toString().trim();

    final List<String> nameParts =
    fullName.isEmpty
        ? <String>[]
        : fullName.split(RegExp(r'\s+'));

    final String firstName =
    nameParts.isNotEmpty
        ? nameParts.first
        : '';

    final String lastName =
    nameParts.length >= 2
        ? nameParts.last
        : '';

    final String middleName =
    nameParts.length > 2
        ? nameParts
        .sublist(
      1,
      nameParts.length - 1,
    )
        .join(' ')
        : '';

    // مسار الصورة القادم من MySQL
    final String? imagePathFromServer =
    data['image_path']?.toString();

    return ChildModel(
      id: childId,

      // معرف ثابت مأخوذ من MySQL
      localId: 'server:$childId',

      firstName: firstName,
      middleName: middleName,
      lastName: lastName,

      gender:
      (data['gender'] ?? '').toString(),

      birthDate: DateTime.parse(
        data['birth_date'].toString(),
      ),

      diabetesType:
      (data['diabetes_type'] ?? '').toString(),

      diagnosisDate:
      data['diagnosis_date'] == null
          ? null
          : DateTime.parse(
        data['diagnosis_date'].toString(),
      ),

      notes:
      (data['notes'] ?? '').toString(),

      // الصورة ليست ملفًا محليًا
      imagePath: null,

      // الاحتفاظ بالصورة الموجودة في Laravel
      serverImagePath: imagePathFromServer,
    );
  }

  // =====================================
  // تحويل المعرف إلى int
  // =====================================

  static int? _parseId(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }
}

// =====================================
// Child Store
// =====================================

class ChildStore extends ChangeNotifier {
  ChildStore._();

  static final ChildStore instance =
  ChildStore._();

  final List<ChildModel> _children = [];

  ChildModel? _selectedChild;

  bool _isLoading = false;
  String? _errorMessage;

  List<ChildModel> get children =>
      List.unmodifiable(_children);

  ChildModel? get selectedChild =>
      _selectedChild;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // =====================================
  // جلب الأطفال من Laravel
  // =====================================

  Future<void> loadChildrenFromApi() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      // جلب بيانات الأطفال
      final List<Map<String, dynamic>> apiChildren =
      await ChildService.getChildren();

      // تحويل البيانات إلى ChildModel
      final List<ChildModel> loadedChildren =
      apiChildren.map((data) {
        return ChildModel.fromApiMap(data);
      }).toList();

      // الاحتفاظ بمعرف الطفل المختار
      final int? previousServerId =
          _selectedChild?.id;

      final String? previousIdentity =
          _selectedChild?._identityKey;

      // استبدال البيانات المحلية ببيانات MySQL
      // لمنع ظهور الأطفال مرتين
      _children
        ..clear()
        ..addAll(loadedChildren);

      ChildModel? newSelection;

      // اختيار نفس الطفل عبر child_id
      if (previousServerId != null) {
        for (final child in _children) {
          if (child.id == previousServerId) {
            newSelection = child;
            break;
          }
        }
      }

      // محاولة مطابقة الطفل المحلي
      if (newSelection == null &&
          previousIdentity != null) {
        for (final child in _children) {
          if (child._identityKey ==
              previousIdentity) {
            newSelection = child;
            break;
          }
        }
      }

      // اختيار أول طفل عند عدم وجود مطابقة
      if (newSelection == null &&
          _children.isNotEmpty) {
        newSelection = _children.first;
      }

      _selectedChild = newSelection;
    } catch (error) {
      _errorMessage = error
          .toString()
          .replaceFirst('Exception: ', '');

      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =====================================
  // إزالة التكرار
  // =====================================

  void deduplicateChildren() {
    final selectedLocalId =
        _selectedChild?.localId;

    final selectedServerId =
        _selectedChild?.id;

    final List<ChildModel> uniqueChildren = [];
    final Set<String> seen = {};

    for (final child in _children) {
      final String key = child.id != null
          ? 'server:${child.id}'
          : 'local:${child._identityKey}';

      if (seen.add(key)) {
        uniqueChildren.add(child);
      }
    }

    _children
      ..clear()
      ..addAll(uniqueChildren);

    ChildModel? selection;

    for (final child in _children) {
      if ((selectedServerId != null &&
          child.id == selectedServerId) ||
          child.localId == selectedLocalId) {
        selection = child;
        break;
      }
    }

    _selectedChild = selection ??
        (_children.isEmpty
            ? null
            : _children.first);

    notifyListeners();
  }

  // =====================================
  // إضافة طفل إلى القائمة المحلية
  // =====================================

  void addChild(ChildModel child) {
    // البحث أولًا باستخدام رقم الطفل
    if (child.id != null) {
      final serverIndex =
      _children.indexWhere(
            (item) => item.id == child.id,
      );

      if (serverIndex != -1) {
        _children[serverIndex] = child;
        _selectedChild = child;
        notifyListeners();
        return;
      }
    }

    final localIndex =
    _children.indexWhere(
          (item) => item.localId == child.localId,
    );

    if (localIndex != -1) {
      _children[localIndex] = child;
      _selectedChild = child;
      notifyListeners();
      return;
    }

    // منع تكرار النسخ المحلية
    if (child.id == null) {
      final duplicateIndex =
      _children.indexWhere(
            (item) =>
        item.id == null &&
            item._identityKey ==
                child._identityKey,
      );

      if (duplicateIndex != -1) {
        _selectedChild =
        _children[duplicateIndex];

        notifyListeners();
        return;
      }
    }

    _children.add(child);
    _selectedChild = child;

    notifyListeners();
  }

  // =====================================
  // تحديث بيانات طفل محليًا
  // =====================================

  void updateChild(ChildModel child) {
    final index = _children.indexWhere(
          (item) =>
      child.id != null &&
          item.id == child.id,
    );

    final localIndex = index != -1
        ? index
        : _children.indexWhere(
          (item) =>
      item.localId == child.localId,
    );

    if (localIndex == -1) return;

    final oldChild = _children[localIndex];

    // الاحتفاظ بمسار الصورة المحفوظة على Laravel
    // عند تعديل بيانات الطفل محليًا
    if (child.serverImagePath == null) {
      child.serverImagePath =
          oldChild.serverImagePath;
    }

    _children[localIndex] = child;

    if (_selectedChild?.localId ==
        child.localId ||
        (child.id != null &&
            _selectedChild?.id ==
                child.id)) {
      _selectedChild = child;
    }

    deduplicateChildren();
  }

  // =====================================
  // اختيار طفل
  // =====================================

  void selectChild(String localId) {
    final index = _children.indexWhere(
          (child) =>
      child.localId == localId,
    );

    if (index == -1) return;

    if (_selectedChild?.localId ==
        localId) {
      return;
    }

    _selectedChild =
    _children[index];

    notifyListeners();
  }

  // =====================================
  // مسح البيانات المحلية
  // =====================================

  void clear() {
    _children.clear();
    _selectedChild = null;
    _errorMessage = null;
    _isLoading = false;

    notifyListeners();
  }
}
