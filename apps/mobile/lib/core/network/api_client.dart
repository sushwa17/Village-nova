import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  static String get baseUrl =>
      kIsWeb ? 'http://127.0.0.1:8000/v1' : 'http://10.0.2.2:8000/v1';

  late final Dio dio;

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Attach Supabase Session Token if initialized & logged in;
          // otherwise use dev prototype token for local backend preview.
          Session? session;
          try {
            session = Supabase.instance.client.auth.currentSession;
          } catch (_) {
            // Supabase is optional in local/offline preview builds
          }
          if (session != null) {
            options.headers['Authorization'] = 'Bearer ${session.accessToken}';
          } else {
            options.headers['Authorization'] =
                'Bearer dev-00000000-0000-0000-0000-000000000001';
            options.headers['X-Resident-ID'] =
                '00000000-0000-0000-0000-000000000001';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Centralized error logging
          return handler.next(e);
        },
      ),
    );
  }
}
