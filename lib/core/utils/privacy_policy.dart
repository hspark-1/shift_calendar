// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ExternalPageLauncher = Future<bool> Function(Uri url);
typedef PrivacyPolicyLauncher = ExternalPageLauncher;

final Uri privacy_policy_url = Uri.https('www.shiftmate.co.kr', '/privacy');
final Uri customer_support_url = Uri.https('www.shiftmate.co.kr', '/support');

Future<bool> launchExternalPage(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

Future<bool> launchPrivacyPolicy(Uri url) => launchExternalPage(url);

/// 로그인 상태와 관계없이 정책을 열고 실패하면 URL과 재시도 방법을 알린다.
Future<void> openPrivacyPolicy(
  BuildContext context, {
  PrivacyPolicyLauncher launcher = launchPrivacyPolicy,
}) => _openExternalPage(
  context,
  url: privacy_policy_url,
  page_name: '개인정보처리방침',
  launcher: launcher,
);

Future<void> openCustomerSupport(
  BuildContext context, {
  ExternalPageLauncher launcher = launchExternalPage,
}) => _openExternalPage(
  context,
  url: customer_support_url,
  page_name: '고객 지원',
  launcher: launcher,
);

Future<void> _openExternalPage(
  BuildContext context, {
  required Uri url,
  required String page_name,
  required ExternalPageLauncher launcher,
}) async {
  try {
    if (await launcher(url)) return;
  } on Exception {
    // 플랫폼에서 브라우저를 열지 못한 경우 아래 안내를 표시한다.
  }
  if (!context.mounted) return;
  await showCupertinoDialog<void>(
    context: context,
    builder: (dialog_context) => CupertinoAlertDialog(
      title: const Text('페이지 열기 실패'),
      content: Text(
        '$page_name 페이지를 열지 못했습니다. 잠시 후 다시 시도해 주세요.\n'
        '$url',
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialog_context).pop(),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}
