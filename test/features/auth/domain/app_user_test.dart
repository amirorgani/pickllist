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
    expect(roundTrip.hashCode, manager.hashCode);
    expect(roundTrip.toString(), contains('manager@farm.test'));
  });

  test('copyWith replaces selected fields only', () {
    final worker = manager.copyWith(
      role: UserRole.worker,
      displayName: 'Wendy',
    );

    expect(worker.id, manager.id);
    expect(worker.displayName, 'Wendy');
    expect(worker.isManager, isFalse);
  });

  test('Iterable lookup returns matching users and handles null ids', () {
    final users = [manager];

    expect(users.byId('u_manager'), manager);
    expect(users.byId('missing'), isNull);
    expect(users.byId(null), isNull);
  });
}
