import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение и настройки CORS.',
  ]);
}

class CancelledRequestException extends ApiException {
  const CancelledRequestException() : super('Запрос отменён.');
}

class BadRequestException extends ApiException {
  const BadRequestException(super.message);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([super.message = 'Недостаточно прав для этого действия.']);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

class ConflictException extends ApiException {
  const ConflictException(super.message);
}

class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(super.message, this.errors);
}

class ServerException extends ApiException {
  const ServerException([super.message = 'Ошибка на сервере. Попробуйте позже.']);
}

ApiException mapHttpError(int status, dynamic body) {
  String? message;
  if (body is Map && body['message'] is String) {
    message = body['message'] as String;
  }

  switch (status) {
    case 400:
      return BadRequestException(message ?? 'Некорректный запрос.');
    case 401:
      return UnauthorizedException(message ?? 'Требуется вход в систему.');
    case 403:
      return ForbiddenException(message ?? 'Недостаточно прав.');
    case 404:
      return NotFoundException(message ?? 'Запись не найдена.');
    case 409:
      return ConflictException(message ?? 'Операция невозможна из-за конфликта.');
    case 422:
      final errors = <String, String>{};
      if (body is Map && body['errors'] is Map) {
        final raw = body['errors'] as Map;
        for (final entry in raw.entries) {
          errors['${entry.key}'] = '${entry.value}';
        }
      }
      return ValidationException(message ?? 'Ошибка валидации.', errors);
    default:
      return ServerException(message ?? 'Неизвестная ошибка сервера (код $status).');
  }
}

ApiException mapDioError(DioException error) {
  final existing = error.error;
  if (existing is ApiException) return existing;

  if (error.type == DioExceptionType.cancel) {
    return const CancelledRequestException();
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return const NetworkException('Сервер не ответил вовремя.');
  }

  if (error.type == DioExceptionType.connectionError) {
    return const NetworkException(
      'Не удалось соединиться с сервером. Если сервер запущен, '
      'откройте F12 → Console и проверьте CORS.',
    );
  }

  if (error.response != null) {
    return mapHttpError(error.response!.statusCode ?? 500, error.response!.data);
  }

  return const ServerException();
}

Future<T> guardWrite<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (e) {
    throw mapDioError(e);
  }
}

Future<T> guardRead<T>(Future<T> Function() action, {int maxAttempts = 3}) async {
  ApiException? last;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } on DioException catch (e) {
      final mapped = mapDioError(e);
      if (mapped is CancelledRequestException) throw mapped;
      last = mapped;
      if (mapped is! NetworkException || attempt == maxAttempts) {
        throw mapped;
      }
      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
    }
  }

  throw last ?? const ServerException();
}
