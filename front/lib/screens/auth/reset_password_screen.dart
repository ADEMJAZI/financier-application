import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/service_providers.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  /// Raw reset token from the deep-link query parameter ?token=...
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _resetDone = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    if (widget.token.isEmpty) {
      AppSnackbar.error(context, 'Invalid reset link — no token found.');
      return;
    }

    _isSubmitting = true;
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.resetPassword(
        token: widget.token,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _resetDone = true);
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
        title: const Text('Reset Password'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        // Hide back button once reset is done — user should go to login
        automaticallyImplyLeading: !_resetDone,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: _resetDone ? _buildSuccess(theme) : _buildForm(theme),
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
          Icons.lock_outlined,
          size: 72,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          'Create new password',
          style: AppTypography.h2.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),

        Text(
          'Your new password must be at least 6 characters long.',
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
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  hintText: 'Enter new password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) => Validators.password(value),
                enabled: !_isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),

              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  hintText: 'Re-enter new password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                enabled: !_isLoading,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),

              AppButton(
                label: 'Reset Password',
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xxl),

        Icon(
          Icons.check_circle_outline,
          size: 72,
          color: Colors.green,
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          'Password reset!',
          style: AppTypography.h2.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),

        Text(
          'Your password has been changed successfully. All existing sessions have been signed out for your security.',
          style: AppTypography.bodyMedium.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxxl),

        AppButton(
          label: 'Sign In',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
