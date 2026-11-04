
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_config.dart';

class MealService {
  // =====================================
  // حفظ وجبة جديدة في Laravel
  // POST /api/meals
  // =====================================

  static Future<Map<String, dynamic>> saveMeal({
    required int childId,
    required String mealType,
    required Map<String, List<String>> ingredients,
    required String mealDate,
    required String mealTime,
    String? notes,
  }) async {
    try {
      const storage = FlutterSecureStorage();

      // جلب Token تسجيل الدخول
      final String? token =
      await storage.read(key: 'auth_token');

      if (token == null || token.isEmpty) {
        throw Exception(
          'يجب تسجيل الدخول أولًا.',
        );
      }

      // =====================================
      // إرسال الوجبة إلى Laravel
      // =====================================

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/meals',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'child_id': childId,
          'meal_type': mealType,
          'ingredients': ingredients,
          'meal_date': mealDate,
          'meal_time': mealTime,
          'notes': notes,
        }),
      ).timeout(
        const Duration(seconds: 20),
      );

      // =====================================
      // قراءة استجابة Laravel
      // =====================================

      final dynamic decoded =
      jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'استجابة غير صحيحة من الخادم.',
        );
      }

      final Map<String, dynamic> data = decoded;

      // =====================================
      // نجاح الحفظ
      // =====================================

      if (response.statusCode == 201 &&
          data['success'] == true) {
        if (data['meal_id'] == null) {
          throw Exception(
            'تم استلام استجابة بدون رقم الوجبة.',
          );
        }

        return data;
      }

      // =====================================
      // انتهاء تسجيل الدخول
      // =====================================

      if (response.statusCode == 401) {
        throw Exception(
          'انتهت جلسة تسجيل الدخول. سجلي الدخول مجددًا.',
        );
      }

      // =====================================
      // أخطاء التحقق من البيانات
      // =====================================

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

      // =====================================
      // بقية الأخطاء
      // =====================================

      throw Exception(
        data['message']?.toString() ??
            'تعذر حفظ الوجبة.',
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
