import 'package:done_today/storage/hive/hive_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ActivityView { heatmap, list, calendar }

final viewNotifierProvider = NotifierProvider<ViewNotifier, ActivityView>(() {
  return ViewNotifier();
});

class ViewNotifier extends Notifier<ActivityView> {
  @override
  ActivityView build() {
    Future.microtask(() => _initializeView());
    return ActivityView.heatmap;
  }

  Future<void> _initializeView() async {
    try {
      final index = HiveService.getActivityViewIndex();
      if (index != null && index < ActivityView.values.length) {
        state = ActivityView.values[index];
      }
    } catch (e) {
      // On error, keep default state
    }
  }

  Future<void> toggleView(ActivityView view) async {
    state = view;
    await HiveService.setActivityViewIndex(view.index);
  }
}
