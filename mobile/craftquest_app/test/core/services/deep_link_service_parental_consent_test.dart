import 'package:craftquest_app/core/services/deep_link_service.dart';
import 'package:craftquest_app/features/auth/presentation/account_link_launch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkService.parseAccountLink', () {
    test('parses craftquest parental consent deep link', () {
      const token = 'abcdefghijklmnopqrstuvwxyz';

      final link = DeepLinkService.parseAccountLink(
        Uri.parse('craftquest://parental-consent/$token'),
      );

      expect(link?.kind, AccountLinkKind.parentalConsent);
      expect(link?.token, token);
    });

    test('parses https api parental consent universal link', () {
      const token = 'abcdefghijklmnopqrstuvwxyz';

      final link = DeepLinkService.parseAccountLink(
        Uri.parse('https://api.craftquestai.com/parental-consent/$token'),
      );

      expect(link?.kind, AccountLinkKind.parentalConsent);
      expect(link?.token, token);
    });
  });
}
