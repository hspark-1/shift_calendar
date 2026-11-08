// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';

final profileImageBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, String>((ref, image_url) async {
      final cancel_token = CancelToken();
      ref.onDispose(cancel_token.cancel);
      final response = await ref
          .watch(dioProvider)
          .get<List<int>>(
            image_url,
            options: Options(
              responseType: ResponseType.bytes,
              followRedirects: false,
              headers: {'Accept': 'image/*'},
            ),
            cancelToken: cancel_token,
          );
      return Uint8List.fromList(response.data!);
    });

/// 관리 이미지에만 앱 인증을 적용하고 외부 OAuth 이미지는 직접 표시한다.
class ProfileImage extends ConsumerWidget {
  final String image_url;
  final Widget fallback;

  const ProfileImage({
    super.key,
    required this.image_url,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (image_url.trim().isEmpty) return fallback;
    final base_uri = Uri.parse(ApiConstants.base_url);
    final uri = base_uri.resolve(image_url);
    final is_managed =
        uri.origin == base_uri.origin &&
        RegExp(r'^/api/v1/profile-images/[^/]+$').hasMatch(uri.path);
    if (!is_managed) {
      return Image.network(
        uri.toString(),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return ref
        .watch(profileImageBytesProvider(uri.toString()))
        .when(
          data: (bytes) => Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          ),
          loading: () => fallback,
          error: (_, _) => fallback,
        );
  }
}
