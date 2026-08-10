import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/service_providers.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Once the request succeeds we show a confirmation view instead of the form
  bool _emailSent = false;

  @override
  void dispose() {
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
      await authService.forgotPassword(email: _emailController.text.trim());

      if (!mounted) return;
      setState(() => _emailSent = true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      AppSnackbar.error(context, message);
    } finally {
      _isSubmitting = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: _emailSent ? _buildConfirmation(theme) : _buildForm(theme),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxl),

        Icon(
          Icons.lock_reset_outlined,
          size: 72,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          'Reset your password',
          style: AppTypography.h2.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),

        Text(
          'Enter the email address associated with your account and we\'ll send you a reset link.',
          style: AppTypography.bodyMedium.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxxl),

        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'Enter your email address',
                ),
                validator: (value) => Validators.email(value),
                enabled: !_isLoading,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),

              AppButton(
                label: 'Send Reset Link',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmation(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxl),

        Icon(
          Icons.mark_email_read_outlined,
          size: 72,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          'Check your inbox',
          style: AppTypography.h2.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),

        Text(
          'If an account exists for ${_emailController.text.trim()}, '
          'a password reset link has been sent. Check your spam folder if you don\'t see it.',
          style: AppTypography.bodyMedium.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),

        Text(
          'The link expires in 1 hour.',
          style: AppTypography.bodySmall.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.45),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxxl),

        AppButton(
          label: 'Back to Sign In',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Allow resending without leaving the screen
        AppButton.secondary(
          label: 'Resend Email',
          isLoading: _isLoading,
          onPressed: () {
            setState(() => _emailSent = false);
          },
        ),
      ],
    );
  }
}
