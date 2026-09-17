/**
 * ============================================================
 *  Loob — Honeypot & Login Monitoring (Firebase Cloud Functions)
 * ============================================================
 *
 * fakeApi:        نقطة API وهمية تبدو كأنها endpoint حقيقي (مثل /admin أو
 *                  /api/v1/users) لا يستخدمها التطبيق الحقيقي إطلاقاً —
 *                  أي طلب يصلها هو على الأرجح من بوت/سكربت استكشاف يبحث
 *                  عن ثغرات. نسجّل معلومات الطلب في Firestore.
 *
 * monitorLogins:  Cloud Function Trigger يراقب محاولات تسجيل الدخول
 *                  الفاشلة المتكررة عبر Firebase Auth (blocking function)
 *                  ويسجّل الأنماط المشبوهة في نفس مجموعة الـ logs.
 *
 * كل السجلات تُحفظ في مجموعة Firestore: honeypot_logs
 * (نفس المجموعة التي يكتب لها تطبيق Flutter من BotProtection/FirebaseService،
 *  لتوحيد المراقبة بين الواجهة الأمامية والخلفية في مكان واحد).
 */

const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const { beforeUserSignedIn } = require('firebase-functions/v2/identity');
const { logger } = require('firebase-functions');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const Stripe = require('stripe');

admin.initializeApp();
const db = admin.firestore();

// مفاتيح Stripe السرية — تُدار عبر Secret Manager (لا تُكتب في الكود أبداً).
// تُضبط عبر: firebase functions:secrets:set STRIPE_SECRET_KEY
//            firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');
const stripeWebhookSecret = defineSecret('STRIPE_WEBHOOK_SECRET');

// نسبة عمولة المنصة الافتراضية ورسوم المعالجة — يجب أن تطابق القيم
// المستخدمة في lib/main.dart (WhopPaymentService) لضمان اتساق الحسابات
// بين ما يراه المستخدم في الواجهة وما يُحفظ فعلياً في الخادم.
const PLATFORM_FEE_PERCENT = 0.03;
const PROCESSING_FEE_PERCENT = 0.027;
const PROCESSING_FEE_FIXED = 0.30;

// ============================================================
//  1) fakeApi — Honeypot Endpoint
// ============================================================
//
// انشرها ثم أضف رابطها في أماكن لا يزورها إلا الزاحف الآلي: robots.txt
// (بحيث تُمنع فهرستها لكن تبقى مكتوبة، فالبوتات السيئة تتجاهل robots.txt
// وتزورها فعلاً)، أو كرابط مخفي CSS في صفحة الويب الرئيسية.
//
// مثال الرابط بعد النشر:
// https://REGION-PROJECT_ID.cloudfunctions.net/fakeApi/admin
exports.fakeApi = onRequest({ cors: true }, async (req, res) => {
  try {
    const entry = {
      type: 'fake_api_hit',
      method: req.method,
      path: req.path,
      query: req.query || {},
      headers: {
        userAgent: req.get('user-agent') || 'unknown',
        referer: req.get('referer') || null,
      },
      ip: req.ip || req.headers['x-forwarded-for'] || 'unknown',
      body: typeof req.body === 'object' ? req.body : {},
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('honeypot_logs').add(entry);
    logger.warn('Honeypot hit', entry);

    // نُعيد رداً عادياً (200) يبدو كأنه API حقيقي حتى لا يشتبه المهاجم
    // أنه اكتُشف — بدل إرجاع خطأ واضح.
    res.status(200).json({ status: 'ok' });
  } catch (error) {
    logger.error('fakeApi error', error);
    // حتى في حال الخطأ، لا نكشف تفاصيل داخلية للمُستدعي
    res.status(200).json({ status: 'ok' });
  }
});

// ============================================================
//  2) monitorLogins — مراقبة تسجيلات الدخول عبر Firebase Auth
// ============================================================
//
// Blocking Function تعمل قبل إتمام كل عملية تسجيل دخول (Identity Platform).
// تتطلب تفعيل "Blocking Functions" من Firebase Console > Authentication > Triggers.
// لا تمنع تسجيل الدخول أبداً هنا (فقط تراقب/تسجّل) لتفادي حجب مستخدمين شرعيين
// بالخطأ؛ منطق الحظر الفعلي (rate limiting) يبقى من طرف تطبيق Flutter
// (BotProtection.checkRateLimit) لتفادي إيقاف الدخول عالمياً بخطأ في السحابة.
exports.monitorLogins = beforeUserSignedIn(async (event) => {
  const user = event.data;

  try {
    await db.collection('honeypot_logs').add({
      type: 'login_monitor',
      userId: user.uid,
      email: user.email || null,
      provider: event.credential?.providerId || 'unknown',
      isNewUser: event.additionalUserInfo?.isNewUser || false,
      ip: event.ipAddress || 'unknown',
      userAgent: event.userAgent || 'unknown',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    logger.error('monitorLogins logging error', error);
    // لا نرمي استثناءً هنا: خطأ في التسجيل يجب ألا يمنع تسجيل الدخول الفعلي
  }

  // لا نُعيد أي تعديل على بيانات المستخدم — فقط مراقبة سلبية
  return;
});

// ============================================================
//  3) createPaymentIntent — إنشاء عملية دفع حقيقية عبر Stripe
// ============================================================
//
// Callable Function يستدعيها تطبيق Flutter عبر cloud_functions
// (PaymentService.createPaymentIntent). تُنشئ Payment Intent فعلياً على
// خادم Stripe باستخدام المفتاح السري (لا يغادر الخادم أبداً)، وتُنشئ في
// نفس الوقت وثيقة طلب مبدئية بحالة "pending" في مجموعة orders — الحالة
// النهائية (completed/failed) لا تُحدَّث إلا من stripeWebhook أدناه.
exports.createPaymentIntent = onCall(
  { secrets: [stripeSecretKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول لإتمام عملية الشراء');
    }

    const {
      amount, currency, productId, productName, sellerId,
      affiliateId, affiliateCommission, couponCode, discountAmount,
    } = request.data;

    if (!amount || amount <= 0 || !currency || !productId || !sellerId) {
      throw new HttpsError('invalid-argument', 'بيانات الدفع غير مكتملة');
    }

    const stripe = Stripe(stripeSecretKey.value());
    const buyerId = request.auth.uid;

    // حساب الرسوم بنفس منطق الواجهة (WhopPaymentService.calculateFees في main.dart)
    const finalAmount = amount; // الخصم يكون قد طُبِّق بالفعل قبل الوصول هنا
    const platformFee = finalAmount * PLATFORM_FEE_PERCENT;
    const processingFee = (finalAmount * PROCESSING_FEE_PERCENT) + PROCESSING_FEE_FIXED;
    const affiliateFee = affiliateCommission || 0;
    const sellerEarnings = finalAmount - platformFee - processingFee - affiliateFee;

    // Stripe يتعامل بأصغر وحدة عملة (سنت للدولار)
    const amountInCents = Math.round(finalAmount * 100);

    try {
      const orderRef = db.collection('orders').doc();

      const paymentIntent = await stripe.paymentIntents.create({
        amount: amountInCents,
        currency: currency.toLowerCase(),
        automatic_payment_methods: { enabled: true },
        metadata: {
          orderId: orderRef.id,
          productId,
          buyerId,
          sellerId,
          affiliateId: affiliateId || '',
        },
      });

      await orderRef.set({
        productId,
        productName,
        buyerId,
        sellerId,
        amount: finalAmount,
        platformFee,
        processingFee,
        sellerEarnings,
        affiliateCommission: affiliateFee || null,
        affiliateId: affiliateId || null,
        status: 'pending',
        paymentMethod: 'card',
        transactionId: paymentIntent.id,
        couponCode: couponCode || null,
        discountAmount: discountAmount || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        completedAt: null,
      });

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        orderId: orderRef.id,
      };
    } catch (error) {
      logger.error('createPaymentIntent error', error);
      throw new HttpsError('internal', 'تعذّر إنشاء عملية الدفع، حاول مرة أخرى');
    }
  }
);

// ============================================================
//  4) stripeWebhook — تأكيد نتيجة الدفع من طرف Stripe (مصدر الحقيقة الوحيد)
// ============================================================
//
// نقطة نهاية تستقبلها Stripe مباشرة بعد كل حدث دفع، وتُحدِّث حالة الطلب في
// Firestore وفق التوقيع المُتحقَّق منه (Stripe-Signature) — لا نثق بأي
// إشارة نجاح قادمة من تطبيق العميل نفسه، لأنه يمكن تزييفها.
//
// بعد النشر، سجّل رابط هذه الدالة كـ Webhook Endpoint من Stripe Dashboard:
// https://REGION-PROJECT_ID.cloudfunctions.net/stripeWebhook
// واختر الأحداث: payment_intent.succeeded, payment_intent.payment_failed
exports.stripeWebhook = onRequest(
  { secrets: [stripeSecretKey, stripeWebhookSecret] },
  async (req, res) => {
    const stripe = Stripe(stripeSecretKey.value());
    const signature = req.headers['stripe-signature'];

    let event;
    try {
      event = stripe.webhooks.constructEvent(
        req.rawBody,
        signature,
        stripeWebhookSecret.value()
      );
    } catch (error) {
      logger.error('stripeWebhook signature verification failed', error);
      res.status(400).send('Webhook signature verification failed');
      return;
    }

    try {
      const paymentIntent = event.data.object;
      const orderId = paymentIntent.metadata?.orderId;

      if (!orderId) {
        res.status(200).json({ received: true });
        return;
      }

      const orderRef = db.collection('orders').doc(orderId);

      if (event.type === 'payment_intent.succeeded') {
        await orderRef.update({
          status: 'completed',
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // إشعار البائع بطلب جديد ناجح (Firebase Push Notifications — تُبنى تفصيلياً
        // في الخطوة 2 القادمة؛ نكتفي هنا بتسجيل الحدث في Firestore ليلتقطه
        // notification_service.dart لاحقاً عبر مستمع مباشر على orders/{orderId}).
        logger.info(`Order ${orderId} completed via Stripe`);
      } else if (event.type === 'payment_intent.payment_failed') {
        await orderRef.update({ status: 'cancelled' });
        logger.warn(`Order ${orderId} payment failed`);
      }

      res.status(200).json({ received: true });
    } catch (error) {
      logger.error('stripeWebhook processing error', error);
      // 200 حتى مع الخطأ الداخلي — لتفادي إعادة محاولة Stripe اللانهائية
      // لحدث ربما فشلت معالجته لسبب لن يُحل بإعادة المحاولة (مثل orderId تالف)
      res.status(200).json({ received: true });
    }
  }
);
