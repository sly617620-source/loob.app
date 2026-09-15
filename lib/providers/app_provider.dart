import 'package:flutter/widgets.dart';
import '../services/app_controller.dart';

class AppProvider extends InheritedNotifier<AppController> {
  const AppProvider({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AppController of(BuildContext context, {bool listen = true}) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<AppProvider>()!
          .notifier!;
    } else {
      final widget = context
          .getElementForInheritedWidgetOfExactType<AppProvider>()
          ?.widget as AppProvider?;
      return widget!.notifier!;
    }
  }
}
