import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // دالة إرسال المقطع الممنتج للمراجعة
  Future<void> submitClip({
    required String clipperId,
    required String clipperName,
    required String videoUrl,
    required String captionText, // الوصف الذي كتبه الممنتج للفيديو
    required String campaignTag, // التاغ المطلوب للحملة مثل #ريادة_الأعمال
    required double campaignCpm, // سعر الـ CPM الخاص بهذه الحملة
  }) async {
    try {
      // إضافة مستند جديد في جدول التقديمات (submissions)
      await _db.collection('submissions').add({
        'clipper_id': clipperId,
        'clipper_name': clipperName,
        'video_url': videoUrl,
        'caption': captionText, // البايثون سيبحث عن التاغ داخل هذا النص
        'required_tag': campaignTag,
        'cpm': campaignCpm,
        'status': 'pending', // الحالة الافتراضية "قيد الانتظار" ليفحصها البوت
        'current_views': 0,
        'earnings': 0.0,
        'submitted_at': FieldValue.serverTimestamp(),
      });
      print(
          '✅ تم إرسال الفيديو لقاعدة البيانات بنجاح وبوت البايثون سيقوم بفحصه الآن!');
    } catch (e) {
      print('❌ حدث خطأ أثناء التقديم: $e');
    }
  }
}
