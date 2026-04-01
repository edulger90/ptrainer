import 'package:flutter_test/flutter_test.dart';
import 'package:ptrainer/models/user.dart';
import 'package:ptrainer/services/auth_controller.dart';
import 'package:ptrainer/services/auth_service.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({
    this.userExistsValue = false,
    this.savedUsername,
    this.authenticatedUser,
    this.throwOnUserExists = false,
  });

  User? authenticatedUser;
  String? savedUsername;
  bool userExistsValue;
  bool throwOnUserExists;

  final List<({String username, String email, String password})>
  registeredUsers = [];
  final List<String> persistedUsernames = [];

  @override
  Future<User?> authenticate({
    required String username,
    required String password,
  }) async {
    return authenticatedUser;
  }

  @override
  Future<String?> loadSavedUsername() async => savedUsername;

  @override
  Future<void> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    registeredUsers.add((username: username, email: email, password: password));
    userExistsValue = true;
  }

  @override
  Future<void> saveUsername(String username) async {
    persistedUsernames.add(username);
  }

  @override
  Future<bool> userExists() async {
    if (throwOnUserExists) {
      throw Exception('userExists failed');
    }
    return userExistsValue;
  }
}

void main() {
  group('AuthController', () {
    test(
      'loadInitialState returns saved username and login mode for existing user',
      () async {
        final controller = AuthController(
          authService: FakeAuthService(
            userExistsValue: true,
            savedUsername: 'coach',
          ),
        );

        final state = await controller.loadInitialState();

        expect(state.userExists, isTrue);
        expect(state.isLogin, isTrue);
        expect(state.savedUsername, 'coach');
      },
    );

    test(
      'submit returns success user on valid login and persists username',
      () async {
        final fakeService = FakeAuthService(
          authenticatedUser: User(
            username: 'coach',
            email: 'coach@example.com',
            password: 'hash',
          ),
        );
        final controller = AuthController(authService: fakeService);

        final result = await controller.submit(
          isLogin: true,
          username: 'Coach',
          email: '',
          password: 'Password1',
        );

        expect(result.user?.username, 'coach');
        expect(result.shouldClearPassword, isTrue);
        expect(fakeService.persistedUsernames, ['coach']);
      },
    );

    test('submit locks login after five failed attempts', () async {
      final controller = AuthController(
        authService: FakeAuthService(authenticatedUser: null),
        clock: () => DateTime(2026, 4, 1, 10, 0, 0),
      );

      for (var i = 0; i < 5; i++) {
        await controller.submit(
          isLogin: true,
          username: 'coach',
          email: '',
          password: 'wrongpass',
        );
      }

      final result = await controller.submit(
        isLogin: true,
        username: 'coach',
        email: '',
        password: 'wrongpass',
      );

      expect(result.message?.code, AuthMessageCode.tooManyAttempts);
      expect(result.message?.remainingSeconds, 30);
    });

    test(
      'submit validates registration and switches back to login on success',
      () async {
        final fakeService = FakeAuthService();
        final controller = AuthController(authService: fakeService);

        final result = await controller.submit(
          isLogin: false,
          username: 'coach',
          email: 'coach@example.com',
          password: 'Password1',
        );

        expect(result.message?.code, AuthMessageCode.registrationSuccess);
        expect(result.message?.isSuccess, isTrue);
        expect(result.shouldSwitchToLogin, isTrue);
        expect(result.shouldClearPassword, isTrue);
        expect(result.userExists, isTrue);
        expect(fakeService.registeredUsers.single.username, 'coach');
      },
    );
  });
}
