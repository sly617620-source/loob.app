import '../firebase_service.dart';

/// خدمة المساعد الذكي (Chatbot Service)
class ChatbotService {
  // ملاحظة: FirebaseService يُستقبل هنا للحفاظ على توافق واجهة الإنشاء
  // مع المستدعي (ChatbotService(FirebaseService())) رغم عدم استخدامه
  // فعليًا بعد داخل هذه الخدمة حاليًا (لا يُخزَّن كحقل غير مستخدم).
  ChatbotService(FirebaseService firebaseService);

  /// معالجة الرسائل القادمة من المستخدم
  Future<String> processMessage(String message) async {
    if (message.trim().isEmpty) {
      return 'يرجى كتابة رسالة صالحة.';
    }
    
    // محاكاة استجابة المساعد الذكي
    await Future.delayed(const Duration(milliseconds: 500));
    return 'شكراً لتواصلك معنا! كيف يمكنني مساعدتك اليوم؟';
  }
}
