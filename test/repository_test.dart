import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ypdart_pr6/core/api_exceptions.dart';
import 'package:ypdart_pr6/models/models.dart';
import 'package:ypdart_pr6/repositories/repositories.dart';

class FakeAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(int status, Object body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

Dio fakeDio(Future<ResponseBody> Function(RequestOptions options) handler) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local/api'));
  dio.httpClientAdapter = FakeAdapter(handler);
  return dio;
}

Book sampleBook() {
  return const Book(
    id: 0,
    title: 'Тестовая книга',
    isbn: 'TEST-1',
    year: 2020,
    pages: 100,
    publisherId: 1,
    publisherName: '',
    authorIds: [1],
    authorNames: [],
    genreIds: [1],
    genreNames: [],
    copiesTotal: 1,
    copiesAvailable: 0,
  );
}

void main() {
  test('репозиторий разбирает страницу книг', () async {
    final dio = fakeDio(
      (options) async => jsonBody(200, {
        'items': [
          {
            'id': 1,
            'title': 'Война и мир',
            'isbn': '978-test',
            'year': 1869,
            'pages': 1300,
            'publisher': {'id': 1, 'name': 'АСТ'},
            'authors': [
              {'id': 1, 'fullName': 'Толстой Л. Н.'}
            ],
            'genres': [
              {'id': 2, 'name': 'Роман'}
            ],
            'copiesTotal': 4,
            'copiesAvailable': 3,
            'deletedAt': null,
          }
        ],
        'page': 1,
        'size': 10,
        'total': 1,
        'totalPages': 1,
      }),
    );

    final page = await BookRepository(dio).find(const BookQuery());
    expect(page.total, 1);
    expect(page.items.single.publisherName, 'АСТ');
  });

  test('422 преобразуется в ValidationException', () async {
    final dio = fakeDio(
      (options) async => jsonBody(422, {
        'message': 'Ошибка валидации',
        'errors': {'isbn': 'Книга с таким ISBN уже существует'},
      }),
    );

    await expectLater(
      BookRepository(dio).create(sampleBook()),
      throwsA(isA<ValidationException>()),
    );
  });

  test('409 преобразуется в ConflictException', () async {
    final dio = fakeDio(
      (options) async => jsonBody(409, {'message': 'Конфликт'}),
    );

    await expectLater(
      BookRepository(dio).hardDelete(1),
      throwsA(isA<ConflictException>()),
    );
  });

  test('500 преобразуется в ServerException', () async {
    final dio = fakeDio(
      (options) async => jsonBody(500, {'message': 'Сбой сервера'}),
    );

    await expectLater(
      BookRepository(dio).find(const BookQuery()),
      throwsA(isA<ServerException>()),
    );
  });

  test('сетевой сбой преобразуется в NetworkException', () async {
    var attempts = 0;
    final dio = fakeDio((options) async {
      attempts++;
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'offline',
      );
    });

    await expectLater(
      BookRepository(dio).find(const BookQuery()),
      throwsA(isA<NetworkException>()),
    );

    expect(attempts, 3);
  });
}
