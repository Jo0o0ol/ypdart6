import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'auth_controller.dart';
import 'config.dart';

Dio buildDio(AuthController auth) {
  late final Dio dio;

  dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = auth.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API] → ${options.method} ${options.uri}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) async {
        final status = response.statusCode ?? 0;
        final path = response.requestOptions.path;

        if (kDebugMode) {
          debugPrint('[API] ← $status ${response.requestOptions.uri}');
        }

        if (status == 401 &&
            !path.contains('/auth/') &&
            response.requestOptions.extra['retried401'] != true) {
          try {
            await auth.refreshTokens();

            final options = response.requestOptions;
            options.extra['retried401'] = true;
            options.headers['Authorization'] = 'Bearer ${auth.accessToken}';

            final retried = await dio.fetch<dynamic>(options);
            handler.resolve(retried);
            return;
          } catch (_) {
            await auth.forceLogout(
              'Сессия истекла, обновить токен не удалось. Войдите снова.',
            );
          }
        }

        if (status >= 400) {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
          return;
        }

        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          debugPrint(
            '[API] ✕ ${error.requestOptions.method} '
            '${error.requestOptions.uri} ${error.type}',
          );
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}
