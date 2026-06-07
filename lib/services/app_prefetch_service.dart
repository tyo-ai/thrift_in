import 'dart:async';

import 'cart_service.dart';
import 'chat_service.dart';
import 'notification_service.dart';
import 'order_service.dart';
import 'product_service.dart';
import 'user_service.dart';

class AppPrefetchService {
  static final AppPrefetchService instance = AppPrefetchService._();

  AppPrefetchService._();

  bool _isWarming = false;

  Future<void> warmCritical() async {
    await Future.wait([
      ProductService().getProducts(limit: ProductService.defaultPageSize),
      ProductService().getLiveProducts(limit: 6),
    ]).timeout(const Duration(seconds: 3));
  }

  void warmBackground() {
    if (_isWarming) return;
    _isWarming = true;

    unawaited(
      _warmBackground()
          .whenComplete(() {
            _isWarming = false;
          })
          .catchError((_) {}),
    );
  }

  Future<void> warmAfterLogin() async {
    await warmCritical();
    warmBackground();
  }

  Future<void> _warmBackground() async {
    final userId = UserService.currentUserId;
    if (userId == null) return;

    await Future.wait([
      ProductService().getFavoriteProducts(),
      CartService().getCartItems(),
      OrderService().getOrdersByBuyer(userId),
      NotificationService().getNotifications(),
      ChatService().getRoomsForUser(userId),
    ]).timeout(const Duration(seconds: 6));
  }
}
