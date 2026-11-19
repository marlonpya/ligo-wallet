import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ligo_wallet/app/router/app_router.dart';

void main() {
  group('StreamListenable', () {
    test('notifica en cada evento del stream', () async {
      final controller = StreamController<int>();
      final listenable = StreamListenable(controller.stream);
      var notifications = 0;
      listenable.addListener(() => notifications++);

      controller
        ..add(1)
        ..add(2);
      await pumpEventQueue();

      expect(notifications, 2);
      listenable.dispose();
      await controller.close();
    });

    test('dispose cancela la suscripción', () async {
      final controller = StreamController<int>();
      StreamListenable(controller.stream).dispose();
      await pumpEventQueue();

      expect(controller.hasListener, isFalse);
      await controller.close();
    });
  });
}
