// ignore_for_file: non_constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../calendar/application/calendar_range_notifier.dart';
import '../../../calendar/application/calendar_range_state.dart';
import '../../data/services/friend_service.dart';

final friendCalendarRangeProvider = StateNotifierProvider.autoDispose
    .family<CalendarRangeNotifier, CalendarRangeState, String>((
      ref,
      friend_user_id,
    ) {
      final service = ref.watch(friendServiceProvider);
      return CalendarRangeNotifier(
        loader: ({required start_date, required end_date}) async {
          final response = await service.getFriendCalendarRange(
            friendUserId: friend_user_id,
            startDate: start_date,
            endDate: end_date,
          );
          return response.data;
        },
      );
    });
