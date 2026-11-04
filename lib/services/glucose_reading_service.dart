
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_config.dart';

class GlucoseReadingService {
  // =====================================
  // حفظ قراءة السكر في Laravel
  // POST /api/glucose-readings
  // =====================================

  static Future<Map<String, dynamic>> saveReading({
    required int childId,
    required String readingType,
    required double glucoseLevel,
    required String readingDate,
    required String readingTime,
    String? mealStatus,
    int? mealId,
  }) async {
    try {
      const storage = FlutterSecureStorage();

      // قراءة Token تسجيل الدخول
      final String? token =
      await storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        throw Exception(
          'يجب تسجيل الدخول أولًا.',
        );
      }

      // إرسال القراءة إلى Laravel
      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/glucose-readings',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'child_id': childId,
          'reading_type': readingType,
          'glucose_level': glucoseLevel,
          'unit': 'mg/dL',
          'reading_date': readingDate,
          'reading_time': readingTime,
          'meal_status': mealStatus,
          'meal_id': mealId,
        }),
      ).timeout(
        const Duration(seconds: 20),
      );

      // قراءة استجابة Laravel
      final dynamic data =
      jsonDecode(utf8.decode(response.bodyBytes));

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'استجابة غير صحيحة من الخادم.',
        );
      }

      // نجاح الحفظ
      if (response.statusCode == 201 &&
          data['success'] == true) {
        return data;
      }

      // انتهاء جلسة تسجيل الدخول
      if (response.statusCode == 401) {
        throw Exception(
          'انتهت جلسة تسجيل الدخول. سجلي الدخول مجددًا.',
        );
      }

      // أخطاء التحقق من البيانات
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

      // بقية الأخطاء
      throw Exception(
        data['message']?.toString() ??
            'تعذر حفظ قراءة السكر.',
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
