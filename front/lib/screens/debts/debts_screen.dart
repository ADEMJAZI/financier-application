import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/debt_provider.dart';
import '../../providers/business_provider.dart';
import '../../models/customer_debt.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirmation_dialog.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filter = ref.watch(debtStatusFilterProvider);
    final filteredDebtsAsync = ref.watch(filteredDebtListProvider);
    final totalRemaining = ref.watch(totalRemainingProvider);
    final unpaidCount = ref.watch(unpaidDebtsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Debts'),
      ),
      body: Column(
        children: [
          // Summary Cards
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Outstanding',
                    value: Formatters.currency(totalRemaining),
                    icon: Icons.account_balance_wallet_outlined,
                    color: isDark ? AppColors.dangerDark : AppColors.dangerLight,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SummaryCard(
                    title: 'Unpaid',
                    value: '$unpaidCount Debts',
                    icon: Icons.error_outline,
                    color: isDark ? AppColors.warningDark : AppColors.warningLight,
                  ),
                ),
              ],
            ),
          ),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Row(
              children: [
                {'label': 'All', 'value': 'all'},
                {'label': 'Unpaid', 'value': 'unpaid'},
                {'label': 'Partial', 'value': 'partial'},
                {'label': 'Paid', 'value': 'paid'},
              ].map((item) {
                final value = item['value']!;
                final selected = filter == value;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(item['label']!),
                    selected: selected,
                    onSelected: (_) =>
                        ref.read(debtStatusFilterProvider.notifier).state =
                            value,
                    selectedColor:
                        theme.colorScheme.primary.withOpacity(0.15),
                    checkmarkColor: theme.colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Debt List
          Expanded(
            child: filteredDebtsAsync.when(
              loading: () => const LoadingShimmerList(),
              error: (error, _) => ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(debtListProvider),
              ),
              data: (debts) {
                if (debts.isEmpty) {
                  return EmptyState(
                    icon: Icons.payment_outlined,
                    title: 'No Debts Found',
                    message: filter == 'all'
                        ? 'Track customer payments and outstanding debts here.'
                        : 'No ${filter == "all" ? "" : filter} debts found.',
                    actionLabel: 'Add Debt',
                    onAction: () =>
                        _showAddDebtBottomSheet(context, ref),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(debtListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: 90),
                    itemCount: debts.length,
                    itemBuilder: (ctx, i) {
                      return _DebtCard(
                        debt: debts[i],
                        isDark: isDark,
                        onAddPayment: () =>
                            _showAddPaymentSheet(context, ref, debts[i]),
                        onDelete: () =>
                            _deleteDebt(context, ref, debts[i]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => _showAddDebtBottomSheet(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Add Debt'),
        ),
      ),
    );
  }

  void _showAddDebtBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useRootNavigator: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (modalContext) => _AddDebtSheet(ref: ref),
    );
  }

  void _showAddPaymentSheet(
      BuildContext context, WidgetRef ref, CustomerDebt debt) {
    print('ðŸ”µ DEBUG: _showAddPaymentSheet called for debt: ${debt.customerName}');
    print('ðŸ”µ DEBUG: Debt ID: ${debt.id}');
    print('ðŸ”µ DEBUG: Remaining amount: ${debt.remainingAmount}');
    
    // Use root navigator to prevent context issues with nested navigators
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useRootNavigator: false, // Use current context navigator
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (modalContext) {
        print('ðŸ”µ DEBUG: Bottom sheet builder called');
        // Pass the original ref, not the modal context's ref
        return _AddPaymentSheet(debt: debt, ref: ref);
      },
    ).then((value) {
      print('ðŸ”µ DEBUG: Bottom sheet dismissed with value: $value');
    }).catchError((error) {
      print('ðŸ”´ DEBUG: Error showing bottom sheet: $error');
    });
  }

  Future<void> _deleteDebt(
      BuildContext context, WidgetRef ref, CustomerDebt debt) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Debt',
      message: 'Are you sure you want to delete the debt for:',
      itemName: debt.customerName,
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(debtNotifierProvider.notifier).deleteDebt(debt.id);
        if (context.mounted) AppSnackbar.success(context, 'Debt deleted');
      } catch (e) {
        if (context.mounted) AppSnackbar.error(context, e.toString());
      }
    }
  }
}

// â”€â”€â”€ Summary Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.md),
          Text(title,
              style: AppTypography.labelSmall.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              )),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style: AppTypography.h4.copyWith(
                color: theme.colorScheme.onSurface,
              )),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Debt Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DebtCard extends StatefulWidget {
  final CustomerDebt debt;
  final bool isDark;
  final VoidCallback onAddPayment;
  final VoidCallback onDelete;

  const _DebtCard({
    required this.debt,
    required this.isDark,
    required this.onAddPayment,
    required this.onDelete,
  });

  @override
  State<_DebtCard> createState() => _DebtCardState();
}

class _DebtCardState extends State<_DebtCard> {
  bool _isProcessing = false;

  void _handleAddPayment() {
    if (_isProcessing) {
      print('ðŸ”´ DEBUG: Payment already in progress, ignoring click');
      return;
    }
    
    setState(() => _isProcessing = true);
    print('ðŸ”µ DEBUG: Record Payment button clicked!');
    
    widget.onAddPayment();
    
    // Reset after a delay to prevent double-clicks
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(Icons.person_outline,
                      color: theme.colorScheme.primary, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.debt.customerName,
                          style: AppTypography.bodyMedium.copyWith(
                              fontWeight: AppTypography.semiBold)),
                      const SizedBox(height: 2),
                      Text(Formatters.relativeTime(widget.debt.createdAt),
                          style: AppTypography.labelSmall.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.5))),
                    ],
                  ),
                ),
                StatusBadge(status: widget.debt.status),
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            Divider(color: theme.dividerColor),
            const SizedBox(height: AppSpacing.md),

            // Amount details
            Row(
              children: [
                Expanded(
                  child: _AmountItem(
                    label: 'Total',
                    value: Formatters.currency(widget.debt.totalAmount),
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: _AmountItem(
                    label: 'Paid',
                    value: Formatters.currency(widget.debt.paidAmount),
                    color: widget.isDark
                        ? AppColors.successDark
                        : AppColors.successLight,
                  ),
                ),
                Expanded(
                  child: _AmountItem(
                    label: 'Remaining',
                    value: Formatters.currency(widget.debt.remainingAmount),
                    color: widget.isDark
                        ? AppColors.dangerDark
                        : AppColors.dangerLight,
                  ),
                ),
              ],
            ),

            // Progress bar
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: widget.debt.paidPercentage / 100,
                backgroundColor:
                    theme.colorScheme.onSurface.withOpacity(0.1),
                color: widget.debt.isFullyPaid
                    ? (widget.isDark
                        ? AppColors.successDark
                        : AppColors.successLight)
                    : widget.debt.isPartiallyPaid
                        ? (widget.isDark
                            ? AppColors.warningDark
                            : AppColors.warningLight)
                        : (widget.isDark
                            ? AppColors.dangerDark
                            : AppColors.dangerLight),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${widget.debt.paidPercentage.toStringAsFixed(0)}% paid',
              style: AppTypography.labelSmall.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),

            // Payment history (collapsed)
            if (widget.debt.payments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  '${widget.debt.payments.length} payment${widget.debt.payments.length > 1 ? 's' : ''}',
                  style: AppTypography.labelMedium.copyWith(
                      color: theme.colorScheme.primary),
                ),
                children: widget.debt.payments.map((p) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm),
                    dense: true,
                    leading: Icon(Icons.check_circle_outline,
                        size: 16,
                        color: widget.isDark
                            ? AppColors.successDark
                            : AppColors.successLight),
                    title: Text(Formatters.currency(p.amount),
                        style: AppTypography.bodySmall.copyWith(
                            fontWeight: AppTypography.semiBold)),
                    subtitle: p.note != null && p.note!.isNotEmpty
                        ? Text(p.note!,
                            style: AppTypography.labelSmall)
                        : null,
                    trailing: Text(Formatters.date(p.date),
                        style: AppTypography.labelSmall.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.5))),
                  );
                }).toList(),
              ),
            ],

            // Add Payment button
            if (!widget.debt.isFullyPaid) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _handleAddPayment,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Record Payment'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AmountItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelSmall.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.5))),
        const SizedBox(height: AppSpacing.xs),
        Text(value,
            style: AppTypography.bodySmall
                .copyWith(color: color, fontWeight: AppTypography.semiBold)),
      ],
    );
  }
}

// â”€â”€â”€ Add Debt Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _AddDebtSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddDebtSheet({required this.ref});

  @override
  ConsumerState<_AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends ConsumerState<_AddDebtSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
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
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Add Customer Debt', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    Validators.required(v, fieldName: 'Customer name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Total Amount (DT)',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '0.000',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    Validators.positiveNumber(v, fieldName: 'Amount'),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Add Debt',
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

      await ref.read(debtNotifierProvider.notifier).createDebt({
        'business': businessId,
        'customerName': _nameCtrl.text.trim(),
        'totalAmount': Validators.parseDouble(_amountCtrl.text),
      });

      if (mounted) {
        Navigator.of(context).pop();
        AppSnackbar.success(context, 'Debt recorded');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

// â”€â”€â”€ Add Payment Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _AddPaymentSheet extends ConsumerStatefulWidget {
  final CustomerDebt debt;
  final WidgetRef ref;

  const _AddPaymentSheet({required this.debt, required this.ref});

  @override
  ConsumerState<_AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends ConsumerState<_AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    print('ðŸ”µ DEBUG: _AddPaymentSheet initState');
  }

  @override
  void dispose() {
    print('ðŸ”µ DEBUG: _AddPaymentSheet dispose');
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = widget.debt.remainingAmount;

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
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Record Payment', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Customer: ${widget.debt.customerName}',
                style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
              Text(
                'Remaining: ${Formatters.currency(remaining)}',
                style: AppTypography.bodySmall.copyWith(
                    color: AppColors.dangerLight,
                    fontWeight: AppTypography.semiBold),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _amountCtrl,
                decoration: InputDecoration(
                  labelText: 'Payment Amount (DT)',
                  prefixIcon: const Icon(Icons.attach_money),
                  hintText: Formatters.currency(remaining),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final err =
                      Validators.positiveNumber(v, fieldName: 'Amount');
                  if (err != null) return err;
                  final val = Validators.parseDouble(v!);
                  if (val > remaining) {
                    return 'Amount cannot exceed remaining balance';
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
                label: 'Record Payment',
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
    print('ðŸŸ¢ DEBUG: _submit called in _AddPaymentSheet');
    if (!_formKey.currentState!.validate()) {
      print('ðŸ”´ DEBUG: Form validation failed');
      return;
    }
    
    print('ðŸŸ¢ DEBUG: Form validated, starting submission');
    setState(() => _isSubmitting = true);
    
    try {
      final amount = Validators.parseDouble(_amountCtrl.text);
      final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
      
      print('ðŸŸ¢ DEBUG: Calling addPayment - debtId: ${widget.debt.id}, amount: $amount, note: $note');
      
      await ref.read(debtNotifierProvider.notifier).addPayment(
            widget.debt.id,
            amount,
            note,
          );
      
      print('ðŸŸ¢ DEBUG: addPayment completed successfully');
      
      if (mounted) {
        // Close modal first
        Navigator.of(context).pop();
        
        // Small delay to ensure modal is closed before showing snackbar
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          AppSnackbar.success(context, 'Payment recorded successfully');
        }
      }
    } catch (e) {
      print('ðŸ”´ DEBUG: Error in _submit: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppSnackbar.error(context, 'Failed to record payment: ${e.toString()}');
      }
    }
  }
}



