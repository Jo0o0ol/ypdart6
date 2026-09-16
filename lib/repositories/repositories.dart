import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../models/models.dart';

typedef JsonParser<T> = T Function(Map<String, dynamic> json);
typedef InputSerializer<T> = Map<String, dynamic> Function(T item);

class ApiCrudRepository<T> {
  final Dio _dio;
  final String endpoint;
  final JsonParser<T> parser;
  final InputSerializer<T> serializer;
  CancelToken? _listToken;

  ApiCrudRepository({
    required Dio dio,
    required this.endpoint,
    required this.parser,
    required this.serializer,
  }) : _dio = dio;

  Future<PageResult<T>> find(SimpleQuery query) async {
    _listToken?.cancel('Устаревший запрос отменён');
    final token = CancelToken();
    _listToken = token;

    return guardRead(() async {
      final response = await _dio.get(
        endpoint,
        queryParameters: query.toApiParams(),
        cancelToken: token,
      );
      return PageResult<T>.fromJson(
        Map<String, dynamic>.from(response.data as Map),
        parser,
      );
    });
  }

  Future<T> findById(int id, {bool includeDeleted = false}) {
    return guardRead(() async {
      final response = await _dio.get(
        '$endpoint/$id',
        queryParameters: {
          if (includeDeleted) 'includeDeleted': true,
        },
      );
      return parser(Map<String, dynamic>.from(response.data as Map));
    });
  }

  Future<T> create(T item) {
    return guardWrite(() async {
      final response = await _dio.post(endpoint, data: serializer(item));
      return parser(Map<String, dynamic>.from(response.data as Map));
    });
  }

  Future<T> update(int id, T item) {
    return guardWrite(() async {
      final response = await _dio.put('$endpoint/$id', data: serializer(item));
      return parser(Map<String, dynamic>.from(response.data as Map));
    });
  }

  Future<void> softDelete(int id) {
    return guardWrite(() async {
      await _dio.delete('$endpoint/$id');
    });
  }

  Future<void> hardDelete(int id) {
    return guardWrite(() async {
      await _dio.delete('$endpoint/$id', queryParameters: {'hard': true});
    });
  }

  Future<T> restore(int id) {
    return guardWrite(() async {
      final response = await _dio.post('$endpoint/$id/restore');
      return parser(Map<String, dynamic>.from(response.data as Map));
    });
  }

  Future<int> deleteMany(List<int> ids) {
    return guardWrite(() async {
      final response = await _dio.post('$endpoint/bulk-delete', data: {'ids': ids});
      final data = Map<String, dynamic>.from(response.data as Map);
      final raw = data['deleted'];
      if (raw is int) return raw;
      return int.tryParse('$raw') ?? 0;
    });
  }
}

class BookQuery {
  final String search;
  final int? yearFrom;
  final int? yearTo;
  final bool? available;
  final String sort;
  final int page;
  final int size;
  final bool includeDeleted;
  final int? delayMs;
  final int? failCode;

  const BookQuery({
    this.search = '',
    this.yearFrom,
    this.yearTo,
    this.available,
    this.sort = 'title,asc',
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
    this.delayMs,
    this.failCode,
  });

  BookQuery copyWith({
    String? search,
    int? yearFrom,
    int? yearTo,
    bool? available,
    String? sort,
    int? page,
    int? size,
    bool? includeDeleted,
    bool clearYearFrom = false,
    bool clearYearTo = false,
    bool clearAvailable = false,
  }) {
    return BookQuery(
      search: search ?? this.search,
      yearFrom: clearYearFrom ? null : (yearFrom ?? this.yearFrom),
      yearTo: clearYearTo ? null : (yearTo ?? this.yearTo),
      available: clearAvailable ? null : (available ?? this.available),
      sort: sort ?? this.sort,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
      delayMs: delayMs,
      failCode: failCode,
    );
  }

  Map<String, dynamic> toApiParams() => {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (yearFrom != null) 'yearFrom': yearFrom,
        if (yearTo != null) 'yearTo': yearTo,
        if (available != null) 'available': available,
        'sort': sort,
        'page': page,
        'size': size,
        if (includeDeleted) 'includeDeleted': true,
        if (delayMs != null) '__delay': delayMs,
        if (failCode != null) '__fail': failCode,
      };
}

class BookRepository {
  final Dio _dio;
  CancelToken? _listToken;

  BookRepository(this._dio);

  Future<PageResult<Book>> find(BookQuery query) async {
    _listToken?.cancel('Устаревший запрос отменён');
    final token = CancelToken();
    _listToken = token;

    return guardRead(() async {
      final response = await _dio.get(
        '/books',
        queryParameters: query.toApiParams(),
        cancelToken: token,
      );
      return PageResult<Book>.fromJson(
        Map<String, dynamic>.from(response.data as Map),
        Book.fromJson,
      );
    });
  }

  Future<Book> findById(int id, {bool includeDeleted = false}) {
    return guardRead(() async {
      final response = await _dio.get(
        '/books/$id',
        queryParameters: {if (includeDeleted) 'includeDeleted': true},
      );
      return Book.fromJson(Map<String, dynamic>.from(response.data as Map));
    });
  }

  Future<Book> create(Book book) {
    return guardWrite(() async {
      final response = await _dio.post('/books', data: book.toInputJson());
      return Book.fromJson(Map<String, dynamic>.from(response.data as Map));
    });
  }

  Future<Book> update(Book book) {
    return guardWrite(() async {
      final response = await _dio.put('/books/${book.id}', data: book.toInputJson());
      return Book.fromJson(Map<String, dynamic>.from(response.data as Map));
    });
  }

  Future<void> softDelete(int id) {
    return guardWrite(() async {
      await _dio.delete('/books/$id');
    });
  }

  Future<void> hardDelete(int id) {
    return guardWrite(() async {
      await _dio.delete('/books/$id', queryParameters: {'hard': true});
    });
  }

  Future<Book> restore(int id) {
    return guardWrite(() async {
      final response = await _dio.post('/books/$id/restore');
      return Book.fromJson(Map<String, dynamic>.from(response.data as Map));
    });
  }
}

class LoanRepository {
  final Dio _dio;

  LoanRepository(this._dio);

  Future<PageResult<Loan>> find() {
    return guardRead(() async {
      final response = await _dio.get(
        '/loans',
        queryParameters: {'page': 1, 'size': 50, 'sort': 'id,desc'},
      );
      return PageResult<Loan>.fromJson(
        Map<String, dynamic>.from(response.data as Map),
        Loan.fromJson,
      );
    });
  }

  Future<Loan> create({required int readerId, required int bookId, int days = 14}) {
    return guardWrite(() async {
      final response = await _dio.post(
        '/loans',
        data: {'readerId': readerId, 'bookId': bookId, 'days': days},
      );
      return Loan.fromJson(Map<String, dynamic>.from(response.data as Map));
    });
  }

  Future<Loan> returnLoan(int id) {
    return guardWrite(() async {
      final response = await _dio.post('/loans/$id/return');
      return Loan.fromJson(Map<String, dynamic>.from(response.data as Map));
    });
  }

  Future<Loan> extendLoan(int id, {int days = 7}) {
    return guardWrite(() async {
      final response = await _dio.post(
        '/loans/$id/extend',
        data: {'days': days},
      );
      return Loan.fromJson(Map<String, dynamic>.from(response.data as Map));
    });
  }
}


class UserRepository {
  final Dio _dio;

  UserRepository(this._dio);

  Future<PageResult<AppUser>> find({
    int page = 1,
    int size = 50,
  }) {
    return guardRead(() async {
      final response = await _dio.get(
        '/users',
        queryParameters: {
          'page': page,
          'size': size,
          'sort': 'username,asc',
        },
      );
      return PageResult<AppUser>.fromJson(
        Map<String, dynamic>.from(response.data as Map),
        AppUser.fromJson,
      );
    });
  }

  Future<AppUser> changeRole(int id, String role) {
    return guardWrite(() async {
      final response = await _dio.patch(
        '/users/$id/role',
        data: {'role': role},
      );
      return AppUser.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    });
  }
}

class AdminRepository {
  final Dio _dio;

  AdminRepository(this._dio);

  Future<AdminStats> stats() {
    return guardRead(() async {
      final response = await _dio.get('/admin/stats');
      return AdminStats.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    });
  }
}

class ReferenceCache {
  final ApiCrudRepository<Author> authorsRepo;
  final ApiCrudRepository<Genre> genresRepo;
  final ApiCrudRepository<Publisher> publishersRepo;

  List<Author>? _authors;
  List<Genre>? _genres;
  List<Publisher>? _publishers;

  ReferenceCache({
    required this.authorsRepo,
    required this.genresRepo,
    required this.publishersRepo,
  });

  Future<List<Author>> authors() async {
    if (_authors != null) return _authors!;
    _authors = (await authorsRepo.find(const SimpleQuery(size: 100, sort: 'fullName,asc'))).items;
    return _authors!;
  }

  Future<List<Genre>> genres() async {
    if (_genres != null) return _genres!;
    _genres = (await genresRepo.find(const SimpleQuery(size: 100, sort: 'name,asc'))).items;
    return _genres!;
  }

  Future<List<Publisher>> publishers() async {
    if (_publishers != null) return _publishers!;
    _publishers = (await publishersRepo.find(const SimpleQuery(size: 100, sort: 'name,asc'))).items;
    return _publishers!;
  }

  void invalidate() {
    _authors = null;
    _genres = null;
    _publishers = null;
  }
}
