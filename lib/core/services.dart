import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';
import 'auth_controller.dart';

class AppServices {
  final AuthController auth;
  final Dio dio;
  late final BookRepository books;
  late final ApiCrudRepository<Author> authors;
  late final ApiCrudRepository<Genre> genres;
  late final ApiCrudRepository<Publisher> publishers;
  late final ApiCrudRepository<Reader> readers;
  late final LoanRepository loans;
  late final UserRepository users;
  late final AdminRepository admin;
  late final ReferenceCache references;

  static AppServices forTest(AuthController auth, Dio dio) {
    auth.attachDio(dio);
    return AppServices._(auth, dio);
  }

  AppServices._(this.auth, this.dio) {
    books = BookRepository(dio);
    authors = ApiCrudRepository<Author>(
      dio: dio,
      endpoint: '/authors',
      parser: Author.fromJson,
      serializer: (item) => item.toInputJson(),
    );
    genres = ApiCrudRepository<Genre>(
      dio: dio,
      endpoint: '/genres',
      parser: Genre.fromJson,
      serializer: (item) => item.toInputJson(),
    );
    publishers = ApiCrudRepository<Publisher>(
      dio: dio,
      endpoint: '/publishers',
      parser: Publisher.fromJson,
      serializer: (item) => item.toInputJson(),
    );
    readers = ApiCrudRepository<Reader>(
      dio: dio,
      endpoint: '/readers',
      parser: Reader.fromJson,
      serializer: (item) => item.toInputJson(),
    );
    loans = LoanRepository(dio);
    users = UserRepository(dio);
    admin = AdminRepository(dio);
    references = ReferenceCache(
      authorsRepo: authors,
      genresRepo: genres,
      publishersRepo: publishers,
    );
  }

  static Future<AppServices> create() async {
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthController(prefs);
    final dio = buildDio(auth);
    auth.attachDio(dio);

    final services = AppServices._(auth, dio);
    await auth.restore();
    return services;
  }
}
