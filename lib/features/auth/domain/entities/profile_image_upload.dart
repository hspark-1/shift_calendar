// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

/// 가입 완료 또는 프로필 수정 요청에 첨부할 사용자 선택 이미지.
class ProfileImageUpload {
  final Uint8List bytes;
  final String filename;
  final String? content_type;

  const ProfileImageUpload({
    required this.bytes,
    required this.filename,
    this.content_type,
  });
}
