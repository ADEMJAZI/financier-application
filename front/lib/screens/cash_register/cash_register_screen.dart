import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/cash_register_provider.dart';
import '../../models/cash_register.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/premium_card.dart';
import '../../providers/business_provider.dart';

class CashRegisterScreen extends ConsumerWidget {
  const CashRegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registersAsync = ref.watch(cashRegisterNotifierProvider);
    final todayRegisterAsync = ref.watch(todayCashRegisterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cash Registers')),
      body: Column(
        children: [
          todayRegisterAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(todayCashRegisterProvider),
            ),
            data: (reg) => _TodayRegisterStatusHeader(reg: reg, ref: ref),
          ),
          const Divider(),
          Expanded(
            child: registersAsync.when(
              loading: () => const LoadingShimmerList(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(cashRegisterNotifierProvider),
              ),
              data: (registers) {
                if (registers.isEmpty) {
                  return EmptyState(
                    icon: Icons.history_toggle_off,
                    title: 'No Register History',
                    message: 'Once you open and close registers, your history will appear here.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(cashRegisterNotifierProvider);
                    ref.invalidate(todayCashRegisterProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
                    itemCount: registers.length,
                    itemBuilder: (ctx, i) => _RegisterHistoryCard(reg: registers[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayRegisterStatusHeader extends StatelessWidget {
  final CashRegister? reg;
  final WidgetRef ref;
  const _TodayRegisterStatusHeader({required this.reg, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isOpen = reg != null && reg!.isOpen;
    final statusColor = isOpen
        ? (isDark ? AppColors.successDark : AppColors.successLight)
        : (isDark ? AppColors.dangerDark : AppColors.dangerLight);

    return PremiumCard(
      padding: const EdgeInsetsDirectional.all(AppSpacing.xl),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isOpen ? Icons.lock_open : Icons.lock_outline, color: statusColor, size: 28),
              const SizedBox(width: AppSpacing.md),
              Text(
                isOpen ? 'Register is Open' : 'Register is Closed',
                style: AppTypography.h3.copyWith(color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (isOpen) ...[
            Text('Opened: ${Formatters.dateTime(reg!.openedAt)}', style: AppTypography.bodySmall),
            const SizedBox(height: 2),
            Text('Opening Balance: ${Formatters.currency(reg!.openingBalance)}',
                style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold)),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Close Daily Register',
              variant: AppButtonVariant.primary,
              onPressed: () => _showCloseRegisterDialog(context, reg!),
            ),
          ] else ...[
            Text('Start of day register is not open.', style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Open New Register',
              onPressed: () => _showOpenRegisterDialog(context),
            ),
          ],
        ],
      ),
    );
  }

  void _showOpenRegisterDialog(BuildContext context) {
    showDialog(context: context, builder: (ctx) => _OpenRegisterDialog(ref: ref));
  }

  void _showCloseRegisterDialog(BuildContext context, CashRegister reg) {
    showDialog(context: context, builder: (ctx) => _CloseRegisterDialog(reg: reg, ref: ref));
  }
}

class _OpenRegisterDialog extends StatefulWidget {
  final WidgetRef ref;
  const _OpenRegisterDialog({required this.ref});
  @override
  State<_OpenRegisterDialog> createState() => _OpenRegisterDialogState();
}

class _OpenRegisterDialogState extends State<_OpenRegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Open Register'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _amountCtrl,
          decoration: const InputDecoration(labelText: 'Opening Cash Balance (DT)', prefixIcon: Icon(Icons.attach_money), hintText: '0.000'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (v) => Validators.nonNegativeNumber(v, fieldName: 'Opening balance'),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Open'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final businessId = widget.ref.read(activeBusinessIdProvider);
      if (businessId == null) throw Exception('No business selected');
      await widget.ref.read(cashRegisterNotifierProvider.notifier).openRegister({'business': businessId, 'openingBalance': Validators.parseDouble(_amountCtrl.text)});
      widget.ref.invalidate(todayCashRegisterProvider);
      if (mounted) { Navigator.pop(context); AppSnackbar.success(context, 'Register opened successfully'); }
    } catch (e) { if (mounted) AppSnackbar.error(context, e.toString()); }
    finally { if (mounted) setState(() => _isSubmitting = false); }
  }
}

class _CloseRegisterDialog extends StatefulWidget {
  final CashRegister reg;
  final WidgetRef ref;
  const _CloseRegisterDialog({required this.reg, required this.ref});
  @override
  State<_CloseRegisterDialog> createState() => _CloseRegisterDialogState();
}

class _CloseRegisterDialogState extends State<_CloseRegisterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() { _amountCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Close Register'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Opening Balance: ${Formatters.currency(widget.reg.openingBalance)}', style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(labelText: 'Actual Closing Cash (DT)', prefixIcon: Icon(Icons.attach_money), hintText: '0.000'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => Validators.nonNegativeNumber(v, fieldName: 'Closing balance'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Close Register'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.ref.read(cashRegisterNotifierProvider.notifier).closeRegister(widget.reg.id, Validators.parseDouble(_amountCtrl.text));
      widget.ref.invalidate(todayCashRegisterProvider);
      if (mounted) { Navigator.pop(context); AppSnackbar.success(context, 'Register closed successfully'); }
    } catch (e) { if (mounted) AppSnackbar.error(context, e.toString()); }
    finally { if (mounted) setState(() => _isSubmitting = false); }
  }
}

class _RegisterHistoryCard extends StatelessWidget {
  final CashRegister reg;
  const _RegisterHistoryCard({required this.reg});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = reg.isOpen ? (isDark ? AppColors.successDark : AppColors.successLight) : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    final diff = reg.difference;
    final hasDiscrepancy = reg.hasDiscrepancy;

    return PremiumCard(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Formatters.date(reg.openedAt), style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold)),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: const BorderRadiusDirectional.all(Radius.circular(AppSpacing.radiusSm)),
                ),
                child: Text(reg.isOpen ? 'Open' : 'Closed', style: AppTypography.labelSmall.copyWith(color: statusColor, fontWeight: AppTypography.semiBold)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _MiniItem(label: 'Opening', value: Formatters.currency(reg.openingBalance))),
              if (reg.closingBalance != null) Expanded(child: _MiniItem(label: 'Closing', value: Formatters.currency(reg.closingBalance!))),
              if (reg.expectedBalance != null) Expanded(child: _MiniItem(label: 'Expected', value: Formatters.currency(reg.expectedBalance!))),
            ],
          ),
          if (!reg.isOpen && diff != null) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(color: theme.dividerColor),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Difference:', style: AppTypography.labelMedium),
                Text('${diff >= 0 ? '+' : ''}${Formatters.currency(diff)}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: AppTypography.bold,
                      color: hasDiscrepancy ? (isDark ? AppColors.dangerDark : AppColors.dangerLight) : (isDark ? AppColors.successDark : AppColors.successLight),
                    )),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniItem extends StatelessWidget {
  final String label;
  final String value;
  const _MiniItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.bodySmall.copyWith(fontWeight: AppTypography.semiBold)),
      ],
    );
  }
}
