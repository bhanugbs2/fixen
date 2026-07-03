import 'package:flutter_test/flutter_test.dart';
import 'package:fixen/common/validators/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('Email validator returns error for empty or invalid email', () {
      expect(Validators.validateEmail(''), 'Email address is required');
      expect(Validators.validateEmail(null), 'Email address is required');
      expect(Validators.validateEmail('invalid-email'), 'Please enter a valid email address');
      expect(Validators.validateEmail('test@com'), 'Please enter a valid email address');
      expect(Validators.validateEmail('user@domain.com'), null);
    });

    test('Password validator enforces length constraint', () {
      expect(Validators.validatePassword(''), 'Password is required');
      expect(Validators.validatePassword(null), 'Password is required');
      expect(Validators.validatePassword('12345'), 'Password must be at least 6 characters long');
      expect(Validators.validatePassword('123456'), null);
    });

    test('Confirm password validator matches passwords', () {
      expect(Validators.validateConfirmPassword('', '123456'), 'Confirm password is required');
      expect(Validators.validateConfirmPassword('12345', '123456'), 'Passwords do not match');
      expect(Validators.validateConfirmPassword('123456', '123456'), null);
    });

    test('Phone validator checks digits and length constraints', () {
      expect(Validators.validatePhone(''), 'Phone number is required');
      expect(Validators.validatePhone(null), 'Phone number is required');
      expect(Validators.validatePhone('1234'), 'Please enter a valid phone number');
      expect(Validators.validatePhone('9876543210'), null);
      expect(Validators.validatePhone('+919876543210'), null);
    });

    test('OTP validator enforces 6 digit digits constraint', () {
      expect(Validators.validateOtp(''), 'OTP is required');
      expect(Validators.validateOtp(null), 'OTP is required');
      expect(Validators.validateOtp('12345'), 'OTP must be exactly 6 digits');
      expect(Validators.validateOtp('12345a'), 'OTP must contain only numbers');
      expect(Validators.validateOtp('123456'), null);
    });

    test('Gov ID validator checks minimum length rules', () {
      expect(Validators.validateGovId(''), 'Government ID is required');
      expect(Validators.validateGovId(null), 'Government ID is required');
      expect(Validators.validateGovId('W1'), 'Please enter a valid Government ID');
      expect(Validators.validateGovId('W12345'), null);
    });
  });
}
