import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../widgets/gradient_fab.dart';
import '../../widgets/fade_in_up.dart';
import '../../widgets/animated_count.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/expense_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/reports_provider.dart';
import '../../models/expense.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snackbar.dart';
import '../ai/smart_quick_add_sheet.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredExpensesAsync = ref.watch(filteredExpenseListProvider);
    final filter = ref.watch(expenseFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          // Filter chips in app bar
          PopupMenuButton<String>(
            initialValue: filter,
            onSelected: (value) =>
                ref.read(expenseFilterProvider.notifier).state = value,
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Fixed', child: Text('Fixed')),
              const PopupMenuItem(value: 'Variable', child: Text('Variable')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.filter_list,
                      color: filter != 'All'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface),
                  if (filter != 'All') ...[
                    const SizedBox(width: 4),
                    Text(filter,
                        style: AppTypography.labelSmall.copyWith(
                            color: theme.colorScheme.primary)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Row
          _ExpenseSummaryRow(isDark: isDark),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: ['All', 'Fixed', 'Variable'].map((f) {
                final selected = filter == f;
                // Localized labels for screen readers
                String semanticLabel;
                switch (f) {
                  case 'All':
                    semanticLabel = 'All expenses filter';
                    break;
                  case 'Fixed':
                    semanticLabel = 'Fixed expenses filter';
                    break;
                  case 'Variable':
                    semanticLabel = 'Variable expenses filter';
                    break;
                  default:
                    semanticLabel = '$f expenses filter';
                }

                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Semantics(
                    selected: selected,
                    button: true,
                    label: semanticLabel,
                    hint: selected ? 'Currently selected' : 'Tap to select',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            ref.read(expenseFilterProvider.notifier).state = f,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        child: Container(
                          // Ensure minimum 44x44 touch target
                          constraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 44,
                          ),
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: selected
                              ? AppColors.selectedCardGlow(
                                  theme.colorScheme.primary,
                                  isDark: isDark,
                                )
                              : BoxDecoration(
                                  border: Border.all(
                                    color: theme.dividerColor,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull,
                                  ),
                                ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selected)
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              if (selected) const SizedBox(width: 4),
                              Text(
                                f,
                                style: AppTypography.labelMedium.copyWith(
                                  color: selected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                  fontWeight: selected 
                                      ? AppTypography.semiBold
                                      : AppTypography.medium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // List
          Expanded(
            child: filteredExpensesAsync.when(
              loading: () => const LoadingShimmerList(),
              error: (error, _) => ErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(expenseListProvider),
              ),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Expenses Yet',
                    message: filter != 'All'
                        ? 'No $filter expenses found.'
                        : 'Start tracking your business expenses.',
                    actionLabel: 'Add Expense',
                    onAction: () => _showAddExpenseBottomSheet(context, ref),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(expenseListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: 90),
                    itemCount: expenses.length,
                    itemBuilder: (ctx, i) {
                      final expense = expenses[i];
                      return FadeInUp(
                        delay: Duration(milliseconds: i * 50),
                        child: _ExpenseCard(
                          expense: expense,
                          isDark: isDark,
                          onDelete: () => _deleteExpense(context, ref, expense),
                          onEdit: () =>
                              _showEditExpenseBottomSheet(context, ref, expense),
                        ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GradientFAB(
              heroTag: "ai_expense",
              onPressed: () => _showAiExpenseSheet(context, ref),
              icon: LucideIcons.sparkles,
            ),
            const SizedBox(height: AppSpacing.md),
            GradientFAB(
              heroTag: "manual_expense",
              onPressed: () => _showAddExpenseBottomSheet(context, ref),
              icon: LucideIcons.plus,
              label: 'Add Expense',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExpense(
      BuildContext context, WidgetRef ref, Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text(
            'Delete "${expense.category}" expense of ${Formatters.currency(expense.amount)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerLight),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final service = ref.read(expenseServiceProvider);
        await service.deleteExpense(expense.id);
        ref.invalidate(expenseListProvider);
        // Expenses affect daily profit and monthly cash flow — invalidate both.
        ref.invalidate(cashFlowReportProvider);
        ref.invalidate(todayDailyProfitProvider);
        
        // Add a small delay to ensure the dialog is fully dismissed
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (context.mounted) {
          AppSnackbar.success(context, 'Expense deleted');
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.error(context, e.toString());
        }
      }
    }
  }

  void _showAddExpenseBottomSheet(
    BuildContext context,
    WidgetRef ref, {
    double? prefillAmount,
    String? prefillCategory,
    String? prefillDescription,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => _ExpenseFormSheet(
        ref: ref,
        prefillAmount: prefillAmount,
        prefillCategory: prefillCategory,
        prefillDescription: prefillDescription,
      ),
    );
  }

  void _showAiExpenseSheet(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) => const SmartQuickAddSheet(),
    );
    if (result != null && context.mounted) {
      // Open the standard expense form pre-filled with AI-parsed data
      _showAddExpenseBottomSheet(
        context,
        ref,
        prefillAmount: result['amount'] as double?,
        prefillCategory: result['category'] as String?,
        prefillDescription: result['description'] as String?,
      );
    }
  }

  void _showEditExpenseBottomSheet(
      BuildContext context, WidgetRef ref, Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (ctx) =>
          _ExpenseFormSheet(ref: ref, expense: expense),
    );
  }
}

// â”€â”€â”€ Summary Row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ExpenseSummaryRow extends ConsumerWidget {
  final bool isDark;
  const _ExpenseSummaryRow({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final total = ref.watch(totalExpensesProvider);
    final fixed = ref.watch(fixedExpensesProvider);
    final variable = ref.watch(variableExpensesProvider);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark
                ? AppColors.primaryDark.withOpacity(0.3)
                : AppColors.primaryLight.withOpacity(0.08),
            isDark
                ? AppColors.secondaryDark.withOpacity(0.2)
                : AppColors.secondaryLight.withOpacity(0.06),
          ],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Total',
              value: Formatters.currency(total),
              numericValue: total,
              category: 'expense',
              color: isDark ? AppColors.dangerDark : AppColors.dangerLight,
              isDark: isDark,
            ),
          ),
          Container(
              width: 1, height: 40, color: theme.dividerColor),
          Expanded(
            child: _SummaryItem(
              label: 'Fixed',
              value: Formatters.currency(fixed),
              numericValue: fixed,
              category: 'rent',
              color: isDark ? AppColors.warningDark : AppColors.warningLight,
              isDark: isDark,
            ),
          ),
          Container(
              width: 1, height: 40, color: theme.dividerColor),
          Expanded(
            child: _SummaryItem(
              label: 'Variable',
              value: Formatters.currency(variable),
              numericValue: variable,
              category: 'utility',
              color: isDark ? AppColors.infoLight : AppColors.infoLight,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final double? numericValue;
  final String category;
  final Color color;
  final bool isDark;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.numericValue,
    required this.category,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: AppColors.categoryGradient(category, isDark: isDark),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        children: [
          Text(label,
              style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6))),
          const SizedBox(height: AppSpacing.xs),
          numericValue != null
              ? AnimatedCount(
                  value: numericValue!,
                  decimalPlaces: 3,
                  style: AppTypography.bodySmall.copyWith(
                    color: color,
                    fontWeight: AppTypography.bold,
                    fontFamily: AppTypography.numberFontFamily,
                  ),
                )
              : Text(value,
                  style: AppTypography.bodySmall
                      .copyWith(color: color, fontWeight: AppTypography.bold),
                  textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Expense Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ExpenseCard({
    required this.expense,
    required this.isDark,
    required this.onDelete,
    required this.onEdit,
  });

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'rent':
        return LucideIcons.home;
      case 'utilities':
        return LucideIcons.zap;
      case 'salaries':
        return LucideIcons.users;
      case 'supplies':
        return LucideIcons.package;
      case 'marketing':
        return LucideIcons.megaphone;
      case 'maintenance':
        return LucideIcons.wrench;
      case 'transport':
        return LucideIcons.truck;
      default:
        return LucideIcons.moreHorizontal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final warningColor =
        isDark ? AppColors.warningDark : AppColors.warningLight;
    final infoColor = isDark ? AppColors.infoDark : AppColors.infoLight;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Category Icon
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: AppColors.iconContainerGradient(
                    expense.isFixed ? warningColor : infoColor,
                    isDark: isDark,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  _categoryIcon(expense.category),
                  color: expense.isFixed ? warningColor : infoColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expense.category,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: (expense.isFixed
                                    ? warningColor
                                    : infoColor)
                                .withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            expense.isFixed ? 'Fixed' : 'Variable',
                            style: AppTypography.labelSmall.copyWith(
                              color: expense.isFixed
                                  ? warningColor
                                  : infoColor,
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (expense.description != null &&
                        expense.description!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        expense.description!,
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      Formatters.date(expense.date),
                      style: AppTypography.labelSmall.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Amount + actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(expense.amount),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: AppTypography.bold,
                      color: isDark
                          ? AppColors.dangerDark
                          : AppColors.dangerLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 20,
                        color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Expense Form Bottom Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ExpenseFormSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final Expense? expense;
  final double? prefillAmount;
  final String? prefillCategory;
  final String? prefillDescription;

  const _ExpenseFormSheet({
    required this.ref,
    this.expense,
    this.prefillAmount,
    this.prefillCategory,
    this.prefillDescription,
  });

  @override
  ConsumerState<_ExpenseFormSheet> createState() =>
      _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<_ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descriptionCtrl;
  late String _selectedCategory;
  late bool _isFixed;
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _amountCtrl = TextEditingController(
        text: e != null
            ? e.amount.toStringAsFixed(3)
            : (widget.prefillAmount != null
                ? widget.prefillAmount!.toStringAsFixed(3)
                : ''));
    _descriptionCtrl = TextEditingController(
        text: e?.description ?? widget.prefillDescription ?? '');
    // Try to match AI-parsed category to the existing categories list
    final aiCat = widget.prefillCategory?.toLowerCase();
    String resolvedCategory = e?.category ?? ExpenseCategory.all.first;
    if (e == null && aiCat != null) {
      final match = ExpenseCategory.all.where(
        (c) => c.toLowerCase() == aiCat ||
               aiCat.contains(c.toLowerCase()) ||
               c.toLowerCase().contains(aiCat),
      );
      resolvedCategory = match.isNotEmpty ? match.first : ExpenseCategory.other;
    }
    _selectedCategory = resolvedCategory;
    _isFixed = e?.isFixed ?? false;
    _selectedDate = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.expense != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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

              Text(
                isEdit ? 'Edit Expense' : 'Add Expense',
                style: AppTypography.h3,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: ExpenseCategory.all
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Amount
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount (DT)',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: '0.000',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => Validators.positiveNumber(v,
                    fieldName: 'Amount'),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Description
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Date picker row
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(Formatters.date(_selectedDate)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Fixed / Variable toggle
              Row(
                children: [
                  Switch(
                    value: _isFixed,
                    onChanged: (v) => setState(() => _isFixed = v),
                    activeColor: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _isFixed ? 'Fixed Expense' : 'Variable Expense',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              AppButton(
                label: isEdit ? 'Update Expense' : 'Add Expense',
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

      final service = ref.read(expenseServiceProvider);
      final amount = Validators.parseDouble(_amountCtrl.text);

      if (widget.expense != null) {
        await service.updateExpense(
          widget.expense!.id,
          Expense(
            id: widget.expense!.id,
            businessId: businessId,
            category: _selectedCategory,
            amount: amount,
            isFixed: _isFixed,
            description: _descriptionCtrl.text.trim(),
            date: _selectedDate,
            createdAt: widget.expense!.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        await service.createExpense(Expense(
          id: '',
          businessId: businessId,
          category: _selectedCategory,
          amount: amount,
          isFixed: _isFixed,
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          date: _selectedDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      ref.invalidate(expenseListProvider);
      // Expenses affect daily profit and monthly cash flow on the dashboard —
      // invalidate both so they re-fetch immediately after any mutation.
      ref.invalidate(cashFlowReportProvider);
      ref.invalidate(todayDailyProfitProvider);
      if (mounted) {
        Navigator.of(context).pop();
        // Add a small delay to ensure the bottom sheet is fully dismissed
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          AppSnackbar.success(
              context,
              widget.expense != null
                  ? 'Expense updated'
                  : 'Expense added successfully');
        }
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}



