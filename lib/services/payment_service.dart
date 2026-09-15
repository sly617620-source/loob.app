import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Service for handling real Stripe payment processing.
/// Replaces mock implementations with PaymentIntents, verification, and error handling.
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  bool _isInitialized = false;

  /// Initialize Stripe with publishable key.
  Future<void> initialize(String publishableKey) async {
    if (_isInitialized) return;
    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
    _isInitialized = true;
  }

  /// Create a payment intent via Cloud Function.
  Future<Map<String, dynamic>> _createPaymentIntent({
    required double amount,
    required String currency,
    String? customerId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final callable = _functions.httpsCallable('createPaymentIntent');
      final result = await callable.call({
        'amount': (amount * 100).round(), // Convert to cents
        'currency': currency.toLowerCase(),
        'customerId': customerId,
        'metadata': metadata,
      });
      return result.data as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Failed to create payment intent: ${e.message}');
    }
  }

  /// Process a payment using Stripe Payment Sheet.
  Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required String description,
    String? customerEmail,
    String? customerName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 1. Create payment intent on server
      final paymentIntentData = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        metadata: metadata,
      );

      // 2. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['clientSecret'],
          merchantDisplayName: 'Loob Platform',
          style: ThemeMode.system,
          billingDetails: BillingDetails(
            email: customerEmail,
            name: customerName,
          ),
          googlePay: const PaymentSheetGooglePay(
            merchantCountryCode: 'SA',
            testEnv: true,
          ),
          applePay: const PaymentSheetApplePay(
            merchantCountryCode: 'SA',
          ),
        ),
      );

      // 3. Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Confirm payment was successful
      final paymentIntent = await Stripe.instance.retrievePaymentIntent(
        paymentIntentData['clientSecret'],
      );

      if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        return PaymentResult(
          success: true,
          paymentIntentId: paymentIntent.id,
          amount: amount,
          currency: currency,
        );
      } else {
        return PaymentResult(
          success: false,
          errorMessage: 'Payment status: ${paymentIntent.status}',
        );
      }
    } on StripeException catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: e.error.localizedMessage ?? 'Payment failed',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        errorMessage: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Verify a payment status.
  Future<bool> verifyPayment(String paymentIntentId) async {
    try {
      final callable = _functions.httpsCallable('verifyPayment');
      final result = await callable.call({'paymentIntentId': paymentIntentId});
      return result.data['verified'] == true;
    } catch (e) {
      debugPrint('Payment verification failed: $e');
      return false;
    }
  }

  /// Refund a payment.
  Future<bool> refundPayment(String paymentIntentId, {double? amount}) async {
    try {
      final callable = _functions.httpsCallable('refundPayment');
      final result = await callable.call({
        'paymentIntentId': paymentIntentId,
        'amount': amount != null ? (amount * 100).round() : null,
      });
      return result.data['success'] == true;
    } catch (e) {
      debugPrint('Refund failed: $e');
      return false;
    }
  }

  /// Create a setup intent for saving cards.
  Future<String?> createSetupIntent(String customerId) async {
    try {
      final callable = _functions.httpsCallable('createSetupIntent');
      final result = await callable.call({'customerId': customerId});
      return result.data['clientSecret'] as String?;
    } catch (e) {
      debugPrint('Setup intent creation failed: $e');
      return null;
    }
  }
}

/// Result of a payment operation.
class PaymentResult {
  final bool success;
  final String? paymentIntentId;
  final double? amount;
  final String? currency;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    this.paymentIntentId,
    this.amount,
    this.currency,
    this.errorMessage,
  });

  @override
  String toString() => 'PaymentResult(success: $success, id: $paymentIntentId)';
}
