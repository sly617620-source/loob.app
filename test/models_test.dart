// test/models_test.dart
//
// اختبارات وحدة (Unit Tests) حقيقية لمنطق النماذج (Models) الصرف —
// أي بدون أي اعتماد على Firebase. عمداً لم نستخدم اختبار
// testWidgets(pumpWidget(MyApp())) الشائع، لأن MyApp() يتطلب
// Firebase.initializeApp() الذي يعمل فقط داخل main() الحقيقي، وسيفشل
// هذا الاختبار فورًا في أي بيئة CI بدون محاكاة (mocking) لـ Firebase.
// هذه الاختبارات تغطي النماذج الفعلية المستخدمة في التطبيق.

import 'package:flutter_test/flutter_test.dart';
import 'package:loob/models/product_model.dart';
import 'package:loob/models/coupon_model.dart';
import 'package:loob/models/affiliate_model.dart';
import 'package:loob/models/order_model.dart';

void main() {
  group('Product', () {
    test('isOnSale يكون صحيحاً فقط عند وجود سعر أصلي أعلى من السعر الحالي', () {
      final onSale = Product(
        id: 'p1',
        title: 'منتج',
        description: 'وصف',
        sellerId: 's1',
        sellerName: 'بائع',
        sellerAvatar: 'ب',
        price: 50,
        originalPrice: 100,
        type: ProductType.digital,
        images: const [],
        tags: const [],
        category: 'فئة',
        features: const [],
        createdAt: DateTime.now(),
      );
      final notOnSale = Product(
        id: 'p2',
        title: 'منتج',
        description: 'وصف',
        sellerId: 's1',
        sellerName: 'بائع',
        sellerAvatar: 'ب',
        price: 100,
        type: ProductType.digital,
        images: const [],
        tags: const [],
        category: 'فئة',
        features: const [],
        createdAt: DateTime.now(),
      );

      expect(onSale.isOnSale, isTrue);
      expect(notOnSale.isOnSale, isFalse);
    });

    test('discountPercent يحسب النسبة الصحيحة ولا يقسم على صفر', () {
      final product = Product(
        id: 'p3',
        title: 'منتج',
        description: 'وصف',
        sellerId: 's1',
        sellerName: 'بائع',
        sellerAvatar: 'ب',
        price: 75,
        originalPrice: 100,
        type: ProductType.digital,
        images: const [],
        tags: const [],
        category: 'فئة',
        features: const [],
        createdAt: DateTime.now(),
      );
      final noOriginal = Product(
        id: 'p4',
        title: 'منتج',
        description: 'وصف',
        sellerId: 's1',
        sellerName: 'بائع',
        sellerAvatar: 'ب',
        price: 75,
        type: ProductType.digital,
        images: const [],
        tags: const [],
        category: 'فئة',
        features: const [],
        createdAt: DateTime.now(),
      );

      expect(product.discountPercent, closeTo(25, 0.001));
      expect(noOriginal.discountPercent, 0);
    });
  });

  group('Coupon', () {
    test('isValid يعتمد على تاريخ الصلاحية وعدد الاستخدامات', () {
      final valid = Coupon(
        id: 'c1',
        code: 'SAVE20',
        discountPercent: 20,
        validUntil: DateTime.now().add(const Duration(days: 10)),
        maxUses: 10,
        usedCount: 5,
      );
      final expired = Coupon(
        id: 'c2',
        code: 'OLD10',
        discountPercent: 10,
        validUntil: DateTime.now().subtract(const Duration(days: 1)),
      );
      final maxedOut = Coupon(
        id: 'c3',
        code: 'LIMITED',
        discountPercent: 50,
        validUntil: DateTime.now().add(const Duration(days: 10)),
        maxUses: 5,
        usedCount: 5,
      );

      expect(valid.isValid, isTrue);
      expect(expired.isValid, isFalse);
      expect(maxedOut.isValid, isFalse);
    });

    test('isValid يعود false بعد تعطيل الكوبون يدوياً', () {
      final coupon = Coupon(
        id: 'c4',
        code: 'DISABLED',
        discountPercent: 15,
        validUntil: DateTime.now().add(const Duration(days: 10)),
        isActive: false,
      );
      expect(coupon.isValid, isFalse);
    });
  });

  group('Affiliate', () {
    test('conversionRate يحسب النسبة الصحيحة ولا يقسم على صفر', () {
      final withClicks = Affiliate(
        id: 'a1',
        userId: 'u1',
        referralCode: 'ref_123',
        totalClicks: 40,
        totalConversions: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final noClicks = Affiliate(
        id: 'a2',
        userId: 'u2',
        referralCode: 'ref_456',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(withClicks.conversionRate, closeTo(0.25, 0.001));
      expect(noClicks.conversionRate, 0.0);
    });

    test('earningsPerClick لا يقسم على صفر عند عدم وجود نقرات', () {
      final affiliate = Affiliate(
        id: 'a3',
        userId: 'u3',
        referralCode: 'ref_789',
        totalEarnings: 100,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(affiliate.earningsPerClick, 0.0);
    });
  });

  group('Order', () {
    test('يحوّل من وإلى JSON دون فقد البيانات', () {
      final order = Order(
        id: 'o1',
        productId: 'p1',
        productTitle: 'منتج تجريبي',
        buyerId: 'u1',
        sellerId: 's1',
        amount: 49.0,
        status: OrderStatus.completed,
        createdAt: DateTime.parse('2026-01-01T00:00:00.000'),
      );
      final json = order.toJson();
      final restored = Order.fromJson(json);

      expect(restored.id, order.id);
      expect(restored.amount, order.amount);
      expect(restored.status, order.status);
    });
  });
}
