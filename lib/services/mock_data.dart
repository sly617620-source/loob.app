import '../models/product_model.dart';
import '../models/review_model.dart';
import '../models/chat_model.dart';
import '../models/order_model.dart';
import '../models/coupon_model.dart';
import '../models/affiliate_model.dart';
import '../models/campaign_model.dart';
import '../models/submission_model.dart';

class MockData {
  static final List<Product> products = [
    Product(
      id: 'p1',
      title: 'قالب تيك توك برو - 50 انتقال احترافي',
      description:
          'مجموعة انتقالات فيديو احترافية لتطبيق CapCut. تتضمن 50 انتقالاً سلساً مع تأثيرات صوتية.',
      sellerId: 's1',
      sellerName: 'أحمد التصميم',
      sellerAvatar: 'أت',
      price: 49.0,
      originalPrice: 99.0,
      type: ProductType.template,
      images: ['template1.jpg'],
      tags: ['capcut', 'تيك_توك', 'انتقالات'],
      category: 'قوالب فيديو',
      features: [
        '50 انتقال فريد',
        'تأثيرات صوتية متضمنة',
        'شرح تعليمي',
        'تحديثات مجانية'
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      salesCount: 234,
      rating: 4.8,
      reviewsCount: 56,
      isFeatured: true,
      isPayAsYouSell: true,
    ),
    Product(
      id: 'p2',
      title: 'دورة التسويق بالمحتوى - من الصفر للاحتراف',
      description:
          'دورة شاملة في التسويق بالمحتوى تشمل 20 ساعة فيديو، ملفات عمل، وشهادة إتمام.',
      sellerId: 's2',
      sellerName: 'نورة التسويق',
      sellerAvatar: 'نت',
      price: 199.0,
      originalPrice: 399.0,
      type: ProductType.course,
      images: ['course1.jpg'],
      tags: ['تسويق', 'محتوى', 'دورة'],
      category: 'دورات تعليمية',
      features: [
        '20 ساعة فيديو',
        'ملفات عمل قابلة للتحميل',
        'شهادة معتمدة',
        'دعم مباشر'
      ],
      metadata: {'duration': '20 ساعة', 'lessons': 45, 'level': 'متوسط'},
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      salesCount: 512,
      rating: 4.9,
      reviewsCount: 128,
      isFeatured: true,
    ),
    Product(
      id: 'p3',
      title: 'سكريبت أتمتة إنستغرام - بوت ذكي',
      description:
          'سكريبت بايثون كامل لأتمتة التفاعل على إنستغرام مع واجهة رسومية سهلة.',
      sellerId: 's3',
      sellerName: 'محمد البرمجة',
      sellerAvatar: 'مب',
      price: 299.0,
      type: ProductType.license,
      images: ['license1.jpg'],
      tags: ['بايثون', 'أتمتة', 'إنستغرام'],
      category: 'أدوات برمجية',
      features: [
        'كود مصدري كامل',
        'ترخيص سنة',
        'دعم فني 3 أشهر',
        'تحديثات مجانية'
      ],
      licenseKey: 'LIC-2026-XXXX-XXXX',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      salesCount: 89,
      rating: 4.6,
      reviewsCount: 23,
    ),
    Product(
      id: 'p4',
      title: 'باقة UGC كاملة - 20 فيديو جاهز',
      description:
          'مجموعة من 20 فيديو UGC جاهز للاستخدام في حملاتك الإعلانية. محتوى عربي أصيل 100%.',
      sellerId: 's4',
      sellerName: 'ليلى المحتوى',
      sellerAvatar: 'لم',
      price: 150.0,
      originalPrice: 250.0,
      type: ProductType.ugc,
      images: ['ugc1.jpg'],
      tags: ['UGC', 'إعلانات', 'فيديو'],
      category: 'محتوى إعلاني',
      features: [
        '20 فيديو فريد',
        'جودة 4K',
        'موسيقى مرخصة',
        'تعديلات مجانية'
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      salesCount: 45,
      rating: 4.7,
      reviewsCount: 12,
      stock: 100,
    ),
    Product(
      id: 'p5',
      title: 'مجتمع رواد المحتوى - اشتراك شهري',
      description:
          'انضم لمجتمع حصري من رواد المحتوى. ورش عمل أسبوعية، مصادر حصرية، وتواصل مباشر.',
      sellerId: 's2',
      sellerName: 'نورة التسويق',
      sellerAvatar: 'نت',
      price: 29.0,
      type: ProductType.hybrid,
      images: ['community1.jpg'],
      tags: ['مجتمع', 'شبكة', 'تعلم'],
      category: 'مجتمعات',
      features: [
        'ورش عمل أسبوعية',
        'قروب خاص',
        'مصادر حصرية',
        'لقاءات شهرية'
      ],
      metadata: {'subscription': 'monthly', 'members': 1200},
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      salesCount: 876,
      rating: 4.9,
      reviewsCount: 203,
    ),
  ];

  static final List<Review> reviews = [
    Review(
      id: 'r1',
      productId: 'p1',
      userId: 'u1',
      userName: 'خالد العنزي',
      userAvatar: 'خا',
      rating: 5.0,
      comment: 'أفضل قالب استخدمته! الانتقالات سلسة جداً والجودة عالية.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      helpfulCount: 12,
    ),
    Review(
      id: 'r2',
      productId: 'p1',
      userId: 'u2',
      userName: 'سارة الأحمد',
      userAvatar: 'سأ',
      rating: 4.0,
      comment: 'ممتاز لكن يحتاج شرح أكثر للمبتدئين.',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      helpfulCount: 5,
      sellerReply: 'شكراً سارة! سنضيف درساً للمبتدئين قريباً.',
    ),
    Review(
      id: 'r3',
      productId: 'p2',
      userId: 'u3',
      userName: 'فهد السبيعي',
      userAvatar: 'فس',
      rating: 5.0,
      comment: 'الدورة غيرت مفهومي للتسويق بالكامل. أنصح بها بشدة!',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      helpfulCount: 23,
    ),
  ];

  static final List<ChatMessage> chatMessages = [
    ChatMessage(
      id: 'cm1',
      conversationId: 'conv_p1_u1',
      senderId: 'u1',
      content: 'مرحباً، هل القالب يعمل على آيفون؟',
      sentAt: DateTime.now().subtract(const Duration(minutes: 30)),
      isRead: true,
    ),
    ChatMessage(
      id: 'cm2',
      conversationId: 'conv_p1_u1',
      senderId: 's1',
      content: 'نعم يعمل على iOS و Android بدون مشاكل!',
      sentAt: DateTime.now().subtract(const Duration(minutes: 25)),
      isRead: true,
    ),
    ChatMessage(
      id: 'cm3',
      conversationId: 'conv_p1_u1',
      senderId: 'u1',
      content: 'ممتاز، سأشتريه الآن',
      sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
  ];

  static final List<Order> orders = [
    Order(
      id: 'o1',
      productId: 'p1',
      productTitle: 'قالب تيك توك برو',
      buyerId: 'u1',
      sellerId: 's1',
      amount: 49.0,
      platformFee: 4.9,
      status: OrderStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      completedAt: DateTime.now().subtract(const Duration(days: 9)),
      licenseKey: 'LIC-ABC-123-XYZ',
    ),
  ];

  static final List<Coupon> coupons = [
    Coupon(
      id: 'c1',
      code: 'LOOB20',
      discountPercent: 20.0,
      maxDiscount: 50.0,
      validUntil: DateTime.now().add(const Duration(days: 30)),
      maxUses: 100,
      usedCount: 45,
    ),
    Coupon(
      id: 'c2',
      code: 'FIRSTBUY',
      discountPercent: 30.0,
      validUntil: DateTime.now().add(const Duration(days: 60)),
      maxUses: 50,
      usedCount: 12,
    ),
  ];

  /// Advertising / clipping campaigns shown in the "استكشف الحملات" feed.
  /// Content creators submit posts against a campaign and earn per CPM.
  static final List<Campaign> campaigns = [
    Campaign(
      id: 'cmp1',
      brandId: 's1',
      title: 'بودكاست ريادة الأعمال العربي',
      description:
          'نبحث عن صناع محتوى لتقطيع ونشر مقاطع من بودكاست ريادة الأعمال على تيك توك وإنستغرام. المطلوب نشر لايف كليبات مع الوسم الرسمي للحملة.',
      budget: 500.0,
      rewardPerSubmission: 5.0,
      status: CampaignStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 16)),
      endDate: DateTime.now().add(const Duration(days: 14)),
      requirements: [
        'مدة المقطع بين 30-90 ثانية',
        'إضافة وسم #ريادة_الأعمال في الوصف',
        'نشر على تيك توك أو إنستغرام ريلز',
        'عدم استخدام محتوى مسيء أو مضلل',
      ],
      categories: ['بودكاست'],
      maxSubmissions: 200,
      currentSubmissions: 180,
      createdAt: DateTime.now().subtract(const Duration(days: 16)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      brandName: 'أحمد الشقيري',
      brandAvatar: 'AS',
      cpm: 2.0,
      viewsCount: 12500,
      avgRating: 4.8,
      spentBudget: 450.0,
    ),
    Campaign(
      id: 'cmp2',
      brandId: 's5',
      title: 'تحدي تداول العملات الرقمية',
      description:
          'حملة تحدي لصناع المحتوى المهتمين بالتداول والعملات الرقمية. شارك تجربتك مع منصة Ouinex واربح لكل 1000 مشاهدة.',
      budget: 4000.0,
      rewardPerSubmission: 8.0,
      status: CampaignStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 29)),
      requirements: [
        'ذكر اسم المنصة Ouinex بوضوح',
        'عدم تقديم نصائح استثمارية مضمونة',
        'إرفاق رابط الإحالة الخاص بك',
      ],
      categories: ['تداول'],
      maxSubmissions: 500,
      currentSubmissions: 500,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now(),
      brandName: 'منصة Ouinex',
      brandAvatar: 'OX',
      cpm: 3.0,
      viewsCount: 8900,
      avgRating: 4.5,
      spentBudget: 3993.0,
    ),
    Campaign(
      id: 'cmp3',
      brandId: 's2',
      title: 'أفضل نصائح التطوير الذاتي لهذا العام',
      description:
          'ننشئ سلسلة محتوى قصير عن التطوير الذاتي وبناء العادات. نبحث عن مقاطع تحفيزية أصيلة بصوتك الخاص.',
      budget: 1200.0,
      rewardPerSubmission: 4.0,
      status: CampaignStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      endDate: DateTime.now().add(const Duration(days: 25)),
      requirements: [
        'محتوى أصلي بصوتك الخاص',
        'مدة المقطع لا تقل عن 20 ثانية',
        'وسم #تطوير_ذاتي في الوصف',
      ],
      categories: ['تطوير ذاتي'],
      maxSubmissions: 300,
      currentSubmissions: 96,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      brandName: 'نورة التسويق',
      brandAvatar: 'نت',
      cpm: 1.5,
      viewsCount: 4300,
      avgRating: 4.6,
      spentBudget: 384.0,
    ),
    Campaign(
      id: 'cmp4',
      brandId: 's4',
      title: 'إطلاق باقة UGC الجديدة - تسويق',
      description:
          'حملة تسويقية لإطلاق باقة UGC الجديدة. المطلوب مراجعات فيديو قصيرة توضح كيفية استخدام الباقة.',
      budget: 800.0,
      rewardPerSubmission: 6.0,
      status: CampaignStatus.active,
      startDate: DateTime.now().subtract(const Duration(days: 3)),
      endDate: DateTime.now().add(const Duration(days: 20)),
      requirements: [
        'مراجعة صادقة لا تقل عن دقيقة',
        'إظهار الباقة أثناء الاستخدام',
        'وضع رابط المنتج في السيرة الذاتية',
      ],
      categories: ['تسويق'],
      maxSubmissions: 150,
      currentSubmissions: 40,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      brandName: 'ليلى المحتوى',
      brandAvatar: 'لم',
      cpm: 2.5,
      viewsCount: 2100,
      avgRating: 4.4,
      spentBudget: 240.0,
    ),
  ];

  static final List<Submission> submissions = [];

  static final List<Affiliate> affiliateLinks = [
    Affiliate(
      id: 'a1',
      userId: 'u1',
      referralCode: 'AHMED20',
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(days: 45)),
    ),
  ];
}
