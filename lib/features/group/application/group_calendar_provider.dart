// ignore_for_file: non_constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'group_calendar_range_notifier.dart';
import 'group_calendar_range_state.dart';
import 'group_providers.dart';

final groupCalendarRangeProvider = StateNotifierProvider.autoDispose
    .family<GroupCalendarRangeNotifier, GroupCalendarRangeState, String>((
      ref,
      group_id,
    ) {
      return GroupCalendarRangeNotifier(
        repository: ref.watch(groupRepositoryProvider),
        group_id: group_id,
      );
    });
