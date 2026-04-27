import 'package:flutter_test/flutter_test.dart';
import 'package:pickllist/features/auth/domain/app_user.dart';

void main() {
  const manager = AppUser(
    id: 'u_manager',
    email: 'manager@farm.test',
    displayName: 'Maya Manager',
    role: UserRole.manager,
  );

  test('UserRole.fromName falls back to worker for unknown values', () {
    expect(UserRole.fromName('manager'), UserRole.manager);
    expect(UserRole.fromName('missing'), UserRole.worker);
  });

  test('fromMap and toMap round-trip all user fields', () {
    final roundTrip = AppUser.fromMap(manager.toMap());

    expect(roundTrip, manager);
    expect(roundTrip.isManager, isTrue);
    expect(roundTrip.active, isTrue);
    expect(roundTrip.hashCode, manager.hashCode);
    expect(roundTrip.toString(), contains('manager@farm.test'));
    expect(roundTrip.toString(), contains('active: true'));
  });

  test('fromMap defaults active to true when field is absent', () {
    final map = {
      'id': 'u_x',
      'email': 'x@farm.test',
      'displayName': 'X',
      'role': 'worker',
    };
    final user = AppUser.fromMap(map);
    expect(user.active, isTrue);
  });

  test('fromMap respects active: false', () {
    final map = {
      'id': 'u_inactive',
      'email': 'i@farm.test',
      'displayName': 'Inactive',
      'role': 'worker',
      'active': false,
    };
    final user = AppUser.fromMap(map);
    expect(user.active, isFalse);
  });

  test('toMap includes active field', () {
    final map = manager.toMap();
    expect(map['active'], isTrue);

    const inactive = AppUser(
      id: 'u_i',
      email: 'i@farm.test',
      displayName: 'Inactive',
      role: UserRole.worker,
      active: false,
    );
    expect(inactive.toMap()['active'], isFalse);
  });

  test('copyWith replaces selected fields only', () {
    final worker = manager.copyWith(
      role: UserRole.worker,
      displayName: 'Wendy',
    );

    expect(worker.id, manager.id);
    expect(worker.displayName, 'Wendy');
    expect(worker.isManager, isFalse);
    expect(worker.active, isTrue);
  });

  test('copyWith can set active to false', () {
    final inactive = manager.copyWith(active: false);
    expect(inactive.active, isFalse);
    expect(inactive.id, manager.id);
  });

  test('equality includes active field', () {
    const userActive = AppUser(
      id: 'u_x',
      email: 'x@farm.test',
      displayName: 'X',
      role: UserRole.worker,
    );
    const userInactive = AppUser(
      id: 'u_x',
      email: 'x@farm.test',
      displayName: 'X',
      role: UserRole.worker,
      active: false,
    );
    expect(userActive, isNot(equals(userInactive)));
    expect(userActive.hashCode, isNot(equals(userInactive.hashCode)));
  });

  test('Iterable lookup returns matching users and handles null ids', () {
    final users = [manager];

    expect(users.byId('u_manager'), manager);
    expect(users.byId('missing'), isNull);
    expect(users.byId(null), isNull);
  });
}
