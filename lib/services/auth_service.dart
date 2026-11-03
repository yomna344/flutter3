
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class AuthService {

  // =====================================
  // تسجيل دخول ولي الأمر
  // =====================================

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phone.trim(),
          'password': password,
        }),
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
          data['token'] is String &&
          (data['token'] as String).isNotEmpty) {
        return data;
      }

      throw Exception(
        data['message']?.toString() ??
            'فشل تسجيل الدخول.',
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
  // إنشاء حساب ولي أمر جديد
  // =====================================

  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String middleName,
    required String lastName,
    required String phone,
    required String password,
  }) async {
    try {

      // رقم الهاتف المحلي المكون من 9 أرقام
      final String localPhone = phone.trim();

      // إضافة مفتاح اليمن عند الحاجة
      final String fullPhone =
      localPhone.startsWith('967')
          ? localPhone
          : '967$localPhone';

      // إرسال بيانات التسجيل إلى Laravel
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/register'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'first_name': firstName.trim(),
          'middle_name': middleName.trim(),
          'last_name': lastName.trim(),
          'phone': fullPhone,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 20));

      // قراءة استجابة Laravel
      final dynamic data =
      jsonDecode(utf8.decode(response.bodyBytes));

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'استجابة غير صحيحة من الخادم.',
        );
      }

      // نجاح إنشاء الحساب
      if (response.statusCode == 201 &&
          data['success'] == true &&
          data['token'] is String &&
          (data['token'] as String).isNotEmpty) {
        return data;
      }

      // معالجة أخطاء التحقق من Laravel
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

      throw Exception(
        data['message']?.toString() ??
            'تعذر إنشاء الحساب.',
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
}
