import 'package:go_router/go_router.dart';

import 'core/roles.dart';
import 'core/services.dart';
import 'models/models.dart';
import 'screens/admin_screen.dart';
import 'screens/books_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/home_screen.dart';
import 'screens/librarian_desk_screen.dart';
import 'screens/loans_screen.dart';
import 'screens/login_screen.dart';
import 'screens/not_found_screen.dart';
import 'screens/reader_cabinet_screen.dart';
import 'screens/register_screen.dart';
import 'screens/security_demo_screen.dart';
import 'screens/simple_editors.dart';
import 'screens/simple_resource_screen.dart';
import 'widgets/adaptive_navigation_shell.dart';

GoRouter buildRouter(AppServices services) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: services.auth,
    redirect: (context, state) {
      final auth = services.auth;
      final target = state.matchedLocation;
      final loggedIn = auth.isAuthenticated;
      final isPublic = target == '/login' || target == '/register';

      if (!loggedIn && !isPublic) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$from';
      }

      if (loggedIn && isPublic) {
        final from = state.uri.queryParameters['from'];
        if (from != null && from.startsWith('/') && !from.startsWith('/login')) {
          return from;
        }
        return '/';
      }

      if (!loggedIn) return null;
      if (target == '/forbidden' ||
          target == '/security-demo' ||
          target == '/books' ||
          target == '/') {
        return null;
      }

      if (target == '/reader' && !auth.serverIs(AppRole.reader)) {
        return '/forbidden';
      }
      if (target == '/librarian' && !auth.serverIs(AppRole.librarian)) {
        return '/forbidden';
      }
      if (target == '/admin' && !auth.serverIs(AppRole.admin)) {
        return '/forbidden';
      }

      const staffRoutes = <String>{
        '/authors',
        '/genres',
        '/publishers',
        '/readers',
        '/loans',
      };
      if (staffRoutes.contains(target) &&
          !auth.serverHasAtLeast(AppRole.librarian)) {
        return '/forbidden';
      }

      return null;
    },
    routes: [
      // Публичные экраны НЕ находятся внутри адаптивного shell.
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(services: services),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => RegisterScreen(services: services),
      ),

      // Защищённая часть приложения. ShellRoute — безопасный способ
      // добавить NavigationBar/NavigationRail вокруг GoRouter.
      ShellRoute(
        builder: (context, state, child) => AdaptiveNavigationShell(
          services: services,
          currentLocation: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/forbidden',
            builder: (context, state) => ForbiddenScreen(services: services),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => HomeScreen(services: services),
          ),
          GoRoute(
            path: '/books',
            builder: (context, state) => BooksScreen(
              services: services,
              initialDelay: int.tryParse(
                state.uri.queryParameters['__delay'] ?? '',
              ),
              initialFail: int.tryParse(
                state.uri.queryParameters['__fail'] ?? '',
              ),
            ),
          ),
          GoRoute(
            path: '/reader',
            builder: (context, state) => ReaderCabinetScreen(services: services),
          ),
          GoRoute(
            path: '/librarian',
            builder: (context, state) => LibrarianDeskScreen(services: services),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => AdminScreen(services: services),
          ),
          GoRoute(
            path: '/security-demo',
            builder: (context, state) => SecurityDemoScreen(services: services),
          ),
          GoRoute(
            path: '/authors',
            builder: (context, state) => SimpleResourceScreen<Author>(
              services: services,
              title: 'Авторы',
              repository: services.authors,
              itemTitle: (item) => item.fullName,
              itemSubtitle: (item) => '${item.country} · ${item.birthYear ?? '—'}',
              itemId: (item) => item.id,
              isDeleted: (item) => item.isDeleted,
              sortOptions: const {
                'fullName,asc': 'ФИО ↑',
                'fullName,desc': 'ФИО ↓',
                'birthYear,asc': 'Год рождения ↑',
                'birthYear,desc': 'Год рождения ↓',
              },
              editEntity: (context, item) => editAuthor(context, services, item),
            ),
          ),
          GoRoute(
            path: '/genres',
            builder: (context, state) => SimpleResourceScreen<Genre>(
              services: services,
              title: 'Жанры',
              repository: services.genres,
              itemTitle: (item) => item.name,
              itemSubtitle: (item) => item.description,
              itemId: (item) => item.id,
              isDeleted: (item) => item.isDeleted,
              sortOptions: const {
                'name,asc': 'Название ↑',
                'name,desc': 'Название ↓',
                'id,asc': 'ID ↑',
              },
              editEntity: (context, item) => editGenre(context, services, item),
            ),
          ),
          GoRoute(
            path: '/publishers',
            builder: (context, state) => SimpleResourceScreen<Publisher>(
              services: services,
              title: 'Издательства',
              repository: services.publishers,
              itemTitle: (item) => item.name,
              itemSubtitle: (item) => '${item.city} · основано ${item.foundedYear ?? '—'}',
              itemId: (item) => item.id,
              isDeleted: (item) => item.isDeleted,
              sortOptions: const {
                'name,asc': 'Название ↑',
                'name,desc': 'Название ↓',
                'foundedYear,asc': 'Год основания ↑',
                'foundedYear,desc': 'Год основания ↓',
              },
              editEntity: (context, item) => editPublisher(context, services, item),
            ),
          ),
          GoRoute(
            path: '/readers',
            builder: (context, state) => SimpleResourceScreen<Reader>(
              services: services,
              title: 'Читатели',
              repository: services.readers,
              itemTitle: (item) => item.fullName,
              itemSubtitle: (item) => '${item.email} · ${item.phone} · ${item.card?.number ?? 'без билета'}',
              itemId: (item) => item.id,
              isDeleted: (item) => item.isDeleted,
              sortOptions: const {
                'fullName,asc': 'ФИО ↑',
                'fullName,desc': 'ФИО ↓',
                'email,asc': 'E-mail ↑',
              },
              editEntity: (context, item) => editReader(context, services, item),
            ),
          ),
          GoRoute(
            path: '/loans',
            builder: (context, state) => LoansScreen(services: services),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
  );
}
