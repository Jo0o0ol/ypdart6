enum AppRole { reader, librarian, admin }

extension AppRoleInfo on AppRole {
  String get apiName => switch (this) {
        AppRole.reader => 'reader',
        AppRole.librarian => 'librarian',
        AppRole.admin => 'admin',
      };

  String get title => switch (this) {
        AppRole.reader => 'Читатель',
        AppRole.librarian => 'Библиотекарь',
        AppRole.admin => 'Администратор',
      };

  int get level => switch (this) {
        AppRole.reader => 1,
        AppRole.librarian => 2,
        AppRole.admin => 3,
      };

  static AppRole? fromApi(String? value) {
    return switch (value) {
      'reader' => AppRole.reader,
      'librarian' => AppRole.librarian,
      'admin' => AppRole.admin,
      _ => null,
    };
  }
}

class RolePermissions {
  const RolePermissions._();

  static bool canViewCatalog(AppRole role) => true;

  static bool canManageCatalog(AppRole role) =>
      role == AppRole.librarian || role == AppRole.admin;

  static bool canManageLoans(AppRole role) =>
      role == AppRole.librarian || role == AppRole.admin;

  static bool canViewAllReaders(AppRole role) =>
      role == AppRole.librarian || role == AppRole.admin;

  static bool canHardDelete(AppRole role) => role == AppRole.admin;

  static bool canRestore(AppRole role) => role == AppRole.admin;

  static bool canManageUsers(AppRole role) => role == AppRole.admin;

  static bool hasAtLeast(AppRole actual, AppRole required) =>
      actual.level >= required.level;
}

class PasswordRules {
  const PasswordRules(this.value);

  final String value;

  bool get hasMinLength => value.length >= 8;
  bool get hasDigit => RegExp(r'\d').hasMatch(value);
  bool get hasSpecial => RegExp(r'[^A-Za-z0-9А-Яа-я]').hasMatch(value);
  bool get isValid => hasMinLength && hasDigit && hasSpecial;
}
