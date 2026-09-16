import 'package:flutter_test/flutter_test.dart';
import 'package:ypdart_pr6/core/roles.dart';

void main() {
  group('Разграничение прав', () {
    test('reader может просматривать каталог', () {
      expect(RolePermissions.canViewCatalog(AppRole.reader), isTrue);
    });

    test('reader не может управлять каталогом', () {
      expect(RolePermissions.canManageCatalog(AppRole.reader), isFalse);
    });

    test('librarian может управлять каталогом', () {
      expect(RolePermissions.canManageCatalog(AppRole.librarian), isTrue);
    });

    test('librarian не может физически удалять записи', () {
      expect(RolePermissions.canHardDelete(AppRole.librarian), isFalse);
    });

    test('admin может физически удалять записи', () {
      expect(RolePermissions.canHardDelete(AppRole.admin), isTrue);
    });

    test('admin может управлять пользователями', () {
      expect(RolePermissions.canManageUsers(AppRole.admin), isTrue);
    });

    test('reader не может управлять пользователями', () {
      expect(RolePermissions.canManageUsers(AppRole.reader), isFalse);
    });

    test('admin имеет уровень не ниже librarian', () {
      expect(
        RolePermissions.hasAtLeast(AppRole.admin, AppRole.librarian),
        isTrue,
      );
    });
  });
}
