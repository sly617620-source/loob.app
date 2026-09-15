import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../profile/main_navigation_screen.dart';
import 'phone_auth_sheet.dart';
import 'country_code_field.dart';
import '../../data/country_codes.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  CountryCode _selectedCountry = defaultCountry;
  bool _isLoading = false;
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.customer;

  // The country code is now selected separately via [CountryCodeField], so
  // this only validates the local number part: digits (with optional
  // spaces/dashes as separators), 6-12 digits - loose enough for
  // international numbers without pretending to fully validate a real
  // phone number (that needs carrier verification, not a regex).
  static final RegExp _phoneRegex = RegExp(r'^[0-9][0-9\s\-]{5,11}$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleAuth() async {
    // Trim email/password/name so accidental leading/trailing spaces
    // (very common on mobile keyboards) never cause a silently-wrong
    // Firebase Auth call (e.g. "user@mail.com " != "user@mail.com").
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('يرجى ملء جميع الحقول');
      return;
    }
    if (!email.contains('@')) {
      _showError('بريد إلكتروني غير صالح');
      return;
    }
    if (password.length < 6) {
      _showError('كلمة المرور 6 أحرف على الأقل');
      return;
    }
    if (!isLogin && name.isEmpty) {
      _showError('يرجى إدخال الاسم');
      return;
    }
    if (!isLogin && phone.isEmpty) {
      _showError('يرجى إدخال رقم الهاتف');
      return;
    }
    if (!isLogin && !_phoneRegex.hasMatch(phone)) {
      _showError('رقم الهاتف غير صالح');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final controller = AppProvider.of(context);
      bool success;
      if (isLogin) {
        success = await controller.signInWithEmail(email, password);
        if (!success) _showError('بيانات الدخول غير صحيحة');
      } else {
        success = await controller.registerWithEmail(
          email,
          password,
          displayName: name,
          phoneNumber: '${_selectedCountry.dialCode}$phone',
          role: _selectedRole,
        );
        if (!success) _showError('تعذر إنشاء الحساب، حاول مرة أخرى');
      }

      // BUG FIX: this was the actual reason "the account gets created and
      // shows up in Firebase, but the app never lets you in" - on success
      // this method used to just fall through and do nothing. `success`
      // becoming `true` only updates AppController.user in memory; nothing
      // was listening for that to move the user off this screen, so they
      // stayed stuck looking at the login form with no error and no
      // feedback at all. Explicitly navigate into the app now, exactly
      // like AppLoader does for an already-authenticated cold start.
      if (success && mounted) {
        // Only email/password sign-up produces an unverified email - social
        // and phone sign-in never need this prompt (Google/Apple already
        // vouch for the email; phone has no email at all).
        if (!isLogin) await _maybeShowEmailVerificationPrompt();
        if (mounted) Get.offAll(() => const MainNavigationScreen());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Shared handler for both social providers - same loading/error/navigate
  /// contract as [_handleAuth], just driven by [signInMethod] instead of
  /// the email/password form fields. A cancelled picker returns `false`
  /// from [signInMethod] without throwing (see AppController), so it's
  /// silently a no-op here too - no error shown for "changed their mind".
  void _handleSocialAuth(Future<bool> Function() signInMethod) async {
    setState(() => _isLoading = true);
    try {
      final success = await signInMethod();
      if (success && mounted) {
        Get.offAll(() => const MainNavigationScreen());
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPhoneAuthSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => const PhoneAuthSheet(),
    );
  }

  /// Shown right after a successful email/password registration - real
  /// usage of [AppController.isEmailVerified]/[sendEmailVerification]
  /// gating a protected action, per the request. Kept as a dismissible
  /// heads-up rather than a hard block, since forcing verification before
  /// any app access is a product decision this screen shouldn't make
  /// unilaterally - the check itself is what was asked for; wiring it to
  /// fully lock out unverified users is a one-line change at the call site
  /// once that decision is made (call [AppController.isEmailVerified] from
  /// wherever a protected route is entered, same as here).
  Future<void> _maybeShowEmailVerificationPrompt() async {
    final controller = AppProvider.of(context, listen: false);
    final verified = await controller.isEmailVerified();
    if (verified || !mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('تحقق من بريدك الإلكتروني', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'أرسلنا رابط تفعيل إلى بريدك الإلكتروني. افتح الرابط لتفعيل حسابك بالكامل.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await controller.sendEmailVerification();
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('تم إرسال رابط جديد ✅')),
                  );
                }
              } catch (_) {}
            },
            child: const Text('إعادة إرسال'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        // Same dark, gold-accented backdrop as the Splash screen so the
        // Auth flow feels like one continuous brand experience - no more
        // stray teal/navy gradients.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF121212), Color(0xFF161616)],
          ),
        ),
        child: Stack(
          children: [
            // Large, faint, borderless logo watermark behind the form -
            // same treatment as the Splash screen, instead of the old
            // small boxed icon (its visible "box" came from the source
            // PNG's solid-black background, now fixed to real transparency
            // in the asset itself).
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, -0.6),
                child: Opacity(
                  opacity: 0.14,
                  child: Image.asset(
                    'assets/images/loob_logo.png',
                    width: MediaQuery.of(context).size.width * 0.85,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 140),
                    Container(
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isLogin = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isLogin
                                  ? AppColors.accent.withValues(alpha: 0.9)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'تسجيل الدخول',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isLogin ? Colors.black : AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isLogin = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isLogin
                                  ? AppColors.accent.withValues(alpha: 0.9)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'إنشاء حساب',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !isLogin ? Colors.black : AppColors.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (!isLogin)
                  _buildField(_nameController, 'الاسم الكامل', '👤'),
                if (!isLogin) const SizedBox(height: 16),
                if (!isLogin) _buildRoleSelector(),
                if (!isLogin) const SizedBox(height: 16),
                if (!isLogin)
                  Row(
                    children: [
                      CountryCodeField(
                        selected: _selectedCountry,
                        onChanged: (c) => setState(() => _selectedCountry = c),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildField(_phoneController, 'رقم الهاتف', '📱',
                            keyboardType: TextInputType.phone),
                      ),
                    ],
                  ),
                if (!isLogin) const SizedBox(height: 16),
                _buildField(_emailController, 'البريد الإلكتروني', '📧',
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildField(
                  _passwordController,
                  'كلمة المرور',
                  '🔒',
                  obscureText: _obscurePassword,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                    child: Text(_obscurePassword ? '👁️' : '🙈',
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : Text(isLogin ? 'تسجيل الدخول' : 'إنشاء حساب',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                _buildOrDivider(),
                const SizedBox(height: 16),
                _buildSocialButton(
                  label: 'المتابعة عبر Google',
                  icon: _GoogleLogo(),
                  onPressed: _isLoading
                      ? null
                      : () => _handleSocialAuth(
                          () => AppProvider.of(context, listen: false).signInWithGoogle()),
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  label: 'المتابعة عبر Apple',
                  icon: const Icon(Icons.apple, color: Colors.white, size: 22),
                  onPressed: _isLoading
                      ? null
                      : () => _handleSocialAuth(
                          () => AppProvider.of(context, listen: false).signInWithApple()),
                ),
                const SizedBox(height: 12),
                _buildSocialButton(
                  label: 'المتابعة برقم الهاتف',
                  icon: const Icon(Icons.phone_android, color: Colors.white, size: 22),
                  onPressed: _isLoading ? null : _showPhoneAuthSheet,
                ),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.textMuted.withValues(alpha: 0.3))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('أو', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
        Expanded(child: Divider(color: AppColors.textMuted.withValues(alpha: 0.3))),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.card.withValues(alpha: 0.8),
          side: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  /// Account-type picker shown only during registration. The chosen role
  /// determines which dashboard/navigation the account sees after signup
  /// (see MainNavigationScreen._tabsForRole).
  Widget _buildRoleSelector() {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              'نوعية الحساب',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: UserRole.values.where((r) => r != UserRole.admin).map((r) {
              final isSelected = r == _selectedRole;
              return GestureDetector(
                onTap: () => setState(() => _selectedRole = r),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : AppColors.card.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.accent : Colors.transparent),
                  ),
                  child: Column(
                    children: [
                      Text(r.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                        r.label,
                        style: TextStyle(
                          color: isSelected ? AppColors.accent : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint,
    String prefix, {
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.card.withValues(alpha: 0.8),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(prefix, style: const TextStyle(fontSize: 20)),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 44, minHeight: 44),
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: suffix,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1),
        ),
      ),
    );
  }
}

/// Minimal multi-color Google "G" mark drawn from plain widgets - avoids
/// pulling in an icon-font package (font_awesome_flutter etc.) just for
/// one logo. Flutter's Material Icons has no official Google glyph, but
/// `Icons.apple` already exists for the Apple button.
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            height: 1,
          ),
        ),
      ),
    );
  }
}
