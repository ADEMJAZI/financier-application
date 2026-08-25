import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/app_animations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
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
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Stack(
        children: [
          const ParticleBackground(),
          // Ambient glow — top-right teal
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) => Container(
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
          // Ambient glow — bottom-left cyan
          Positioned(
            bottom: -80,
            left: -80,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) => Container(
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
          // Subtle center glow behind logo
          Positioned(
            top: screenHeight * 0.08,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) => Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00B894)
                            .withOpacity(_glowAnimation.value * 0.3),
                        const Color(0xFF00CECE)
                            .withOpacity(_glowAnimation.value * 0.1),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),

                    // ── Logo ──
                    AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) => Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B894)
                                  .withOpacity(_glowAnimation.value * 0.7),
                              blurRadius: 40,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(0xFF00CECE)
                                  .withOpacity(_glowAnimation.value * 0.3),
                              blurRadius: 60,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/images/logo.jpg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Title ──
                    SlideInWidget(
                      delay: const Duration(milliseconds: 100),
                      child: Column(
                        children: [
                          const Text(
                            'Welcome Back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to manage your finances',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.45),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Email Field ──
                    SlideInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
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

                    const SizedBox(height: 22),

                    // ── Password Field ──
                    SlideInWidget(
                      delay: const Duration(milliseconds: 300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Password',
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
                            controller: _passwordController,
                            hintText: 'Enter your password',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            validator: (v) =>
                                Validators.required(v, fieldName: 'Password'),
                            suffixIcon: GestureDetector(
                              onTap: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
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

                    const SizedBox(height: 16),

                    // ── Remember me & Forgot password ──
                    SlideInWidget(
                      delay: const Duration(milliseconds: 400),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 40,
                                height: 24,
                                child: Switch(
                                  value: true,
                                  onChanged: (val) {},
                                  activeColor: Colors.white,
                                  activeTrackColor: const Color(0xFF00B894),
                                  trackOutlineWidth:
                                      WidgetStateProperty.all(0),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('Remember me',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12)),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => context.push('/forgot-password'),
                            child: Text('Forgot Password?',
                                style: TextStyle(
                                  color: const Color(0xFF00B894).withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Login Button ──
                    SlideInWidget(
                      delay: const Duration(milliseconds: 500),
                      child: GradientAuthButton(
                        label: 'Log In',
                        isLoading: _isLoading,
                        onTap: _login,
                        colors: const [Color(0xFF00B894), Color(0xFF00CECE)],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Divider ──
                    SlideInWidget(
                      delay: const Duration(milliseconds: 600),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.15),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('or continue with',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 12,
                                    letterSpacing: 0.5)),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.15),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Social Buttons ──
                    SlideInWidget(
                      delay: const Duration(milliseconds: 700),
                      child: const Row(
                        children: [
                          Expanded(
                              child: SocialAuthButton(
                                  label: 'Google', icon: Icons.g_mobiledata)),
                          SizedBox(width: 14),
                          Expanded(
                              child: SocialAuthButton(
                                  label: 'Apple', icon: Icons.apple)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ── Sign Up link ──
                    SlideInWidget(
                      delay: const Duration(milliseconds: 800),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account? ",
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 13)),
                          GestureDetector(
                            onTap: () => context.push('/register'),
                            child: const Text('Create an account',
                                style: TextStyle(
                                    color: Color(0xFF00B894),
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold)),
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
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    _isSubmitting = true;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      final authState = ref.read(authProvider).valueOrNull;
      if (authState?.status == AuthStatus.authenticated) {
        AppSnackbar.success(context, 'Welcome back!');
      } else if (authState?.error != null) {
        final message = authState!.error!.replaceFirst('Exception: ', '');
        AppSnackbar.error(context, message);
      }
    } finally {
      _isSubmitting = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
