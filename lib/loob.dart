// lib/loob.dart
export 'theme/app_colors.dart';

// UI provider (InheritedNotifier) kept as the canonical AppProvider for widgets
export 'providers/app_provider.dart';

export 'services/app_controller.dart';
export 'services/storage_service.dart';
export 'services/firebase_service.dart';

export 'models/user_model.dart';
export 'models/chat_model.dart'; // canonical chat model
// Note: models/chat_models.dart contains duplicate/legacy definitions and is intentionally NOT exported

export 'models/product_model.dart';
export 'models/review_model.dart';
export 'models/order_model.dart';
export 'models/coupon_model.dart';
export 'models/affiliate_model.dart';
export 'models/campaign_model.dart';
export 'models/notification_model.dart';
export 'models/analytics_model.dart';
export 'models/submission_model.dart';
export 'models/models.dart';
