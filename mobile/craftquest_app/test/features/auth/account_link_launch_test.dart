import 'package:craftquest_app/features/auth/presentation/account_link_launch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseAccountLinkFromUri', () {
    const token = 'gEF7mdfBlvtXOt5aUwYeyS07uigaGyKDZY6JJ0ixF5I';

    test('parses parental consent web url with query token', () {
      final link = parseAccountLinkFromUri(
        Uri.parse('https://app.craftquestai.com/parental-consent?token=$token'),
      );

      expect(link?.kind, AccountLinkKind.parentalConsent);
      expect(link?.token, token);
    });

    test('parses parental consent api landing path token', () {
      final link = parseAccountLinkFromUri(
        Uri.parse('https://api.craftquestai.com/parental-consent/$token'),
      );

      expect(link?.kind, AccountLinkKind.parentalConsent);
      expect(link?.token, token);
    });

    test('returns null for unrelated paths', () {
      expect(
        parseAccountLinkFromUri(Uri.parse('https://app.craftquestai.com/')),
        isNull,
      );
    });
  });
}
