
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_config.dart';

class ChildService {
  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();

  // =====================================
  // إضافة طفل جديد
  // POST /api/children
  // =====================================

  static Future<Map<String, dynamic>> addChild({
    required String firstName,
    required String middleName,
    required String lastName,
    required String gender,
    required DateTime birthDate,
    required String diabetesType,
    required DateTime diagnosisDate,
    String? notes,
    String? imagePath,
  }) async {
    try {
      final String token = await _getToken();

      final String fullName = _fullName(
        firstName,
        middleName,
        lastName,
      );

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/children'),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields.addAll({
        'name': fullName,
        'gender': gender,
        'birth_date': _formatDate(birthDate),
        'diabetes_type': diabetesType,
        'diagnosis_date': _formatDate(diagnosisDate),
        'notes': notes?.trim() ?? '',
      });

      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imagePath,
          ),
        );
      }

      final streamedResponse = await request
          .send()
          .timeout(const Duration(seconds: 30));

      final response =
      await http.Response.fromStream(streamedResponse);

      return _handleChildResponse(
        response,
        expectedStatusCode: 201,
        defaultError: 'تعذر حفظ بيانات الطفل.',
      );
    } on TimeoutException {
      throw Exception(
        'انتهت مهلة الاتصال بالخادم. حاولي مرة أخرى.',
      );
    } on http.ClientException {
      throw Exception(
        'تعذر الاتصال بالخادم. تأكدي أن Laravel يعمل.',
      );
    } on FormatException {
      throw Exception(
        'تعذر قراءة استجابة الخادم.',
      );
    }
  }

  // =====================================
  // جلب أطفال ولي الأمر
  // GET /api/children
  // =====================================

  static Future<List<Map<String, dynamic>>>
  getChildren() async {
    try {
      final String token = await _getToken();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/children'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      final dynamic data =
      jsonDecode(utf8.decode(response.bodyBytes));

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'استجابة غير صحيحة من الخادم.',
        );
      }

      if (response.statusCode == 200 &&
          data['success'] == true &&
          data['children'] is List) {
        final List<dynamic> children =
        data['children'] as List<dynamic>;

        return children.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException(
              'بيانات أحد الأطفال غير صحيحة.',
            );
          }

          return item;
        }).toList();
      }

      if (response.statusCode == 401) {
        throw Exception(
          'انتهت صلاحية تسجيل الدخول. يرجى تسجيل الدخول مجددًا.',
        );
      }

      throw Exception(
        data['message']?.toString() ??
            'تعذر جلب بيانات الأطفال.',
      );
    } on TimeoutException {
      throw Exception(
        'انتهت مهلة الاتصال بالخادم. حاولي مرة أخرى.',
      );
    } on http.ClientException {
      throw Exception(
        'تعذر الاتصال بالخادم. تأكدي أن Laravel يعمل.',
      );
    } on FormatException {
      throw Exception(
        'تعذر قراءة بيانات الأطفال من الخادم.',
      );
    }
  }

  // =====================================
  // تعديل بيانات طفل موجود
  // PUT /api/children/{childId}
  // =====================================

  static Future<Map<String, dynamic>> updateChild({
    required int childId,
    required String firstName,
    required String middleName,
    required String lastName,
    required String gender,
    required DateTime birthDate,
    required String diabetesType,
    required DateTime diagnosisDate,
    String? notes,
    String? imagePath,
  }) async {
    try {
      final String token = await _getToken();

      final String fullName = _fullName(
        firstName,
        middleName,
        lastName,
      );

      // نستخدم POST مع _method=PUT
      // حتى يستطيع Laravel قراءة حقول وصور multipart
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${ApiConfig.baseUrl}/children/$childId',
        ),
      );

      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields.addAll({
        '_method': 'PUT',
        'name': fullName,
        'gender': gender,
        'birth_date': _formatDate(birthDate),
        'diabetes_type': diabetesType,
        'diagnosis_date': _formatDate(diagnosisDate),
        'notes': notes?.trim() ?? '',
      });

      // تُرسل الصورة فقط عند اختيار صورة جديدة
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imagePath,
          ),
        );
      }

      final streamedResponse = await request
          .send()
          .timeout(const Duration(seconds: 30));

      final response =
      await http.Response.fromStream(streamedResponse);

      return _handleChildResponse(
        response,
        expectedStatusCode: 200,
        defaultError: 'تعذر تعديل بيانات الطفل.',
      );
    } on TimeoutException {
      throw Exception(
        'انتهت مهلة الاتصال بالخادم. حاولي مرة أخرى.',
      );
    } on http.ClientException {
      throw Exception(
        'تعذر الاتصال بالخادم. تأكدي أن Laravel يعمل.',
      );
    } on FormatException {
      throw Exception(
        'تعذر قراءة استجابة الخادم.',
      );
    }
  }

  // =====================================
  // جلب Token الخاص بولي الأمر
  // =====================================

  static Future<String> _getToken() async {
    final String? token =
    await _storage.read(key: 'auth_token');

    if (token == null || token.isEmpty) {
      throw Exception(
        'يرجى تسجيل الدخول أولاً.',
      );
    }

    return token;
  }

  // =====================================
  // قراءة استجابة إضافة أو تعديل الطفل
  // =====================================

  static Map<String, dynamic> _handleChildResponse(
      http.Response response, {
        required int expectedStatusCode,
        required String defaultError,
      }) {
    final dynamic data =
    jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! Map<String, dynamic>) {
      throw Exception(
        'استجابة غير صحيحة من الخادم.',
      );
    }

    if (response.statusCode == expectedStatusCode &&
        data['success'] == true &&
        data['child'] is Map) {
      return data;
    }

    if (response.statusCode == 422) {
      final errors = data['errors'];

      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;

        if (firstError is List &&
            firstError.isNotEmpty) {
          throw Exception(
            firstError.first.toString(),
          );
        }
      }
    }

    if (response.statusCode == 401) {
      throw Exception(
        'انتهت صلاحية تسجيل الدخول. يرجى تسجيل الدخول مجددًا.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'الطفل غير موجود أو لا تملكين صلاحية تعديله.',
      );
    }

    throw Exception(
      data['message']?.toString() ?? defaultError,
    );
  }

  // =====================================
  // دمج الأسماء الثلاثة
  // =====================================

  static String _fullName(
      String firstName,
      String middleName,
      String lastName,
      ) {
    return [
      firstName.trim(),
      middleName.trim(),
      lastName.trim(),
    ].where((name) => name.isNotEmpty).join(' ');
  }

  // =====================================
  // تحويل التاريخ إلى yyyy-MM-dd
  // =====================================

  static String _formatDate(DateTime date) {
    final String month =
    date.month.toString().padLeft(2, '0');

    final String day =
    date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
