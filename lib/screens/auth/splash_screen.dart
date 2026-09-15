import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Splash / brand screen shown while the app decides where to send the
/// user next (Auth screen or straight into the app).
///
/// - Dark (#121212-family) background with a soft gold glow behind the
///   LOOB logo, so the brand mark reads clearly even on very dark panels.
/// - A hard 2.5 second [Timer] guarantees the splash stays on screen long
///   enough to be seen before automatically calling [onComplete].
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _navigationTimer;

  static const Duration _splashDuration = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _splashDuration,
      vsync: this,
    )..forward();

    // Explicit 2.5s timer: makes sure the splash is fully visible before
    // we automatically move on to the Auth screen (or the app itself).
    _navigationTimer = Timer(_splashDuration, () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          // Unified dark background (matches the rest of the Black & Gold
          // theme instead of the old, unrelated navy/purple gradient).
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0A), Color(0xFF121212), Color(0xFF161616)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.15, 0.75, curve: Curves.easeOut),
              ),
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOut),
              ),
              child: Opacity(
                // Large, faint, borderless watermark - the logo asset now
                // has a real alpha channel (its old solid-black background
                // used to render as a visible dark square/box behind the
                // mark at any opacity; that's fixed at the source, in the
                // PNG itself, not just here).
                opacity: 0.2,
                child: Image.asset(
                  'assets/images/loob_logo.png',
                  width: MediaQuery.of(context).size.width * 0.7,
                  fit: BoxFit.contain,
                  // Fall back to a plain logo-colored mark if the asset is
                  // ever missing, so the splash never renders blank - kept
                  // deliberately free of any text/wordmark.
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.shield_outlined,
                      color: AppColors.accent,
                      size: 160,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
