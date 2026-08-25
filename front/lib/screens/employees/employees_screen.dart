import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/employee_provider.dart';
import '../../models/employee.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../providers/business_provider.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/gradient_fab.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final employeesAsync = ref.watch(employeeListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      body: employeesAsync.when(
        loading: () => const LoadingShimmerList(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(employeeListProvider),
        ),
        data: (employees) {
          if (employees.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline,
              title: 'No Employees',
              message: 'Add employees and track salary payments.',
              actionLabel: 'Add Employee',
              onAction: () => _showAddEmployeeSheet(context, ref),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(employeeListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: employees.length,
              itemBuilder: (ctx, i) {
                final emp = employees[i];
                return _EmployeeCard(
                  employee: emp,
                  isDark: isDark,
                  onRecordPayment: () => _showRecordPaymentSheet(context, ref, emp),
                  onDeactivate: () => _deactivateEmployee(context, ref, emp),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: GradientFAB(
          icon: LucideIcons.plus,
          label: 'Add Employee',
          onPressed: () => _showAddEmployeeSheet(context, ref),
        ),
      ),
    );
  }

  void _showAddEmployeeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => _AddEmployeeSheet(ref: ref),
    );
  }

  void _showRecordPaymentSheet(BuildContext context, WidgetRef ref, Employee employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => _RecordPaymentSheet(employee: employee, ref: ref),
    );
  }

  Future<void> _deactivateEmployee(BuildContext context, WidgetRef ref, Employee emp) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Deactivate Employee',
      message: 'Are you sure you want to deactivate and soft-delete:',
      itemName: emp.name,
    );

    if (confirmed && context.mounted) {
      try {
        await ref.read(employeeNotifierProvider.notifier).deactivateEmployee(emp.id);
        ref.invalidate(employeeListProvider);
        if (context.mounted) AppSnackbar.success(context, 'Employee status updated to inactive');
      } catch (e) {
        if (context.mounted) AppSnackbar.error(context, e.toString());
      }
    }
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;
  final bool isDark;
  final VoidCallback onRecordPayment;
  final VoidCallback onDeactivate;

  const _EmployeeCard({
    required this.employee,
    required this.isDark,
    required this.onRecordPayment,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final statusColor = employee.isActive
        ? (isDark ? AppColors.successDark : AppColors.successLight)
        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight);

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: EdgeInsets.zero,
      isSelected: employee.isActive,
      selectedAccentColor: primaryColor,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(AppSpacing.lg),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: employee.isActive 
                ? AppColors.iconContainerGradient(primaryColor, isDark: isDark)
                : null,
            color: employee.isActive ? null : statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(LucideIcons.user, color: statusColor, size: 24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(employee.name,
                  style: AppTypography.bodyMedium.copyWith(fontWeight: AppTypography.semiBold)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                employee.status,
                style: AppTypography.labelSmall.copyWith(color: statusColor, fontWeight: AppTypography.semiBold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (employee.role != null && employee.role!.isNotEmpty)
              Text('Role: ${employee.role}', style: AppTypography.labelSmall),
            Text(
              'Salary: ${Formatters.currency(employee.salary)}',
              style: AppTypography.labelSmall.copyWith(fontWeight: AppTypography.semiBold),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (employee.isActive)
              IconButton(
                icon: Icon(LucideIcons.userMinus, size: 20, color: theme.colorScheme.error.withOpacity(0.6)),
                onPressed: onDeactivate,
              ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          if (employee.isActive) ...[
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Record Salary Payment',
                    icon: LucideIcons.banknote,
                    onPressed: onRecordPayment,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (employee.payments.isNotEmpty) ...[
            Text('Payment History',
                style: AppTypography.labelMedium.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: AppSpacing.sm),
            ...employee.payments.reversed.take(5).map((p) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(LucideIcons.checkCircle2,
                    size: 16, color: isDark ? AppColors.successDark : AppColors.successLight),
                title: Text(
                  Formatters.currency(p.amount),
                  style: AppTypography.bodySmall.copyWith(fontWeight: AppTypography.semiBold),
                ),
                subtitle: p.note != null && p.note!.isNotEmpty
                    ? Text(p.note!, style: AppTypography.labelSmall)
                    : null,
                trailing: Text(Formatters.date(p.date), style: AppTypography.labelSmall),
              );
            }),
          ] else ...[
            Text('No payments recorded yet',
                style: AppTypography.labelSmall.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5))),
          ],
        ],
      ),
    );
  }
}

class _AddEmployeeSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _AddEmployeeSheet({required this.ref});

  @override
  ConsumerState<_AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends ConsumerState<_AddEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              Text('Add Employee', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => Validators.required(v, fieldName: 'Employee name'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _roleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Role / Designation (optional)',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _salaryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Monthly Salary (DT)',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '0.000',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => Validators.positiveNumber(v, fieldName: 'Salary'),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Save Employee',
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
      final businessId = widget.ref.read(activeBusinessIdProvider);
      if (businessId == null) throw Exception('No business selected');

      await widget.ref.read(employeeNotifierProvider.notifier).createEmployee({
        'business': businessId,
        'name': _nameCtrl.text.trim(),
        'role': _roleCtrl.text.trim().isEmpty ? null : _roleCtrl.text.trim(),
        'salary': Validators.parseDouble(_salaryCtrl.text),
      });

      widget.ref.invalidate(employeeListProvider);

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success(context, 'Employee added successfully');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  final Employee employee;
  final WidgetRef ref;

  const _RecordPaymentSheet({required this.employee, required this.ref});

  @override
  ConsumerState<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.employee.salary.toStringAsFixed(3);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              Text('Record Salary Payment', style: AppTypography.h3),
              Text('Employee: ${widget.employee.name}', style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Payment Amount (DT)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => Validators.positiveNumber(v, fieldName: 'Payment amount'),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  hintText: 'e.g. Salary July 2026',
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await widget.ref.read(employeeNotifierProvider.notifier).recordPayment(
        widget.employee.id,
        {
          'amount': Validators.parseDouble(_amountCtrl.text),
          'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          'date': DateTime.now().toIso8601String(),
        },
      );

      widget.ref.invalidate(employeeListProvider);

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success(context, 'Salary payment recorded');
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}



