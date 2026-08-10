import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/reserve_provider.dart';
import '../../models/reserve.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../providers/business_provider.dart';

class ReservesScreen extends ConsumerWidget {
  const ReservesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservesAsync = ref.watch(reserveNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reserve Funds')),
      body: reservesAsync.when(
        loading: () => const LoadingShimmerList(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(reserveNotifierProvider),
        ),
        data: (reserves) {
          if (reserves.isEmpty) {
            return EmptyState(
              icon: Icons.savings_outlined,
              title: 'No Reserve Funds',
              message: 'Create a savings fund to set aside business capital.',
              actionLabel: 'Create Fund',
              onAction: () => _showCreateReserveSheet(context, ref),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(reserveNotifierProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: reserves.length,
              itemBuilder: (ctx, i) => _ReserveCard(
                reserve: reserves[i],
                onDeposit: () =>
                    _showTransactionSheet(context, ref, reserves[i], isDeposit: true),
                onWithdraw: () =>
                    _showTransactionSheet(context, ref, reserves[i], isDeposit: false),
                onDelete: () => _deleteReserve(context, ref, reserves[i]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(heroTag: null,
        onPressed: () => _showCreateReserveSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Fund'),
      ),
    );
  }

  void _showCreateReserveSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => _CreateReserveSheet(ref: ref),
    );
  }

  void _showTransactionSheet(
      BuildContext context, WidgetRef ref, Reserve reserve,
      {required bool isDeposit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) =>
          _TransactionSheet(reserve: reserve, isDeposit: isDeposit, ref: ref),
    );
  }

  Future<void> _deleteReserve(
      BuildContext context, WidgetRef ref, Reserve reserve) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Reserve Fund',
      message: 'This will permanently delete the fund:',
      itemName: reserve.name,
    );
    if (confirmed && context.mounted) {
      try {
        await ref.read(reserveNotifierProvider.notifier).deleteReserve(reserve.id);
        if (context.mounted) AppSnackbar.success(context, 'Fund deleted');
      } catch (e) {
        if (context.mounted) AppSnackbar.error(context, e.toString());
      }
    }
  }
}

class _ReserveCard extends StatelessWidget {
  final Reserve reserve;
  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;
  final VoidCallback onDelete;

  const _ReserveCard({
    required this.reserve,
    required this.onDeposit,
    required this.onWithdraw,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final successColor = isDark ? AppColors.successDark : AppColors.successLight;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(AppSpacing.lg),
        childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(Icons.savings_outlined, color: successColor, size: 24),
        ),
        title: Text(reserve.name,
            style: AppTypography.bodyMedium
                .copyWith(fontWeight: AppTypography.semiBold)),
        subtitle: Text(
          'Balance: ${Formatters.currency(reserve.balance)}',
          style: AppTypography.h4.copyWith(color: successColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20,
                  color: theme.colorScheme.onSurface.withOpacity(0.4)),
              onPressed: onDelete,
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDeposit,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Deposit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: successColor,
                    side: BorderSide(color: successColor),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: reserve.balance > 0 ? onWithdraw : null,
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text('Withdraw'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.warningDark
                        : AppColors.warningLight,
                    side: BorderSide(
                        color: isDark
                            ? AppColors.warningDark
                            : AppColors.warningLight),
                  ),
                ),
              ),
            ],
          ),
          // Transaction history
          if (reserve.transactions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('Transaction History',
                style: AppTypography.labelMedium
                    .copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: AppSpacing.sm),
            ...reserve.transactions.reversed.take(5).map((t) {
              final isDeposit = t.isDeposit;
              final color = isDeposit
                  ? (isDark ? AppColors.successDark : AppColors.successLight)
                  : (isDark ? AppColors.dangerDark : AppColors.dangerLight);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  isDeposit
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  color: color,
                  size: 18,
                ),
                title: Text(
                  '${isDeposit ? '+' : '-'}${Formatters.currency(t.amount)}',
                  style: AppTypography.bodySmall.copyWith(
                      color: color, fontWeight: AppTypography.semiBold),
                ),
                subtitle: t.note != null && t.note!.isNotEmpty
                    ? Text(t.note!, style: AppTypography.labelSmall)
                    : null,
                trailing: Text(Formatters.date(t.date),
                    style: AppTypography.labelSmall.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5))),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _CreateReserveSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _CreateReserveSheet({required this.ref});

  @override
  ConsumerState<_CreateReserveSheet> createState() =>
      _CreateReserveSheetState();
}

class _CreateReserveSheetState extends ConsumerState<_CreateReserveSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Create Reserve Fund', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Fund Name',
                  prefixIcon: Icon(Icons.savings_outlined),
                ),
                validator: (v) => Validators.required(v, fieldName: 'Fund name'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _balanceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Initial Balance (DT)',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '0.000',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    Validators.nonNegativeNumber(v, fieldName: 'Balance'),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Create Fund',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final businessId = ref.read(activeBusinessIdProvider);
      if (businessId == null) throw Exception('No business selected');
      await ref.read(reserveNotifierProvider.notifier).createReserve({
        'business': businessId,
        'name': _nameCtrl.text.trim(),
        'balance': Validators.parseDouble(_balanceCtrl.text),
      });
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.success(context, 'Reserve fund created');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _TransactionSheet extends ConsumerStatefulWidget {
  final Reserve reserve;
  final bool isDeposit;
  final WidgetRef ref;

  const _TransactionSheet({
    required this.reserve,
    required this.isDeposit,
    required this.ref,
  });

  @override
  ConsumerState<_TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends ConsumerState<_TransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDeposit = widget.isDeposit;
    final actionColor = isDeposit
        ? (isDark ? AppColors.successDark : AppColors.successLight)
        : (isDark ? AppColors.warningDark : AppColors.warningLight);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                    color: actionColor,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${isDeposit ? 'Deposit to' : 'Withdraw from'} ${widget.reserve.name}',
                    style: AppTypography.h3,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Current balance: ${Formatters.currency(widget.reserve.balance)}',
                style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Amount (DT)',
                  prefixIcon: Icon(
                    isDeposit ? Icons.add : Icons.remove,
                    color: actionColor,
                  ),
                  hintText: '0.000',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final err = Validators.positiveNumber(v, fieldName: 'Amount');
                  if (err != null) return err;
                  if (!isDeposit) {
                    final amount = Validators.parseDouble(v!);
                    if (amount > widget.reserve.balance) {
                      return 'Insufficient balance';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: isDeposit ? 'Deposit' : 'Withdraw',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final amount = Validators.parseDouble(_amountCtrl.text);
      final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
      if (widget.isDeposit) {
        await ref
            .read(reserveNotifierProvider.notifier)
            .deposit(widget.reserve.id, amount, note);
      } else {
        await ref
            .read(reserveNotifierProvider.notifier)
            .withdraw(widget.reserve.id, amount, note);
      }
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.success(context,
            widget.isDeposit ? 'Deposit recorded' : 'Withdrawal recorded');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}



