import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/service_providers.dart';
import '../../utils/validators.dart';
import '../../widgets/app_animations.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_widgets.dart';

/// Step 1 of the password reset flow.
/// Collects the user's email, calls POST /api/auth/forgot-password,
/// then navigates to /verify-reset-code passing the email forward.
/// Always shows a generic success message regardless of whether the
/// email exists (mirrors backend enumeration-prevention behaviour).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;

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
  }

  @override
  void dispose() {
    _glowController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    _isSubmitting = true;
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      // Always succeeds from the user's perspective — backend returns the
      // same message whether or not the email exists.
      await authService.forgotPassword(_emailController.text.trim());

      if (!mounted) return;
      // Navigate to Step 2, passing the email as a query parameter.
      final email =
          Uri.encodeComponent(_emailController.text.trim());
      context.push('/verify-reset-code?email=$email');
    } catch (e) {
      if (!mounted) return;
      // Only real network / server errors reach here.
      AppSnackbar.error(
          context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _isSubmitting = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Stack(
        children: [
          const ParticleBackground(),

          // Ambient glow — top-right
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, _) => Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00B894)
                          .withOpacity(_glowAnimation.value * 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Ambient glow — bottom-left
          Positioned(
            bottom: -80,
            left: -80,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, _) => Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF00CECE)
                          .withOpacity(_glowAnimation.value * 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SlideInWidget(
                    delay: const Duration(milliseconds: 50),
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white54, size: 20),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28.0, vertical: 8.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),

                          // ── Icon ──────────────────────────────────────────
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
                                    color: const Color(0xFF00B894)
                                        .withOpacity(0.35),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00B894)
                                          .withOpacity(
                                              _glowAnimation.value * 0.45),
                                      blurRadius: 32,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.lock_reset_outlined,
                                  color: Color(0xFF00B894),
                                  size: 40,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Heading ───────────────────────────────────────
                          SlideInWidget(
                            delay: const Duration(milliseconds: 200),
                            child: Column(
                              children: [
                                const Text(
                                  'Forgot password?',
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
                                  'Enter your email and we\'ll send you a 6-digit code to reset your password.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.45),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 44),

                          // ── Email field ───────────────────────────────────
                          SlideInWidget(
                            delay: const Duration(milliseconds: 300),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    'Email',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AuthField(
                                  controller: _emailController,
                                  hintText: 'Enter your email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) => Validators.email(v),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 36),

                          // ── Submit button ─────────────────────────────────
                          SlideInWidget(
                            delay: const Duration(milliseconds: 400),
                            child: GradientAuthButton(
                              label: 'Send Code',
                              isLoading: _isLoading,
                              onTap: _submit,
                              colors: const [
                                Color(0xFF00B894),
                                Color(0xFF00CECE),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Back to login ─────────────────────────────────
                          SlideInWidget(
                            delay: const Duration(milliseconds: 500),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Remember your password? ',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 13,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      context.pushReplacement('/login'),
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: Color(0xFF00B894),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
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
