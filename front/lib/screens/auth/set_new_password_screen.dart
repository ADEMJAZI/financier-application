import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/service_providers.dart';
import '../../utils/validators.dart';
import '../../widgets/app_animations.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_widgets.dart';

/// Step 3 of the password reset flow.
/// Takes the [resetSessionToken] issued in Step 2 and a new password,
/// calls POST /api/auth/reset-password {resetSessionToken, newPassword}.
/// On success navigates to /login (all sessions were invalidated server-side).
/// On 401 (token expired — 5-min window) shows a clear "start over" message.
class SetNewPasswordScreen extends ConsumerStatefulWidget {
  /// Short-lived JWT issued by /verify-reset-code. Valid for 5 minutes.
  final String resetSessionToken;

  const SetNewPasswordScreen({super.key, required this.resetSessionToken});

  @override
  ConsumerState<SetNewPasswordScreen> createState() =>
      _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState
    extends ConsumerState<SetNewPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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
  }

  @override
  void dispose() {
    _glowController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    _isSubmitting = true;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(
        resetSessionToken: widget.resetSessionToken,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;
      AppSnackbar.success(
        context,
        'Password reset successfully. Please sign in.',
      );
      // All sessions were invalidated — send user to login.
      // go() replaces the entire stack so back-button can't return here.
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');

      // 401 / expired session token — direct user to restart from Step 1.
      if (message.toLowerCase().contains('reset session expired') ||
          message.toLowerCase().contains('start over')) {
        setState(() => _errorMessage =
            'Your reset session expired. Please request a new code.');
      } else {
        setState(() => _errorMessage = message);
      }
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
                // Back to Step 2
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
                          const SizedBox(height: 16),

                          // ── Icon ─────────────────────────────────────────
                          SlideInWidget(
                            delay: const Duration(milliseconds: 100),
                            child: AnimatedBuilder(
                              animation: _glowAnimation,
                              builder: (context, _) => Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1B2E),
                                  borderRadius:
                                      BorderRadius.circular(24),
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
                                  Icons.lock_open_outlined,
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
                                  'Set new password',
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
                                  'Choose a strong password for your account.',
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

                          const SizedBox(height: 40),

                          // ── New password field ────────────────────────────
                          SlideInWidget(
                            delay: const Duration(milliseconds: 300),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                  alignment:
                                      AlignmentDirectional.centerStart,
                                  child: Text(
                                    'New Password',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AuthField(
                                  controller: _passwordController,
                                  hintText: 'Minimum 6 characters',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  validator: (v) =>
                                      Validators.password(v),
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(() =>
                                        _obscurePassword =
                                            !_obscurePassword),
                                    child: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white38,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Confirm password field ────────────────────────
                          SlideInWidget(
                            delay: const Duration(milliseconds: 400),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                  alignment:
                                      AlignmentDirectional.centerStart,
                                  child: Text(
                                    'Confirm Password',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color:
                                          Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AuthField(
                                  controller: _confirmController,
                                  hintText: 'Re-enter your password',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscureConfirm,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (v != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(() =>
                                        _obscureConfirm =
                                            !_obscureConfirm),
                                    child: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white38,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Session-expired error banner ──────────────────
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _errorMessage != null
                                ? Padding(
                                    key: ValueKey(_errorMessage),
                                    padding:
                                        const EdgeInsets.only(top: 20),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF4B6E)
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFFFF4B6E)
                                              .withOpacity(0.4),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Color(0xFFFF4B6E),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(
                                                  _errorMessage!,
                                                  style: const TextStyle(
                                                    color:
                                                        Color(0xFFFF4B6E),
                                                    fontSize: 13,
                                                    height: 1.4,
                                                  ),
                                                ),
                                                // Only show "Start over" link for
                                                // session-expired errors
                                                if (_errorMessage!
                                                    .contains('expired')) ...[
                                                  const SizedBox(
                                                      height: 8),
                                                  GestureDetector(
                                                    onTap: () => context
                                                        .go(
                                                            '/forgot-password'),
                                                    child: const Text(
                                                      'Request a new code →',
                                                      style: TextStyle(
                                                        color: Color(
                                                            0xFF00B894),
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 36),

                          // ── Reset button ──────────────────────────────────
                          SlideInWidget(
                            delay: const Duration(milliseconds: 500),
                            child: GradientAuthButton(
                              label: 'Reset Password',
                              isLoading: _isLoading,
                              onTap: _submit,
                              colors: const [
                                Color(0xFF00B894),
                                Color(0xFF00CECE),
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
