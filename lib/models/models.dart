
class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final String role;
  final int? readerId;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    required this.readerId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: _asInt(json['id']),
        username: '${json['username'] ?? ''}',
        fullName: '${json['fullName'] ?? ''}',
        email: '${json['email'] ?? ''}',
        role: '${json['role'] ?? 'reader'}',
        readerId: _asNullableInt(json['readerId']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'fullName': fullName,
        'email': email,
        'role': role,
        'readerId': readerId,
      };
}

class AdminStats {
  final int users;
  final int books;
  final int readers;
  final int activeLoans;
  final int overdueLoans;

  const AdminStats({
    required this.users,
    required this.books,
    required this.readers,
    required this.activeLoans,
    required this.overdueLoans,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) => AdminStats(
        users: _asInt(json['users']),
        books: _asInt(json['books']),
        readers: _asInt(json['readers']),
        activeLoans: _asInt(json['activeLoans']),
        overdueLoans: _asInt(json['overdueLoans']),
      );
}

class PageResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int total;
  final int totalPages;

  const PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
  });

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parser,
  ) {
    final rawItems = json['items'];
    return PageResult<T>(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((e) => parser(Map<String, dynamic>.from(e)))
              .toList()
          : <T>[],
      page: _asInt(json['page'], 1),
      size: _asInt(json['size'], 10),
      total: _asInt(json['total'], 0),
      totalPages: _asInt(json['totalPages'], 1),
    );
  }
}

class SimpleQuery {
  final String search;
  final String sort;
  final int page;
  final int size;
  final bool includeDeleted;

  const SimpleQuery({
    this.search = '',
    this.sort = 'id,asc',
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  SimpleQuery copyWith({
    String? search,
    String? sort,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return SimpleQuery(
      search: search ?? this.search,
      sort: sort ?? this.sort,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  Map<String, dynamic> toApiParams() => {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'sort': sort,
        'page': page,
        'size': size,
        if (includeDeleted) 'includeDeleted': true,
      };
}

class Author {
  final int id;
  final String fullName;
  final int? birthYear;
  final String country;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.fullName,
    required this.birthYear,
    required this.country,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        id: _asInt(json['id']),
        fullName: '${json['fullName'] ?? ''}',
        birthYear: _asNullableInt(json['birthYear']),
        country: '${json['country'] ?? ''}',
        deletedAt: _asDate(json['deletedAt']),
      );

  Map<String, dynamic> toInputJson() => {
        'fullName': fullName,
        'birthYear': birthYear,
        'country': country,
      };
}

class Genre {
  final int id;
  final String name;
  final String description;
  final DateTime? deletedAt;

  const Genre({
    required this.id,
    required this.name,
    required this.description,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
        id: _asInt(json['id']),
        name: '${json['name'] ?? ''}',
        description: '${json['description'] ?? ''}',
        deletedAt: _asDate(json['deletedAt']),
      );

  Map<String, dynamic> toInputJson() => {
        'name': name,
        'description': description,
      };
}

class Publisher {
  final int id;
  final String name;
  final String city;
  final int? foundedYear;
  final DateTime? deletedAt;

  const Publisher({
    required this.id,
    required this.name,
    required this.city,
    required this.foundedYear,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  factory Publisher.fromJson(Map<String, dynamic> json) => Publisher(
        id: _asInt(json['id']),
        name: '${json['name'] ?? ''}',
        city: '${json['city'] ?? ''}',
        foundedYear: _asNullableInt(json['foundedYear']),
        deletedAt: _asDate(json['deletedAt']),
      );

  Map<String, dynamic> toInputJson() => {
        'name': name,
        'city': city,
        'foundedYear': foundedYear,
      };
}

class LibraryCard {
  final int id;
  final String number;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  const LibraryCard({
    required this.id,
    required this.number,
    required this.issuedAt,
    required this.expiresAt,
  });

  factory LibraryCard.fromJson(Map<String, dynamic> json) => LibraryCard(
        id: _asInt(json['id']),
        number: '${json['number'] ?? ''}',
        issuedAt: _asDate(json['issuedAt']),
        expiresAt: _asDate(json['expiresAt']),
      );
}

class Reader {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final LibraryCard? card;
  final DateTime? deletedAt;

  const Reader({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  factory Reader.fromJson(Map<String, dynamic> json) {
    final rawCard = json['card'];
    return Reader(
      id: _asInt(json['id']),
      fullName: '${json['fullName'] ?? ''}',
      email: '${json['email'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      card: rawCard is Map
          ? LibraryCard.fromJson(Map<String, dynamic>.from(rawCard))
          : null,
      deletedAt: _asDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toInputJson() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
      };
}

class Book {
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int? publisherId;
  final String publisherName;
  final List<int> authorIds;
  final List<String> authorNames;
  final List<int> genreIds;
  final List<String> genreNames;
  final int copiesTotal;
  final int copiesAvailable;
  final DateTime? deletedAt;

  const Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.year,
    required this.pages,
    required this.publisherId,
    required this.publisherName,
    required this.authorIds,
    required this.authorNames,
    required this.genreIds,
    required this.genreNames,
    required this.copiesTotal,
    required this.copiesAvailable,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  factory Book.fromJson(Map<String, dynamic> json) {
    int? publisherId = _asNullableInt(json['publisherId']);
    String publisherName = '';

    final rawPublisher = json['publisher'];
    if (rawPublisher is Map) {
      publisherId = _asNullableInt(rawPublisher['id']) ?? publisherId;
      publisherName = '${rawPublisher['name'] ?? ''}';
    }

    final authorIds = <int>[];
    final authorNames = <String>[];
    final rawAuthors = json['authors'];
    if (rawAuthors is List) {
      for (final raw in rawAuthors.whereType<Map>()) {
        final id = _asNullableInt(raw['id']);
        if (id != null) authorIds.add(id);
        authorNames.add('${raw['fullName'] ?? ''}');
      }
    } else if (json['authorIds'] is List) {
      for (final raw in json['authorIds'] as List) {
        final id = _asNullableInt(raw);
        if (id != null) authorIds.add(id);
      }
    }

    final genreIds = <int>[];
    final genreNames = <String>[];
    final rawGenres = json['genres'];
    if (rawGenres is List) {
      for (final raw in rawGenres.whereType<Map>()) {
        final id = _asNullableInt(raw['id']);
        if (id != null) genreIds.add(id);
        genreNames.add('${raw['name'] ?? ''}');
      }
    } else if (json['genreIds'] is List) {
      for (final raw in json['genreIds'] as List) {
        final id = _asNullableInt(raw);
        if (id != null) genreIds.add(id);
      }
    }

    return Book(
      id: _asInt(json['id']),
      title: '${json['title'] ?? ''}',
      isbn: '${json['isbn'] ?? ''}',
      year: _asInt(json['year']),
      pages: _asInt(json['pages']),
      publisherId: publisherId,
      publisherName: publisherName,
      authorIds: authorIds,
      authorNames: authorNames,
      genreIds: genreIds,
      genreNames: genreNames,
      copiesTotal: _asInt(json['copiesTotal']),
      copiesAvailable: _asInt(json['copiesAvailable']),
      deletedAt: _asDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toInputJson() => {
        'title': title,
        'isbn': isbn,
        'year': year,
        'pages': pages,
        'publisherId': publisherId,
        'authorIds': authorIds,
        'genreIds': genreIds,
        'copiesTotal': copiesTotal,
      };
}

class Loan {
  final int id;
  final int? readerId;
  final String readerName;
  final int? bookId;
  final String bookTitle;
  final DateTime? issuedAt;
  final DateTime? dueAt;
  final DateTime? returnedAt;
  final String status;

  const Loan({
    required this.id,
    required this.readerId,
    required this.readerName,
    required this.bookId,
    required this.bookTitle,
    required this.issuedAt,
    required this.dueAt,
    required this.returnedAt,
    required this.status,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    final reader = json['reader'];
    final book = json['book'];
    return Loan(
      id: _asInt(json['id']),
      readerId: reader is Map ? _asNullableInt(reader['id']) : _asNullableInt(json['readerId']),
      readerName: reader is Map ? '${reader['fullName'] ?? ''}' : '',
      bookId: book is Map ? _asNullableInt(book['id']) : _asNullableInt(json['bookId']),
      bookTitle: book is Map ? '${book['title'] ?? ''}' : '',
      issuedAt: _asDate(json['issuedAt']),
      dueAt: _asDate(json['dueAt']),
      returnedAt: _asDate(json['returnedAt']),
      status: '${json['status'] ?? ''}',
    );
  }
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  return int.tryParse('$value') ?? fallback;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse('$value');
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse('$value');
}
