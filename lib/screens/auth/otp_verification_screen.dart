import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Colors local to this screen so it stays a self-contained, drop-in file.
class _OtpPalette {
  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1C1C1E);
  static const accent = Color(0xFFFF453A); // burnt orange / red
  static const success = Color(0xFF34C759);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9A9A9E);
}

enum _OtpStage { input, verifying, success, error }

/// Full-screen OTP verification flow.
///
/// - Dark theme, 4-digit boxed input with a glowing accent border on the
///   focused box.
/// - Entering the 4th digit triggers a collapse animation (the boxes
///   contract into a single pill) with a confetti burst, then calls
///   [onVerify].
/// - On success, swaps to [SuccessVerificationView] (checkmark badge +
///   soft particle background). On failure, shakes and lets the user
///   retry.
///
/// Wire it up to any backend by supplying [onVerify] / [onResend] - for
/// example, against this project's own `AppController`:
/// ```dart
/// OtpVerificationScreen(
///   phoneNumber: '+1 555 010 1234',
///   onVerify: (code) => AppController.to.confirmPhoneOTP(verificationId, code),
///   onResend: () => AppController.to.startPhoneVerification(
///     phoneNumber: phone,
///     onCodeSent: (id) => verificationId = id,
///     onVerificationFailed: (msg) {},
///   ),
///   onVerified: () => Get.offAll(() => const MainNavigationScreen()),
/// )
/// ```
class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  /// Return true if [code] is valid. Throw / return false on failure.
  final Future<bool> Function(String code) onVerify;

  /// Called when the user taps "Resend".
  final Future<void> Function()? onResend;

  /// Called once the success view has finished animating in.
  final VoidCallback? onVerified;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.onVerify,
    this.onResend,
    this.onVerified,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  static const int _length = 4;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  late final AnimationController _collapseController;
  late final AnimationController _confettiController;
  late final AnimationController _shakeController;

  _OtpStage _stage = _OtpStage.input;
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  int _resendCooldown = 30;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_length, (_) => TextEditingController());
    _focusNodes = List.generate(_length, (_) => FocusNode());

    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendCooldown <= 0) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _collapseController.dispose();
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Autofill / paste landed in a single box - spread it across boxes.
      final chars = value.split('').take(_length - index).toList();
      for (var i = 0; i < chars.length; i++) {
        _controllers[index + i].text = chars[i];
      }
      final last = (index + chars.length - 1).clamp(0, _length - 1);
      _focusNodes[last].requestFocus();
    } else if (value.isNotEmpty && index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isNotEmpty) setState(() {});
    if (_code.length == _length) {
      FocusScope.of(context).unfocus();
      _submit();
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
    }
  }

  void _spawnConfetti() {
    _particles
      ..clear()
      ..addAll(List.generate(28, (_) => _Particle.random(_rng)));
    _confettiController.forward(from: 0);
  }

  Future<void> _submit() async {
    setState(() => _stage = _OtpStage.verifying);
    _collapseController.forward();
    _spawnConfetti();

    bool ok = false;
    try {
      ok = await widget.onVerify(_code);
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;

    if (ok) {
      setState(() => _stage = _OtpStage.success);
      widget.onVerified?.call();
    } else {
      setState(() => _stage = _OtpStage.error);
      _collapseController.reverse();
      _shakeController.forward(from: 0);
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => _stage = _OtpStage.input);
      });
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || widget.onResend == null) return;
    await widget.onResend!.call();
    if (!mounted) return;
    setState(() => _resendCooldown = 30);
    _startResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _OtpPalette.background,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: 0.94, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: _stage == _OtpStage.success
                  ? SuccessVerificationView(
                      key: const ValueKey('success'),
                      particles: _particles,
                      confettiController: _confettiController,
                    )
                  : OtpInputSection(
                      key: const ValueKey('input'),
                      phoneNumber: widget.phoneNumber,
                      controllers: _controllers,
                      focusNodes: _focusNodes,
                      collapseController: _collapseController,
                      shakeController: _shakeController,
                      isVerifying: _stage == _OtpStage.verifying,
                      hasError: _stage == _OtpStage.error,
                      resendCooldown: _resendCooldown,
                      onChanged: _onChanged,
                      onBackspace: _onBackspace,
                      onResend: _resend,
                    ),
            ),

            // Confetti overlay renders above either stage.
            if (_stage == _OtpStage.verifying || _stage == _OtpStage.success)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, _) => CustomPaint(
                    size: Size.infinite,
                    painter: _ConfettiPainter(
                      particles: _particles,
                      progress: _confettiController.value,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The 4-box code entry section with header, glowing focus border, and a
/// collapse-into-pill transition while verifying.
class OtpInputSection extends StatelessWidget {
  final String phoneNumber;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final AnimationController collapseController;
  final AnimationController shakeController;
  final bool isVerifying;
  final bool hasError;
  final int resendCooldown;
  final void Function(int index, String value) onChanged;
  final void Function(int index) onBackspace;
  final VoidCallback onResend;

  const OtpInputSection({
    super.key,
    required this.phoneNumber,
    required this.controllers,
    required this.focusNodes,
    required this.collapseController,
    required this.shakeController,
    required this.isVerifying,
    required this.hasError,
    required this.resendCooldown,
    required this.onChanged,
    required this.onBackspace,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Let's verify your number",
            style: TextStyle(
              color: _OtpPalette.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "We've sent a 4-digit code to $phoneNumber. It'll auto-verify "
            "once entered.",
            style: const TextStyle(
              color: _OtpPalette.textSecondary,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 48),

          AnimatedBuilder(
            animation: Listenable.merge([collapseController, shakeController]),
            builder: (context, child) {
              final shake = sin(shakeController.value * pi * 6) *
                  (1 - shakeController.value) *
                  10;
              return Transform.translate(
                offset: Offset(hasError ? shake : 0, 0),
                child: child,
              );
            },
            child: _CollapsingBoxRow(
              controllers: controllers,
              focusNodes: focusNodes,
              collapseController: collapseController,
              hasError: hasError,
              onChanged: onChanged,
              onBackspace: onBackspace,
            ),
          ),

          const SizedBox(height: 28),
          if (isVerifying)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(_OtpPalette.accent),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Verifying…',
                  style: TextStyle(color: _OtpPalette.textSecondary),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: onResend,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: _OtpPalette.textSecondary,
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(text: "Didn't receive the code? "),
                    TextSpan(
                      text: resendCooldown > 0
                          ? 'Resend in ${resendCooldown}s'
                          : 'Resend',
                      style: TextStyle(
                        color: resendCooldown > 0
                            ? _OtpPalette.textSecondary
                            : _OtpPalette.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The 4 OTP boxes, which animate (via [collapseController]) into a single
/// centered rounded "token" pill once the code is complete.
class _CollapsingBoxRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final AnimationController collapseController;
  final bool hasError;
  final void Function(int index, String value) onChanged;
  final void Function(int index) onBackspace;

  const _CollapsingBoxRow({
    required this.controllers,
    required this.focusNodes,
    required this.collapseController,
    required this.hasError,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeInOutCubic.transform(collapseController.value);

    return LayoutBuilder(
      builder: (context, constraints) {
        const boxSize = 64.0;
        final totalWidth = constraints.maxWidth;
        // Center x each box travels toward once t > 0.
        final centerX = totalWidth / 2 - boxSize / 2;

        return SizedBox(
          height: boxSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: List.generate(controllers.length, (index) {
              final slotWidth = totalWidth / controllers.length;
              final naturalX = slotWidth * index + (slotWidth - boxSize) / 2;
              final x = lerpDouble(naturalX, centerX, t);
              final scale = lerpDouble(1.0, 0.0, t);
              final opacity = (1 - t).clamp(0.0, 1.0);

              return Positioned(
                left: x,
                top: 0,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale == 0 ? 0.0001 : scale,
                    child: _OtpBox(
                      controller: controllers[index],
                      focusNode: focusNodes[index],
                      hasError: hasError,
                      onChanged: (v) => onChanged(index, v),
                      onBackspace: () => onBackspace(index),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        final isFocused = focusNode.hasFocus;
        final borderColor = hasError
            ? _OtpPalette.accent
            : (isFocused ? _OtpPalette.accent : Colors.white24);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _OtpPalette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isFocused || hasError ? 2 : 1.2,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: _OtpPalette.accent.withOpacity(0.45),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: KeyboardListener(
            focusNode: FocusNode(skipTraversal: true),
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace) {
                onBackspace();
              }
            },
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 4, // allows autofill paste-and-spread
              cursorColor: _OtpPalette.accent,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}

/// Shown once [onVerify] resolves successfully.
class SuccessVerificationView extends StatefulWidget {
  final List<_Particle> particles;
  final AnimationController confettiController;

  const SuccessVerificationView({
    super.key,
    required this.particles,
    required this.confettiController,
  });

  @override
  State<SuccessVerificationView> createState() =>
      _SuccessVerificationViewState();
}

class _SuccessVerificationViewState extends State<SuccessVerificationView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _popController,
              curve: Curves.elasticOut,
            ),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: _OtpPalette.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _OtpPalette.success,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: _OtpPalette.success,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Verified Successfully',
            style: TextStyle(
              color: _OtpPalette.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your number has been verified.',
            style: TextStyle(color: _OtpPalette.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _OtpPalette.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, color: _OtpPalette.success, size: 16),
                SizedBox(width: 8),
                Text(
                  'Verified and Secure',
                  style: TextStyle(
                    color: _OtpPalette.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single confetti/particle used by [_ConfettiPainter].
class _Particle {
  final double startX; // 0..1, fraction of screen width
  final double startY; // 0..1, fraction of screen height
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _Particle({
    required this.startX,
    required this.startY,
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });

  static const _colors = [
    _OtpPalette.accent,
    _OtpPalette.success,
    Color(0xFFFFD60A),
    Color(0xFF5E5CE6),
    Colors.white,
  ];

  factory _Particle.random(Random rng) {
    return _Particle(
      startX: 0.5 + (rng.nextDouble() - 0.5) * 0.1,
      startY: 0.42,
      angle: rng.nextDouble() * 2 * pi,
      speed: 60 + rng.nextDouble() * 140,
      size: 4 + rng.nextDouble() * 5,
      color: _colors[rng.nextInt(_colors.length)],
    );
  }
}

/// Pure-Dart particle burst painter - no external confetti package
/// required, so this file has zero extra dependencies.
class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress; // 0..1

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || particles.isEmpty) return;
    final fade = (1 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final dx = cos(p.angle) * p.speed * progress;
      final dy = sin(p.angle) * p.speed * progress - (120 * progress * progress);
      final x = p.startX * size.width + dx;
      final y = p.startY * size.height + dy;

      final paint = Paint()..color = p.color.withOpacity(fade);
      canvas.drawCircle(Offset(x, y), p.size * (1 - progress * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
