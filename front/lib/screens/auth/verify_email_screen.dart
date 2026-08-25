import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/service_providers.dart';
import '../../widgets/app_animations.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/otp_input.dart';

/// Shown immediately after successful registration.
/// Accepts a 6-digit OTP sent to the user's email and calls
/// POST /api/auth/verify-email { code }.
/// The user is already authenticated (token stored) when they land here.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;

  const VerifyEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with OtpInputMixin, SingleTickerProviderStateMixin {
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.15, end: 0.4).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    startResendTimer();
  }

  @override
  void dispose() {
    _glowController.dispose();
    disposeOtpResources();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_isVerifying || !isOtpComplete) return;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyEmail(currentOtpCode);

      if (!mounted) return;
      AppSnackbar.success(context, 'Email verified successfully!');
      context.go('/business-picker');
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      if (message.contains('Too many failed attempts')) {
        clearOtpBoxes();
      }
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    if (_isResending || resendSecondsRemaining > 0) return;
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resendVerificationCode();

      if (!mounted) return;
      clearOtpBoxes();
      startResendTimer();
      AppSnackbar.success(context, 'New code sent to ${widget.email}');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Stack(
        children: [
          const ParticleBackground(),

          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, _) => Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00B894)
                          .withOpacity(_glowAnimation.value * 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -80,
            left: -80,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, _) => Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00CECE)
                          .withOpacity(_glowAnimation.value * 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),

                  SlideInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, _) => Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1B2E),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF00B894).withOpacity(0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B894)
                                  .withOpacity(_glowAnimation.value * 0.5),
                              blurRadius: 32,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          color: Color(0xFF00B894),
                          size: 40,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  SlideInWidget(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      children: [
                        const Text(
                          'Verify your email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'We sent a 6-digit code to',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.45),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00B894),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 44),

                  SlideInWidget(
                    delay: const Duration(milliseconds: 300),
                    child: OtpBoxRow(
                      controllers: otpControllers,
                      focusNodes: otpFocusNodes,
                      onChanged: (i, v) => onOtpDigitChanged(
                        i, v,
                        onComplete: _verify,
                      ),
                      onPaste: (s) => onOtpPaste(s, onComplete: _verify),
                      hasError: _errorMessage != null,
                    ),
                  ),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _errorMessage != null
                        ? Padding(
                            key: ValueKey(_errorMessage),
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFFF4B6E), size: 16),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFFF4B6E),
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 36),

                  SlideInWidget(
                    delay: const Duration(milliseconds: 400),
                    child: Opacity(
                      opacity: isOtpComplete ? 1.0 : 0.45,
                      child: GradientAuthButton(
                        label: 'Verify Email',
                        isLoading: _isVerifying,
                        onTap: isOtpComplete ? _verify : () {},
                        colors: const [Color(0xFF00B894), Color(0xFF00CECE)],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  SlideInWidget(
                    delay: const Duration(milliseconds: 500),
                    child: ResendRow(
                      secondsRemaining: resendSecondsRemaining,
                      isResending: _isResending,
                      onResend: _resend,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SlideInWidget(
                    delay: const Duration(milliseconds: 600),
                    child: TextButton(
                      onPressed: () => context.go('/business-picker'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.35),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      child: const Text('Skip for now',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
