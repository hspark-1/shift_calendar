"""Run with: python3 -m unittest discover -s ios/scripts -p 'test_*.py'."""

import base64
import plistlib
import tempfile
import unittest
from pathlib import Path

from configure_firebase_phone_auth import configurePhoneAuth


class PhoneAuthConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name) / 'Runner.app' / 'Info.plist'
        self.path.parent.mkdir()
        self.original = {'CFBundleURLTypes': [
            {'CFBundleURLName': 'kakao', 'CFBundleURLSchemes': ['kakao-original']},
            {'CFBundleURLName': 'FirebasePhoneAuth', 'CFBundleURLSchemes': ['stale']},
        ], 'CFBundleIdentifier': 'com.hspark.shiftmate', 'UIBackgroundModes': ['remote-notification']}
        self.path.write_bytes(plistlib.dumps(self.original))
        defines = ['FIREBASE_STAGE_IOS_APP_ID=1:123:ios:abcdef',
                   'FIREBASE_PROD_IOS_APP_ID=1:456:ios:012345']
        self.environment = {
            'DART_DEFINES': ','.join(base64.b64encode(item.encode()).decode() for item in defines),
            'TARGET_BUILD_DIR': self.directory.name,
            'INFOPLIST_PATH': 'Runner.app/Info.plist',
            'CONFIGURATION': 'Debug',
        }

    def schemes(self):
        return plistlib.loads(self.path.read_bytes())['CFBundleURLTypes']

    def test_debug_stage_and_release_profile_production(self):
        for mode, app_id in [('debug', '1-123-ios-abcdef'),
                             ('release', '1-456-ios-012345'),
                             ('profile', '1-456-ios-012345')]:
            with self.subTest(mode=mode):
                self.environment['FLUTTER_BUILD_MODE'] = mode
                configurePhoneAuth(self.environment)
                configurePhoneAuth(self.environment)
                self.assertEqual(self.schemes(), [self.original['CFBundleURLTypes'][0], {
                    'CFBundleURLName': 'FirebasePhoneAuth', 'CFBundleTypeRole': 'Editor',
                    'CFBundleURLSchemes': ['app-' + app_id],
                }])
                config = plistlib.loads(self.path.read_bytes())
                self.assertEqual(config['UIBackgroundModes'], ['remote-notification'])
                self.assertEqual(config['CFBundleIdentifier'], 'com.hspark.shiftmate')

    def test_missing_defines_removes_only_own_stale_scheme(self):
        self.environment['DART_DEFINES'] = ''
        configurePhoneAuth(self.environment)
        self.assertEqual(self.schemes(), self.original['CFBundleURLTypes'][:1])

    def test_invalid_input_fails_before_mutation(self):
        original_bytes = self.path.read_bytes()
        for value in ['invalid-base64!', base64.b64encode(b'FIREBASE_STAGE_IOS_APP_ID=secret-invalid').decode()]:
            self.environment['DART_DEFINES'] = value
            with self.assertRaises(ValueError) as error:
                configurePhoneAuth(self.environment)
            self.assertNotIn('secret-invalid', str(error.exception))
            self.assertEqual(self.path.read_bytes(), original_bytes)


if __name__ == '__main__':
    unittest.main()
