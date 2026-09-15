import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/coupon_model.dart';
import '../models/review_model.dart';
import '../models/analytics_model.dart';
import '../models/campaign_model.dart';
import '../models/submission_model.dart';
import 'mock_data.dart';
import '../services/firebase_service.dart';

/// Central app state controller.
///
/// Registered once via `Get.put(AppController(), permanent: true)` in
/// main.dart. Extends [ChangeNotifier] so it can be consumed either through
/// GetX (`AppController.to`) or through the `AppProvider` InheritedNotifier
/// used by the UI screens (`AppProvider.of(context)`), both of which are
/// used throughout the app.
class AppController extends ChangeNotifier {
  AppController();

  /// Convenience static accessor for GetX-style usage (`AppController.to`).
  static AppController get to => Get.find<AppController>();

  final FirebaseService _firebaseService = FirebaseService();

  User? user;
  bool get isAuthenticated => user != null;

  final List<Product> products = List<Product>.from(MockData.products);
  final List<Order> orders = List<Order>.from(MockData.orders);
  final List<Coupon> coupons = List<Coupon>.from(MockData.coupons);
  final List<Review> _reviews = List<Review>.from(MockData.reviews);
  final List<Product> cart = <Product>[];
  final List<Campaign> campaigns = List<Campaign>.from(MockData.campaigns);
  final List<Submission> submissions = List<Submission>.from(MockData.submissions);

  // ---------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------

  /// Restores an already-signed-in Firebase session (e.g. the app was
  /// closed and reopened after a successful login/registration) into
  /// [user], so the splash screen's auth check has something real to look
  /// at.
  ///
  /// BUG FIX: nothing previously populated [user] from Firebase on cold
  /// start - `AppController.user` was only ever set inside
  /// [signInWithEmail]/[registerWithEmail]. Firebase Auth itself persists
  /// the session across app restarts, but the app never asked it, so
  /// `isAuthenticated` was always `false` on launch and every returning,
  /// already-logged-in user was sent straight back to AuthScreen - which
  /// looks identical to "the account exists but I can't get into the app".
  Future<void> restoreSession() async {
    final fbUser = _firebaseService.currentUser;
    if (fbUser == null) return;
    final restoredUser = await _firebaseService.getUserFromFirestore(fbUser.uid);
    user = restoredUser ??
        User(
          id: fbUser.uid,
          email: fbUser.email ?? '',
          displayName: fbUser.displayName,
          photoUrl: fbUser.photoURL,
          createdAt: DateTime.now(),
        );
    notifyListeners();
  }

  /// Signs in with email/password. Returns `true` on success.
  ///
  /// BUG FIX: this used to catch every error from FirebaseService, log it
  /// with `debugPrint` (invisible to the user), and just return `false`.
  /// AuthScreen then showed the same generic "بيانات الدخول غير صحيحة" for
  /// *any* failure - a wrong password, a disabled account, no internet
  /// connection, a misconfigured Firebase project, etc. all looked
  /// identical to the user, which made the real problem impossible to
  /// diagnose. Real, specific auth errors are now rethrown so they reach
  /// AuthScreen's existing catch block, which already displays
  /// `e.toString()` to the user.
  Future<bool> signInWithEmail(String email, String password) async {
    final signedInUser = await _firebaseService.signInWithEmail(email, password);
    if (signedInUser == null) return false;
    user = signedInUser;
    notifyListeners();
    return true;
  }

  /// Registers a new account with email/password. Returns `true` on success.
  /// See [signInWithEmail] for why errors are rethrown instead of swallowed.
  Future<bool> registerWithEmail(
    String email,
    String password, {
    String? displayName,
    String? phoneNumber,
    UserRole role = UserRole.customer,
  }) async {
    final newUser = await _firebaseService.registerWithEmail(
      email,
      password,
      displayName: displayName,
      phoneNumber: phoneNumber,
      role: role,
    );
    if (newUser == null) return false;
    user = newUser;
    notifyListeners();
    return true;
  }

  /// Signs in with Google. Returns `true` on success, `false` if the user
  /// cancelled the picker (silently - not treated as an error). Real
  /// failures are rethrown - see [signInWithEmail] for why.
  Future<bool> signInWithGoogle() async {
    try {
      final signedInUser = await _firebaseService.signInWithGoogle();
      if (signedInUser == null) return false;
      user = signedInUser;
      notifyListeners();
      return true;
    } catch (e) {
      // FirebaseService throws a plain Exception (not FirebaseAuthException)
      // when the user dismisses the Google account picker - that's a normal
      // "changed their mind", not a failure worth surfacing as an error.
      if (e.toString().contains('cancelled by the user')) return false;
      rethrow;
    }
  }

  /// Signs in with Apple. Same cancel-is-not-an-error contract as
  /// [signInWithGoogle].
  Future<bool> signInWithApple() async {
    try {
      final signedInUser = await _firebaseService.signInWithApple();
      if (signedInUser == null) return false;
      user = signedInUser;
      notifyListeners();
      return true;
    } catch (e) {
      // Apple reports a cancelled sheet as AuthorizationErrorCode.canceled;
      // FirebaseService folds it into a plain Exception's message, so match
      // on that instead of the (already-unwrapped) original exception type.
      if (e.toString().contains('AuthorizationErrorCode.canceled')) return false;
      rethrow;
    }
  }

  /// Starts phone-number sign-in/registration by sending an SMS OTP.
  /// Thin pass-through to [FirebaseService.startPhoneVerification] - see
  /// there for what each callback means. On the (Android-only) instant
  /// auto-verification path, [user] is updated and listeners notified
  /// directly here, same as every other sign-in method.
  Future<void> startPhoneVerification({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onVerificationFailed,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
  }) {
    return _firebaseService.startPhoneVerification(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
      onCodeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      onAutoVerified: (autoVerifiedUser) {
        user = autoVerifiedUser;
        notifyListeners();
      },
    );
  }

  /// Finalizes phone sign-in with the OTP the user typed. Returns `true`
  /// on success; real failures are rethrown - see [signInWithEmail].
  Future<bool> confirmPhoneOTP(String verificationId, String smsCode) async {
    final signedInUser =
        await _firebaseService.signInWithPhoneNumberOTP(verificationId, smsCode);
    if (signedInUser == null) return false;
    user = signedInUser;
    notifyListeners();
    return true;
  }

  /// Resends the verification email to the current user. See
  /// [FirebaseService.sendEmailVerification].
  Future<void> sendEmailVerification() => _firebaseService.sendEmailVerification();

  /// Live check for gating protected routes behind a verified email - see
  /// [FirebaseService.isEmailVerified] for why this isn't just a cached
  /// field read.
  Future<bool> isEmailVerified() => _firebaseService.isEmailVerified();

  // ---------------------------------------------------------------------
  // Profile / settings
  // ---------------------------------------------------------------------

  /// Applies [updatedUser] locally right away (so Settings feels instant)
  /// then best-effort persists it to Firestore. Firestore failures are
  /// swallowed (same pattern as [signOut]) since the local session should
  /// keep working even if the write doesn't land.
  ///
  /// The account type (`role`) chosen at signup is intentionally
  /// non-negotiable from inside the app - per product requirement, it can
  /// only be changed by app management (e.g. directly in Firestore/an
  /// admin tool), never by the user editing their own profile. Rather than
  /// relying on every call site to remember not to change it, this method
  /// discards whatever `role` [updatedUser] carries and re-applies the
  /// role already on the current session - so even a future UI bug that
  /// re-introduces a role picker here couldn't actually change it without
  /// also touching this method deliberately. The real enforcement is
  /// still the Firestore security rule (see firestore.rules) - this is
  /// defense in depth, not a substitute for it, since a client-side-only
  /// guard can always be bypassed by calling Firestore directly.
  Future<void> updateProfile(User updatedUser) async {
    final lockedRole = user?.role ?? updatedUser.role;
    final safeUser = updatedUser.role == lockedRole
        ? updatedUser
        : updatedUser.copyWith(role: lockedRole);
    user = safeUser;
    notifyListeners();
    try {
      await _firebaseService.updateUserProfile(safeUser.id, safeUser.toJson());
    } catch (e) {
      debugPrint('updateProfile failed to persist: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseService.signOut();
    } catch (e) {
      debugPrint('signOut failed: $e');
    }
    user = null;
    cart.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Products / discovery
  // ---------------------------------------------------------------------

  List<Product> getFeaturedProducts() =>
      products.where((p) => p.isFeatured).toList();

  List<Product> getProductsByCategory(String category) {
    if (category.isEmpty || category == 'الكل') {
      return List<Product>.from(products);
    }
    return products.where((p) => p.category == category).toList();
  }

  List<Product> searchProducts(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<Product>.from(products);
    return products.where((p) {
      return p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  // ---------------------------------------------------------------------
  // Product management (seller)
  // ---------------------------------------------------------------------

  void addProduct(Product product) {
    products.insert(0, product);
    notifyListeners();
  }

  void updateProduct(Product updated) {
    final index = products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      products[index] = updated;
      notifyListeners();
    }
  }

  void deleteProduct(String productId) {
    products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Campaigns (campaign creator / content creator)
  // ---------------------------------------------------------------------

  List<Campaign> getCampaignsByCategory(String category) {
    if (category.isEmpty || category == 'الكل') {
      return List<Campaign>.from(campaigns);
    }
    return campaigns.where((c) => c.categories.contains(category)).toList();
  }

  List<Campaign> searchCampaigns(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List<Campaign>.from(campaigns);
    return campaigns.where((c) {
      return c.title.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.displayBrandName.toLowerCase().contains(q);
    }).toList();
  }

  /// Campaigns owned/created by [brandId] - shown on the campaign
  /// creator's own management dashboard.
  List<Campaign> getCampaignsByOwner(String brandId) =>
      campaigns.where((c) => c.brandId == brandId).toList();

  void addCampaign(Campaign campaign) {
    campaigns.insert(0, campaign);
    notifyListeners();
  }

  void updateCampaign(Campaign updated) {
    final index = campaigns.indexWhere((c) => c.id == updated.id);
    if (index != -1) {
      campaigns[index] = updated;
      notifyListeners();
    }
  }

  void deleteCampaign(String campaignId) {
    campaigns.removeWhere((c) => c.id == campaignId);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Submissions (a content creator's post against a campaign)
  // ---------------------------------------------------------------------

  List<Submission> getSubmissionsForUser(String userId) =>
      submissions.where((s) => s.influencerId == userId).toList();

  /// All submissions across every campaign owned by [brandId] - what a
  /// campaign creator reviews/approves.
  List<Submission> getSubmissionsForOwner(String brandId) {
    final ownedIds = getCampaignsByOwner(brandId).map((c) => c.id).toSet();
    return submissions.where((s) => ownedIds.contains(s.campaignId)).toList();
  }

  void submitToCampaign(Submission submission) {
    submissions.insert(0, submission);
    final index = campaigns.indexWhere((c) => c.id == submission.campaignId);
    if (index != -1) {
      campaigns[index] = campaigns[index]
          .copyWith(currentSubmissions: campaigns[index].currentSubmissions + 1);
    }
    notifyListeners();
  }

  void reviewSubmission(String submissionId, SubmissionStatus status, {String? feedback}) {
    final index = submissions.indexWhere((s) => s.id == submissionId);
    if (index == -1) return;
    submissions[index] = submissions[index].copyWith(
      status: status,
      feedback: feedback,
      reviewedAt: DateTime.now(),
    );
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Cart
  // ---------------------------------------------------------------------

  void addToCart(Product product) {
    if (cart.any((p) => p.id == product.id)) return;
    cart.add(product);
    notifyListeners();
  }

  void removeFromCart(String productId) {
    cart.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Reviews
  // ---------------------------------------------------------------------

  List<Review> getProductReviews(String productId) =>
      _reviews.where((r) => r.productId == productId).toList();

  void addReview(Review review) {
    _reviews.insert(0, review);

    final productIndex = products.indexWhere((p) => p.id == review.productId);
    if (productIndex != -1) {
      final product = products[productIndex];
      final productReviews = getProductReviews(review.productId);
      final avgRating =
          productReviews.fold<double>(0, (sum, r) => sum + r.rating) /
              productReviews.length;
      product.reviewsCount = productReviews.length;
      product.rating = double.parse(avgRating.toStringAsFixed(1));
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Coupons
  // ---------------------------------------------------------------------

  Coupon? applyCoupon(String code) {
    try {
      final coupon = coupons.firstWhere(
        (c) => c.code.toUpperCase() == code.trim().toUpperCase() && c.isValid,
      );
      return coupon;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Purchases
  // ---------------------------------------------------------------------

  /// Completes a purchase for [productId] on behalf of [buyerId].
  ///
  /// Accepts an optional [couponCode] (validated against [coupons]) and an
  /// optional [addressId] for future shipping-address support.
  Future<void> purchaseProduct(
    String productId,
    String buyerId, {
    String? couponCode,
    String? addressId,
  }) async {
    final productIndex = products.indexWhere((p) => p.id == productId);
    if (productIndex == -1) {
      throw Exception('Product not found: $productId');
    }
    final product = products[productIndex];

    double amount = product.price;
    Coupon? coupon;
    if (couponCode != null && couponCode.isNotEmpty) {
      coupon = applyCoupon(couponCode);
      if (coupon != null) {
        final discount = amount * (coupon.discountPercent / 100);
        final cappedDiscount =
            coupon.maxDiscount != null && discount > coupon.maxDiscount!
                ? coupon.maxDiscount!
                : discount;
        amount = (amount - cappedDiscount).clamp(0, product.price).toDouble();
        coupon.usedCount += 1;
      }
    }

    final order = Order(
      id: 'o_${DateTime.now().millisecondsSinceEpoch}',
      productId: product.id,
      productTitle: product.title,
      buyerId: buyerId,
      sellerId: product.sellerId,
      amount: amount,
      platformFee: double.parse((amount * 0.1).toStringAsFixed(2)),
      status: OrderStatus.completed,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      licenseKey: product.licenseKey,
      couponCode: coupon?.code,
      discountAmount: coupon != null ? product.price - amount : null,
    );

    orders.insert(0, order);
    product.salesCount += 1;
    cart.removeWhere((p) => p.id == productId);

    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Seller analytics
  // ---------------------------------------------------------------------

  SellerAnalytics getSellerAnalytics(String sellerId) {
    final sellerProducts = products.where((p) => p.sellerId == sellerId).toList();
    final sellerOrders = orders.where((o) => o.sellerId == sellerId).toList();

    final totalRevenue = sellerOrders.fold<double>(0, (sum, o) => sum + o.amount);
    final totalSales = sellerOrders.length;
    final totalViews = sellerProducts.fold<int>(0, (sum, p) => sum + (p.salesCount * 8));
    final conversionRate = totalViews > 0 ? (totalSales / totalViews) * 100 : 0.0;

    final dailySalesMap = <String, DailySale>{};
    for (final o in sellerOrders) {
      final key = '${o.createdAt.year}-${o.createdAt.month}-${o.createdAt.day}';
      final existing = dailySalesMap[key];
      if (existing == null) {
        dailySalesMap[key] = DailySale(date: o.createdAt, revenue: o.amount, sales: 1);
      } else {
        dailySalesMap[key] = DailySale(
          date: existing.date,
          revenue: existing.revenue + o.amount,
          sales: existing.sales + 1,
        );
      }
    }

    final categoryMap = <String, CategoryStat>{};
    for (final p in sellerProducts) {
      final existing = categoryMap[p.category];
      final productOrders = sellerOrders.where((o) => o.productId == p.id);
      final revenue = productOrders.fold<double>(0, (sum, o) => sum + o.amount);
      if (existing == null) {
        categoryMap[p.category] =
            CategoryStat(category: p.category, sales: productOrders.length, revenue: revenue);
      } else {
        categoryMap[p.category] = CategoryStat(
          category: p.category,
          sales: existing.sales + productOrders.length,
          revenue: existing.revenue + revenue,
        );
      }
    }

    final topProducts = sellerProducts.map((p) {
      final productOrders = sellerOrders.where((o) => o.productId == p.id);
      return ProductPerformance(
        productId: p.id,
        title: p.title,
        views: p.salesCount * 8,
        sales: productOrders.length,
        revenue: productOrders.fold<double>(0, (sum, o) => sum + o.amount),
      );
    }).toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return SellerAnalytics(
      totalRevenue: totalRevenue,
      totalSales: totalSales,
      totalViews: totalViews,
      conversionRate: conversionRate,
      dailySales: dailySalesMap.values.toList(),
      categoryStats: categoryMap.values.toList(),
      topProducts: topProducts,
    );
  }
}
