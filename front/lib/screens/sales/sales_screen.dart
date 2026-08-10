import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/business.dart';
import '../../providers/business_provider.dart';
import '../../providers/active_business_provider.dart';
import '../../theme/app_spacing.dart';
import 'resale_sales_view.dart';
import 'manufacturing_sales_view.dart';

/// Sales screen that branches by business type
class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBusiness = ref.watch(activeBusinessProvider);

    if (activeBusiness == null) {
      return Scaffold(
        key: const ValueKey('sales-no-business'),
        appBar: AppBar(title: const Text('Sales')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text('No active business selected'),
          ),
        ),
      );
    }

    // Branch by business type — each view returns its own Scaffold
    switch (activeBusiness.businessType) {
      case BusinessType.resale:
        return ResaleSalesView(key: ValueKey('sales-resale-${activeBusiness.id}'), business: activeBusiness);
      case BusinessType.manufacturing:
        return ManufacturingSalesView(key: ValueKey('sales-manufacturing-${activeBusiness.id}'), business: activeBusiness);
    }
  }
}
