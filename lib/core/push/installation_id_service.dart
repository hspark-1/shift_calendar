// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

final installationIdServiceProvider = Provider<InstallationIdService>((ref) {
  return InstallationIdService();
});

class InstallationIdService {
  static const String _installation_id_key = 'push_installation_id';

  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  InstallationIdService({FlutterSecureStorage? storage, Uuid? uuid})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          ),
      _uuid = uuid ?? const Uuid();

  Future<String> getOrCreate() async {
    final stored_id = await _storage.read(key: _installation_id_key);
    if (stored_id != null && Uuid.isValidUUID(fromString: stored_id)) {
      return stored_id;
    }
    final installation_id = _uuid.v4();
    await _storage.write(key: _installation_id_key, value: installation_id);
    return installation_id;
  }
}
