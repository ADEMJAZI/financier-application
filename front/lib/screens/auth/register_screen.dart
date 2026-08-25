import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_widgets.dart';
import '../../widgets/app_animations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C14),
      body: Stack(
        children: [
          const ParticleBackground(color: Color(0xFF00CECE)),
          // Teal glow top-right
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00B894).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00CECE).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),

                    // Simple Finance Grid Logo
                    SlideInWidget(
                      delay: const Duration(milliseconds: 100),
                      child: Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1B2E),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFF00B894).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.grid_view_rounded,
                            color: Color(0xFF00B894),
                            size: 36,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SlideInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: Column(
                        children: const [
                          Center(
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Join us to start managing your business',
                              style: TextStyle(fontSize: 13, color: Colors.white54),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 36),

                    // Full Name
                    SlideInWidget(
                      delay: const Duration(milliseconds: 300),
                      child: AuthField(
                        controller: _nameController,
                        hintText: 'Full Name',
                        icon: Icons.person_outline,
                        validator: (v) => Validators.required(v, fieldName: 'Full name'),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Email
                    SlideInWidget(
                      delay: const Duration(milliseconds: 400),
                      child: AuthField(
                        controller: _emailController,
                        hintText: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => Validators.email(v),
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Password
                    SlideInWidget(
                      delay: const Duration(milliseconds: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            validator: (v) => Validators.password(v),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white38,
                                size: 20,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 4, top: 4),
                            child: Text('Minimum 6 characters',
                                style: TextStyle(color: Colors.white38, fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    // Confirm Password
                    SlideInWidget(
                      delay: const Duration(milliseconds: 600),
                      child: AuthField(
                        controller: _confirmPasswordController,
                        hintText: 'Confirm Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please confirm your password';
                          if (v != _passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          child: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white38,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Create Account Button — Teal/Green
                    SlideInWidget(
                      delay: const Duration(milliseconds: 700),
                      child: GradientAuthButton(
                        label: 'Create Account',
                        isLoading: _isLoading,
                        onTap: _register,
                        colors: const [Color(0xFF00B894), Color(0xFF00CECE)],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sign In link
                    SlideInWidget(
                      delay: const Duration(milliseconds: 800),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ',
                              style: TextStyle(color: Colors.white38, fontSize: 13)),
                          GestureDetector(
                            onTap: () => context.pushReplacement('/login'),
                            child: const Text('Sign In',
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    _isSubmitting = true;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      final authState = ref.read(authProvider).valueOrNull;
      if (authState?.status == AuthStatus.authenticated) {
        // Navigate to OTP screen before the router redirect fires.
        // /verify-email is in the auth-exempt list so the router will not
        // redirect an authenticated user away from it.
        final email = Uri.encodeComponent(_emailController.text.trim());
        context.pushReplacement('/verify-email?email=$email');
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
