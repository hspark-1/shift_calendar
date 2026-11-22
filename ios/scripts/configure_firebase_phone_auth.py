#!/usr/bin/env python3
"""Configure only the built app's Phone Auth callback, using Flutter defines."""

import base64
import os
import plistlib
import re
from pathlib import Path


def configurePhoneAuth(environment):
    defines = {}
    for encoded in environment.get('DART_DEFINES', '').split(','):
        if not encoded:
            continue
        try:
            decoded = base64.b64decode(encoded, validate=True).decode('utf-8')
        except (ValueError, UnicodeDecodeError) as error:
            raise ValueError('Invalid Flutter build defines') from error
        key, separator, value = decoded.partition('=')
        if separator:
            defines[key] = value
    mode = environment.get('FLUTTER_BUILD_MODE')
    debug = mode == 'debug' if mode else environment.get('CONFIGURATION', '').startswith('Debug')
    key = 'FIREBASE_STAGE_IOS_APP_ID' if debug else 'FIREBASE_PROD_IOS_APP_ID'
    app_id = defines.get(key, '')
    if app_id and not re.fullmatch(r'1:[0-9]+:ios:[a-fA-F0-9]+', app_id):
        raise ValueError('Invalid Firebase iOS App ID for build configuration')
    path = Path(environment['TARGET_BUILD_DIR']) / environment['INFOPLIST_PATH']
    with path.open('rb') as file:
        config = plistlib.load(file)
    url_types = [entry for entry in config.get('CFBundleURLTypes', [])
                 if entry.get('CFBundleURLName') != 'FirebasePhoneAuth']
    if app_id:
        url_types.append({
            'CFBundleURLName': 'FirebasePhoneAuth',
            'CFBundleTypeRole': 'Editor',
            'CFBundleURLSchemes': ['app-' + app_id.replace(':', '-')],
        })
    config['CFBundleURLTypes'] = url_types
    with path.open('wb') as file:
        plistlib.dump(config, file, fmt=plistlib.FMT_BINARY, sort_keys=False)


if __name__ == '__main__':
    configurePhoneAuth(os.environ)
