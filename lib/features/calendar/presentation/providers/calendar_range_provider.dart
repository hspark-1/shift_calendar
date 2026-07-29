// ignore_for_file: non_constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/calendar_range_notifier.dart';
import '../../application/calendar_range_state.dart';
import '../../data/services/calendar_service.dart';

final calendarRangeProvider =
    StateNotifierProvider.autoDispose<
      CalendarRangeNotifier,
      CalendarRangeState
    >((ref) {
      final service = ref.watch(calendarServiceProvider);
      return CalendarRangeNotifier(
        loader: ({required start_date, required end_date}) async {
          final response = await service.getCalendarRange(
            startDate: start_date,
            endDate: end_date,
          );
          return response.data;
        },
      );
    });
