import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Tajer - Business Manager'**
  String get appTitle;

  /// Dashboard navigation label
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Stock/Inventory navigation label
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stock;

  /// Expenses navigation label
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// Debts navigation label
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get debts;

  /// More navigation label
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @lightOrDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Light or dark mode'**
  String get lightOrDarkMode;

  /// No description provided for @businessProfile.
  ///
  /// In en, this message translates to:
  /// **'Business Profile'**
  String get businessProfile;

  /// No description provided for @selectBusiness.
  ///
  /// In en, this message translates to:
  /// **'Select Business'**
  String get selectBusiness;

  /// No description provided for @noBusiness.
  ///
  /// In en, this message translates to:
  /// **'No Business'**
  String get noBusiness;

  /// No description provided for @switchBusiness.
  ///
  /// In en, this message translates to:
  /// **'Switch Business'**
  String get switchBusiness;

  /// No description provided for @selectDifferentBusiness.
  ///
  /// In en, this message translates to:
  /// **'Select a different business to manage'**
  String get selectDifferentBusiness;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @productsAndStock.
  ///
  /// In en, this message translates to:
  /// **'Products & Stock'**
  String get productsAndStock;

  /// No description provided for @reorderSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Reorder Suggestions'**
  String get reorderSuggestions;

  /// No description provided for @productsNeedRestocking.
  ///
  /// In en, this message translates to:
  /// **'Products that need restocking'**
  String get productsNeedRestocking;

  /// No description provided for @auditLog.
  ///
  /// In en, this message translates to:
  /// **'Audit Log'**
  String get auditLog;

  /// No description provided for @viewAllChanges.
  ///
  /// In en, this message translates to:
  /// **'View all changes and activities'**
  String get viewAllChanges;

  /// No description provided for @financial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get financial;

  /// No description provided for @cashRegister.
  ///
  /// In en, this message translates to:
  /// **'Cash Register'**
  String get cashRegister;

  /// No description provided for @dailyCashManagement.
  ///
  /// In en, this message translates to:
  /// **'Daily cash management'**
  String get dailyCashManagement;

  /// No description provided for @reserveFunds.
  ///
  /// In en, this message translates to:
  /// **'Reserve Funds'**
  String get reserveFunds;

  /// No description provided for @manageSavingsFunds.
  ///
  /// In en, this message translates to:
  /// **'Manage savings funds'**
  String get manageSavingsFunds;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @viewFinancialReports.
  ///
  /// In en, this message translates to:
  /// **'View financial reports and analytics'**
  String get viewFinancialReports;

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @manageSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Manage your suppliers'**
  String get manageSuppliers;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @manageEmployees.
  ///
  /// In en, this message translates to:
  /// **'Manage employees and salaries'**
  String get manageEmployees;

  /// No description provided for @wasteAndLoss.
  ///
  /// In en, this message translates to:
  /// **'Waste & Loss'**
  String get wasteAndLoss;

  /// No description provided for @trackProductWaste.
  ///
  /// In en, this message translates to:
  /// **'Track product waste and losses'**
  String get trackProductWaste;

  /// No description provided for @helpAndSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpAndSupport;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @getHelp.
  ///
  /// In en, this message translates to:
  /// **'Get help and support'**
  String get getHelp;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get version;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @activeProducts.
  ///
  /// In en, this message translates to:
  /// **'Active Products'**
  String get activeProducts;

  /// No description provided for @restockAlerts.
  ///
  /// In en, this message translates to:
  /// **'Restock Alerts'**
  String get restockAlerts;

  /// No description provided for @monthlyCashFlow.
  ///
  /// In en, this message translates to:
  /// **'Monthly Cash Flow'**
  String get monthlyCashFlow;

  /// No description provided for @outstandingDebts.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Debts'**
  String get outstandingDebts;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @restockProduct.
  ///
  /// In en, this message translates to:
  /// **'Restock Product'**
  String get restockProduct;

  /// No description provided for @reportsAndStats.
  ///
  /// In en, this message translates to:
  /// **'Reports & Stats'**
  String get reportsAndStats;

  /// No description provided for @cashRegisterOpen.
  ///
  /// In en, this message translates to:
  /// **'Cash Register is OPEN'**
  String get cashRegisterOpen;

  /// No description provided for @cashRegisterClosed.
  ///
  /// In en, this message translates to:
  /// **'Cash Register is CLOSED'**
  String get cashRegisterClosed;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance'**
  String get openingBalance;

  /// No description provided for @openDailyRegister.
  ///
  /// In en, this message translates to:
  /// **'Open the daily register to log transactions'**
  String get openDailyRegister;

  /// No description provided for @businessManagement.
  ///
  /// In en, this message translates to:
  /// **'Business Management'**
  String get businessManagement;

  /// No description provided for @viewEditBusiness.
  ///
  /// In en, this message translates to:
  /// **'View and edit business information'**
  String get viewEditBusiness;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageChangedToArabic.
  ///
  /// In en, this message translates to:
  /// **'Language changed to Arabic'**
  String get languageChangedToArabic;

  /// No description provided for @languageChangedToFrench.
  ///
  /// In en, this message translates to:
  /// **'Language changed to French'**
  String get languageChangedToFrench;

  /// No description provided for @languageChangedToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Language changed to English'**
  String get languageChangedToEnglish;

  /// No description provided for @businessManagerApp.
  ///
  /// In en, this message translates to:
  /// **'Business Manager'**
  String get businessManagerApp;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A comprehensive business management solution for small businesses in Tunisia'**
  String get appDescription;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Notifications coming soon!'**
  String get notificationsComingSoon;

  /// No description provided for @noBusinessYet.
  ///
  /// In en, this message translates to:
  /// **'No Business Yet'**
  String get noBusinessYet;

  /// No description provided for @createFirstBusiness.
  ///
  /// In en, this message translates to:
  /// **'Create your first business to start managing your inventory and finances'**
  String get createFirstBusiness;

  /// No description provided for @createBusiness.
  ///
  /// In en, this message translates to:
  /// **'Create Business'**
  String get createBusiness;

  /// No description provided for @openCashRegister.
  ///
  /// In en, this message translates to:
  /// **'Open Cash Register'**
  String get openCashRegister;

  /// No description provided for @closeCashRegister.
  ///
  /// In en, this message translates to:
  /// **'Close Cash Register'**
  String get closeCashRegister;

  /// No description provided for @enterOpeningBalance.
  ///
  /// In en, this message translates to:
  /// **'Enter the opening balance for today\'s register:'**
  String get enterOpeningBalance;

  /// No description provided for @openingBalanceDT.
  ///
  /// In en, this message translates to:
  /// **'Opening Balance (DT)'**
  String get openingBalanceDT;

  /// No description provided for @openRegister.
  ///
  /// In en, this message translates to:
  /// **'Open Register'**
  String get openRegister;

  /// No description provided for @cashRegisterOpenedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cash register opened successfully'**
  String get cashRegisterOpenedSuccess;

  /// No description provided for @registerAlreadyOpen.
  ///
  /// In en, this message translates to:
  /// **'A cash register is already open for today. Please close it first'**
  String get registerAlreadyOpen;

  /// No description provided for @failedToOpenRegister.
  ///
  /// In en, this message translates to:
  /// **'Failed to open register'**
  String get failedToOpenRegister;

  /// No description provided for @enterActualCash.
  ///
  /// In en, this message translates to:
  /// **'Enter the actual cash counted in the register:'**
  String get enterActualCash;

  /// No description provided for @closingBalanceDT.
  ///
  /// In en, this message translates to:
  /// **'Closing Balance (DT)'**
  String get closingBalanceDT;

  /// No description provided for @closeRegister.
  ///
  /// In en, this message translates to:
  /// **'Close Register'**
  String get closeRegister;

  /// No description provided for @noDiscrepancy.
  ///
  /// In en, this message translates to:
  /// **'No discrepancy'**
  String get noDiscrepancy;

  /// No description provided for @discrepancy.
  ///
  /// In en, this message translates to:
  /// **'Discrepancy'**
  String get discrepancy;

  /// No description provided for @over.
  ///
  /// In en, this message translates to:
  /// **'over'**
  String get over;

  /// No description provided for @short.
  ///
  /// In en, this message translates to:
  /// **'short'**
  String get short;

  /// No description provided for @failedToCloseRegister.
  ///
  /// In en, this message translates to:
  /// **'Failed to close register'**
  String get failedToCloseRegister;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No Results'**
  String get noResults;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found matching'**
  String get noProductsFound;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clearSearch;

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No Products Yet'**
  String get noProductsYet;

  /// No description provided for @addFirstProduct.
  ///
  /// In en, this message translates to:
  /// **'Add your first product to start tracking your inventory'**
  String get addFirstProduct;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Details'**
  String get editDetails;

  /// No description provided for @deleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProduct;

  /// No description provided for @productDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product deleted successfully'**
  String get productDeletedSuccess;

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @unitOfMeasure.
  ///
  /// In en, this message translates to:
  /// **'Unit of Measure'**
  String get unitOfMeasure;

  /// No description provided for @purchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get purchasePrice;

  /// No description provided for @sellingPrice.
  ///
  /// In en, this message translates to:
  /// **'Selling Price'**
  String get sellingPrice;

  /// No description provided for @initialQuantity.
  ///
  /// In en, this message translates to:
  /// **'Initial Quantity'**
  String get initialQuantity;

  /// No description provided for @lowStockLevel.
  ///
  /// In en, this message translates to:
  /// **'Low Stock Level'**
  String get lowStockLevel;

  /// No description provided for @autoReorderQty.
  ///
  /// In en, this message translates to:
  /// **'Auto-Reorder Qty'**
  String get autoReorderQty;

  /// No description provided for @updateDetails.
  ///
  /// In en, this message translates to:
  /// **'Update Details'**
  String get updateDetails;

  /// No description provided for @productDetailsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product details updated'**
  String get productDetailsUpdated;

  /// No description provided for @productAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully'**
  String get productAddedSuccess;

  /// No description provided for @productAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Product Already Exists'**
  String get productAlreadyExists;

  /// No description provided for @restockInstead.
  ///
  /// In en, this message translates to:
  /// **'Restock Instead'**
  String get restockInstead;

  /// No description provided for @quantityToAdd.
  ///
  /// In en, this message translates to:
  /// **'Quantity to Add'**
  String get quantityToAdd;

  /// No description provided for @newPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'New Purchase Price (DT) (optional)'**
  String get newPurchasePrice;

  /// No description provided for @recordRestock.
  ///
  /// In en, this message translates to:
  /// **'Record Restock'**
  String get recordRestock;

  /// No description provided for @stockRestockedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Stock restocked successfully'**
  String get stockRestockedSuccess;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unit;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @profitMargin.
  ///
  /// In en, this message translates to:
  /// **'Profit Margin'**
  String get profitMargin;

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValue;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @customerDebts.
  ///
  /// In en, this message translates to:
  /// **'Customer Debts'**
  String get customerDebts;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @debtsText.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get debtsText;

  /// No description provided for @noDebtsFound.
  ///
  /// In en, this message translates to:
  /// **'No Debts Found'**
  String get noDebtsFound;

  /// No description provided for @trackCustomerPayments.
  ///
  /// In en, this message translates to:
  /// **'Track customer payments and outstanding debts here'**
  String get trackCustomerPayments;

  /// No description provided for @noDebtsForFilter.
  ///
  /// In en, this message translates to:
  /// **'No debts found'**
  String get noDebtsForFilter;

  /// No description provided for @addDebt.
  ///
  /// In en, this message translates to:
  /// **'Add Debt'**
  String get addDebt;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @paidPercentage.
  ///
  /// In en, this message translates to:
  /// **'paid'**
  String get paidPercentage;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'payment'**
  String get payment;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'payments'**
  String get payments;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @addCustomerDebt.
  ///
  /// In en, this message translates to:
  /// **'Add Customer Debt'**
  String get addCustomerDebt;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @totalAmountDT.
  ///
  /// In en, this message translates to:
  /// **'Total Amount (DT)'**
  String get totalAmountDT;

  /// No description provided for @debtRecorded.
  ///
  /// In en, this message translates to:
  /// **'Debt recorded'**
  String get debtRecorded;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @paymentAmountDT.
  ///
  /// In en, this message translates to:
  /// **'Payment Amount (DT)'**
  String get paymentAmountDT;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @paymentRecordedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded successfully'**
  String get paymentRecordedSuccess;

  /// No description provided for @failedToRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to record payment'**
  String get failedToRecordPayment;

  /// No description provided for @deleteDebt.
  ///
  /// In en, this message translates to:
  /// **'Delete Debt'**
  String get deleteDebt;

  /// No description provided for @areYouSureDeleteDebt.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the debt for:'**
  String get areYouSureDeleteDebt;

  /// No description provided for @debtDeleted.
  ///
  /// In en, this message translates to:
  /// **'Debt deleted'**
  String get debtDeleted;

  /// No description provided for @amountCannotExceed.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot exceed remaining balance'**
  String get amountCannotExceed;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @signOutOfAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutOfAccount;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get logoutSuccess;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// No description provided for @salesHistory.
  ///
  /// In en, this message translates to:
  /// **'Sales History'**
  String get salesHistory;

  /// No description provided for @pointOfSale.
  ///
  /// In en, this message translates to:
  /// **'Point of Sale'**
  String get pointOfSale;

  /// No description provided for @recordNewSale.
  ///
  /// In en, this message translates to:
  /// **'Record a new sale or view today\'s orders'**
  String get recordNewSale;

  /// No description provided for @viewAllPastOrders.
  ///
  /// In en, this message translates to:
  /// **'View all past orders and invoices'**
  String get viewAllPastOrders;

  /// No description provided for @viewAllPastSales.
  ///
  /// In en, this message translates to:
  /// **'View all past sales transactions'**
  String get viewAllPastSales;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No Orders Found'**
  String get noOrdersFound;

  /// No description provided for @noOrdersInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No orders found in this period'**
  String get noOrdersInPeriod;

  /// No description provided for @noSalesFound.
  ///
  /// In en, this message translates to:
  /// **'No Sales Found'**
  String get noSalesFound;

  /// No description provided for @noSalesInPeriod.
  ///
  /// In en, this message translates to:
  /// **'No sales found in this period'**
  String get noSalesInPeriod;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date'**
  String get filterByDate;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get last30Days;

  /// No description provided for @menuItems.
  ///
  /// In en, this message translates to:
  /// **'Menu Items'**
  String get menuItems;

  /// No description provided for @manageMenu.
  ///
  /// In en, this message translates to:
  /// **'Manage Menu'**
  String get manageMenu;

  /// No description provided for @manageMenuRecipes.
  ///
  /// In en, this message translates to:
  /// **'Manage your menu and recipes'**
  String get manageMenuRecipes;

  /// No description provided for @noMenuItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No Menu Items Yet'**
  String get noMenuItemsYet;

  /// No description provided for @addMenuItemsToStart.
  ///
  /// In en, this message translates to:
  /// **'Add menu items to start taking orders'**
  String get addMenuItemsToStart;

  /// No description provided for @todaysRevenue.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Revenue'**
  String get todaysRevenue;

  /// No description provided for @todaysOrders.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Orders'**
  String get todaysOrders;

  /// No description provided for @itemsOrdered.
  ///
  /// In en, this message translates to:
  /// **'items ordered'**
  String get itemsOrdered;

  /// No description provided for @itemsSold.
  ///
  /// In en, this message translates to:
  /// **'items sold'**
  String get itemsSold;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @orderInvoice.
  ///
  /// In en, this message translates to:
  /// **'Order Invoice'**
  String get orderInvoice;

  /// No description provided for @voided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get voided;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @orderCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order created successfully'**
  String get orderCreatedSuccess;

  /// No description provided for @failedToCreateOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to create order'**
  String get failedToCreateOrder;

  /// No description provided for @emptyCartMessage.
  ///
  /// In en, this message translates to:
  /// **'Add items to your cart to checkout'**
  String get emptyCartMessage;

  /// No description provided for @cartTotal.
  ///
  /// In en, this message translates to:
  /// **'Cart Total'**
  String get cartTotal;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get items;

  /// No description provided for @item.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get item;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @todaysProfitLoss.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Profit/Loss'**
  String get todaysProfitLoss;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @loss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get loss;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @stockUsage.
  ///
  /// In en, this message translates to:
  /// **'Stock Usage'**
  String get stockUsage;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @arabicLanguageName.
  ///
  /// In en, this message translates to:
  /// **'العربية (Arabic)'**
  String get arabicLanguageName;

  /// No description provided for @frenchLanguageName.
  ///
  /// In en, this message translates to:
  /// **'Français (French)'**
  String get frenchLanguageName;

  /// No description provided for @englishLanguageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguageName;

  /// No description provided for @aiExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Expense Entry'**
  String get aiExpenseTitle;

  /// No description provided for @aiExpenseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe your expense in natural language and let AI parse it for you'**
  String get aiExpenseSubtitle;

  /// No description provided for @aiExpenseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bought tomatoes for 15 dinars'**
  String get aiExpenseHint;

  /// No description provided for @aiParsing.
  ///
  /// In en, this message translates to:
  /// **'Parsing...'**
  String get aiParsing;

  /// No description provided for @aiParseButton.
  ///
  /// In en, this message translates to:
  /// **'Parse with AI'**
  String get aiParseButton;

  /// No description provided for @aiParseResult.
  ///
  /// In en, this message translates to:
  /// **'Parsed Result'**
  String get aiParseResult;

  /// No description provided for @aiConfirmSave.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Save'**
  String get aiConfirmSave;

  /// No description provided for @aiReject.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get aiReject;

  /// No description provided for @aiExpenseSaved.
  ///
  /// In en, this message translates to:
  /// **'AI expense saved successfully'**
  String get aiExpenseSaved;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
