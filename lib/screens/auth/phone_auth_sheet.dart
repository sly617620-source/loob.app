import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../data/country_codes.dart';
import '../../providers/app_provider.dart';
import '../profile/main_navigation_screen.dart';
import 'country_code_field.dart';
import 'otp_code_input.dart';
import 'package:get/get.dart';

/// Two-step "sign in with phone number" flow: pick a country + enter the
/// local number → receive SMS code → enter it in the 6-box OTP input →
/// signed in. Shown as a bottom sheet from [AuthScreen] so it doesn't need
/// its own route.
class PhoneAuthSheet extends StatefulWidget {
  const PhoneAuthSheet({super.key});

  @override
  State<PhoneAuthSheet> createState() => _PhoneAuthSheetState();
}

class _PhoneAuthSheetState extends State<PhoneAuthSheet> {
  final _phoneController = TextEditingController();
  CountryCode _country = defaultCountry;
  String _otpCode = '';

  String? _verificationId;
  bool _isLoading = false;
  String? _error;

  // Standard 60s SMS-resend cooldown - stops accidental double-taps from
  // burning through the per-number SMS quota Firebase enforces server-side
  // (the "quota-exceeded" error the phone-auth work already maps to a
  // friendly message) before the first message has even arrived.
  static const _resendCooldown = 60;
  Timer? _resendTimer;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _fullPhoneNumber => '${_country.dialCode}${_phoneController.text.trim()}';

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) timer.cancel();
      });
    });
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'يرجى إدخال رقم الهاتف');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final controller = AppProvider.of(context, listen: false);
    try {
      await controller.startPhoneVerification(
        phoneNumber: _fullPhoneNumber,
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
          _startResendTimer();
        },
        onVerificationFailed: (message) {
          if (!mounted) return;
          setState(() {
            _error = message;
            _isLoading = false;
          });
        },
        onCodeAutoRetrievalTimeout: (_) {
          // Purely informational (see FirebaseService docs) - the code the
          // user already received is still valid, nothing to do here.
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (_otpCode.length != 6 || _verificationId == null) {
      setState(() => _error = 'يرجى إدخال رمز التحقق كاملاً');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final controller = AppProvider.of(context, listen: false);
    try {
      final success = await controller.confirmPhoneOTP(_verificationId!, _otpCode);
      if (!mounted) return;
      if (success) {
        Get.offAll(() => const MainNavigationScreen());
      } else {
        setState(() {
          _error = 'تعذر تسجيل الدخول، حاول مرة أخرى';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final codeStep = _verificationId != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            codeStep ? '🔐 أدخل رمز التحقق' : '📱 تسجيل الدخول برقم الهاتف',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            codeStep
                ? 'أرسلنا رمزًا مكونًا من 6 أرقام إلى $_fullPhoneNumber'
                : 'سنرسل لك رمز تحقق عبر رسالة نصية',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          if (!codeStep)
            Row(
              children: [
                CountryCodeField(
                  selected: _country,
                  onChanged: (c) => setState(() => _country = c),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background.withValues(alpha: 0.6),
                      hintText: 'رقم الهاتف',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            )
          else
            OtpCodeInput(
              onChanged: (code) => setState(() => _otpCode = code),
              onCompleted: (code) {
                _otpCode = code;
                _verifyCode();
              },
            ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : (codeStep ? _verifyCode : _sendCode),
              child: _isLoading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(codeStep ? 'تأكيد الرمز' : 'إرسال رمز التحقق',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (codeStep) ...[
            const SizedBox(height: 12),
            Center(
              child: _secondsLeft > 0
                  ? Text('يمكنك إعادة الإرسال بعد $_secondsLeft ثانية',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12))
                  : TextButton(
                      onPressed: _isLoading ? null : _sendCode,
                      child: const Text('إعادة إرسال الرمز', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                    ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() {
                          _verificationId = null;
                          _otpCode = '';
                          _error = null;
                          _resendTimer?.cancel();
                          _secondsLeft = 0;
                        }),
                child: const Text('تغيير رقم الهاتف', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
