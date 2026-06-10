import 'package:dio/dio.dart';
import 'package:e_rupaiya/constants/api_constants.dart';
import 'package:e_rupaiya/features/auth/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockHTTPClient extends Mock implements Dio {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthRepository authRepository;
  late MockHTTPClient mockDioClient;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockDioClient = MockHTTPClient();
    mockSecureStorage = MockFlutterSecureStorage();
    authRepository = AuthRepository(
      dio: mockDioClient,
      secureStorage: mockSecureStorage,
    );
  });

  group('AuthRepository - verifyOtp', () {
    test('posts mobile and otp payload', () async {
      const mobile = '9552529513';
      const otp = '1234';

      when(
        () => mockDioClient.post(
          ApiConstants.verifyOtpEndpoint,
          data: {
            'mobile': mobile,
            'otp': otp,
          },
        ),
      ).thenAnswer(
        (_) async => Response(
          data: const {
            'success': true,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConstants.verifyOtpEndpoint),
        ),
      );

      await authRepository.verifyOtp(mobile: mobile, otp: otp);

      verify(
        () => mockDioClient.post(
          ApiConstants.verifyOtpEndpoint,
          data: {
            'mobile': mobile,
            'otp': otp,
          },
        ),
      ).called(1);
    });
  });

  group('AuthRepository - requestForgotPinOtp', () {
    test('posts mobile and appHash payload', () async {
      const mobile = '9552529513';
      const appHash = '+s+TkP8jIGp';

      when(
        () => mockDioClient.post(
          ApiConstants.requestForgotPinOtpEndpoint,
          data: {
            'mobile': mobile,
            'appHash': appHash,
          },
        ),
      ).thenAnswer(
        (_) async => Response(
          data: const {
            'success': true,
            'message': 'OTP sent',
          },
          statusCode: 200,
          requestOptions:
              RequestOptions(path: ApiConstants.requestForgotPinOtpEndpoint),
        ),
      );

      final message = await authRepository.requestForgotPinOtp(
        mobile: mobile,
        appHash: appHash,
      );

      expect(message, 'OTP sent');
      verify(
        () => mockDioClient.post(
          ApiConstants.requestForgotPinOtpEndpoint,
          data: {
            'mobile': mobile,
            'appHash': appHash,
          },
        ),
      ).called(1);
    });
  });

  group('AuthRepository - logout', () {
    test('deletes all user-related keys from secure storage', () async {
      when(() => mockSecureStorage.read(key: 'refreshToken'))
          .thenAnswer((_) async => null);
      when(
        () => mockSecureStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});

      await authRepository.logout();

      verify(() => mockSecureStorage.read(key: 'refreshToken')).called(1);
      verify(() => mockSecureStorage.delete(key: 'accessToken')).called(1);
      verify(() => mockSecureStorage.delete(key: 'refreshToken')).called(1);
      verify(() => mockSecureStorage.delete(key: 'tokenType')).called(1);
      verify(() => mockSecureStorage.delete(key: 'tokenExpiresAt')).called(1);
      verify(() => mockSecureStorage.delete(key: 'userId')).called(1);
      verify(() => mockSecureStorage.delete(key: 'mobile')).called(1);
      verifyNoMoreInteractions(mockSecureStorage);
    });
  });
}
