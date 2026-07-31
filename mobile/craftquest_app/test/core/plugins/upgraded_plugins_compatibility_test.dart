import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Smoke tests: upgraded plugin APIs still match what the app uses.
void main() {
  group('share_plus', () {
    test('Share and XFile APIs used by sharing flows are available', () {
      expect(Share.share, isA<Function>());
      expect(Share.shareXFiles, isA<Function>());

      final file = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        name: 'craftquest_test.txt',
        mimeType: 'text/plain',
      );
      expect(file, isA<XFile>());
    });
  });

  group('sign_in_with_apple', () {
    test('OAuth APIs and cancellation error codes are available', () {
      expect(SignInWithApple.isAvailable, isA<Function>());
      expect(SignInWithApple.getAppleIDCredential, isA<Function>());
      expect(AuthorizationErrorCode.canceled, AuthorizationErrorCode.canceled);
      expect(
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.email,
      );
    });

    test('SignInWithAppleAuthorizationException exposes code', () {
      const error = SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled,
        message: 'User canceled',
      );
      expect(error.code, AuthorizationErrorCode.canceled);
    });
  });

  group('image_picker', () {
    test('ImagePicker.pickImage signature matches OptionImagePicker usage', () {
      final picker = ImagePicker();
      expect(picker.pickImage, isA<Function>());
      expect(ImageSource.gallery, ImageSource.gallery);
    });
  });

  group('desktop_drop', () {
    test('DropTarget widget is available for drag-and-drop zones', () {
      expect(
        () => DropTarget(
          onDragDone: (_) {},
          child: const SizedBox.shrink(),
        ),
        returnsNormally,
      );
    });
  });
}
