const CustomerDebt = require('../models/CustomerDebt');
const Reserve = require('../models/Reserve');
const Expense = require('../models/Expense');
const SupplierPurchase = require('../models/SupplierPurchase');
const Employee = require('../models/Employee');
const Waste = require('../models/Waste');
const Business = require('../models/Business');
const mongoose = require('mongoose');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');

// Get cash flow report
exports.getCashFlowReport = async (req, res) => {
  try {
    const { businessId } = req.params;
    const { from, to, groupBy = 'month' } = req.query;

    // Validate required fields
    if (!from || !to) {
      return res.status(400).json({
        message: 'from and to dates are required',
      });
    }

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(businessId)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Validate dates
    const fromDate = new Date(from);
    const toDate = new Date(to);
    
    if (isNaN(fromDate.getTime()) || isNaN(toDate.getTime())) {
      return res.status(400).json({
        message: 'Invalid date format',
      });
    }

    if (fromDate > toDate) {
      return res.status(400).json({
        message: 'From date must be less than or equal to to date',
      });
    }

    // Validate groupBy
    if (!['day', 'week', 'month'].includes(groupBy)) {
      return res.status(400).json({
        message: 'groupBy must be one of: day, week, month',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Business not found',
      });
    }

    const businessObjectId = new mongoose.Types.ObjectId(businessId);

    // Date grouping format based on groupBy
    let dateFormat;
    switch (groupBy) {
      case 'day':
        dateFormat = '%Y-%m-%d';
        break;
      case 'week':
        dateFormat = '%Y-W%U';
        break;
      case 'month':
      default:
        dateFormat = '%Y-%m';
        break;
    }

    // CASH IN: Customer debt payments
    const debtPayments = await CustomerDebt.aggregate([
      { $match: { business: businessObjectId } },
      { $unwind: '$payments' },
      {
        $match: {
          'payments.date': { $gte: fromDate, $lte: toDate },
        },
      },
      {
        $group: {
          _id: { $dateToString: { format: dateFormat, date: '$payments.date' } },
          amount: { $sum: '$payments.amount' },
        },
      },
    ]);

    // CASH OUT: Reserve deposits (money going into reserves)
    const reserveDeposits = await Reserve.aggregate([
      { $match: { business: businessObjectId } },
      { $unwind: '$transactions' },
      {
        $match: {
          'transactions.type': 'deposit',
          'transactions.date': { $gte: fromDate, $lte: toDate },
        },
      },
      {
        $group: {
          _id: { $dateToString: { format: dateFormat, date: '$transactions.date' } },
          amount: { $sum: '$transactions.amount' },
        },
      },
    ]);

    // CASH OUT: Expenses
    const expenses = await Expense.aggregate([
      {
        $match: {
          business: businessObjectId,
          date: { $gte: fromDate, $lte: toDate },
        },
      },
      {
        $group: {
          _id: { $dateToString: { format: dateFormat, date: '$date' } },
          amount: { $sum: '$amount' },
        },
      },
    ]);

    // CASH OUT: Supplier purchases
    const supplierPurchases = await SupplierPurchase.aggregate([
      {
        $match: {
          business: businessObjectId,
          date: { $gte: fromDate, $lte: toDate },
        },
      },
      {
        $group: {
          _id: { $dateToString: { format: dateFormat, date: '$date' } },
          amount: { $sum: '$totalCost' },
        },
      },
    ]);

    // CASH OUT: Employee salary payments
    const employeePayments = await Employee.aggregate([
      { $match: { business: businessObjectId } },
      { $unwind: '$payments' },
      {
        $match: {
          'payments.date': { $gte: fromDate, $lte: toDate },
        },
      },
      {
        $group: {
          _id: { $dateToString: { format: dateFormat, date: '$payments.date' } },
          amount: { $sum: '$payments.amount' },
        },
      },
    ]);

    // INFORMATIONAL: Waste losses (non-cash)
    const wasteLosses = await Waste.aggregate([
      {
        $match: {
          business: businessObjectId,
          date: { $gte: fromDate, $lte: toDate },
        },
      },
      {
        $group: {
          _id: { $dateToString: { format: dateFormat, date: '$date' } },
          amount: { $sum: '$estimatedLoss' },
        },
      },
    ]);

    // Combine all periods
    const allPeriods = new Set();
    [...debtPayments, ...reserveDeposits, ...expenses, ...supplierPurchases, ...employeePayments, ...wasteLosses].forEach(
      item => allPeriods.add(item._id)
    );

    // Create maps for easy lookup
    const debtPaymentsMap = new Map(debtPayments.map(item => [item._id, item.amount]));
    const reserveDepositsMap = new Map(reserveDeposits.map(item => [item._id, item.amount]));
    const expensesMap = new Map(expenses.map(item => [item._id, item.amount]));
    const supplierPurchasesMap = new Map(supplierPurchases.map(item => [item._id, item.amount]));
    const employeePaymentsMap = new Map(employeePayments.map(item => [item._id, item.amount]));
    const wasteLossesMap = new Map(wasteLosses.map(item => [item._id, item.amount]));

    // Build breakdown
    const breakdown = Array.from(allPeriods).map(period => {
      const cashIn = debtPaymentsMap.get(period) || 0;
      const cashOut = 
        (reserveDepositsMap.get(period) || 0) +
        (expensesMap.get(period) || 0) +
        (supplierPurchasesMap.get(period) || 0) +
        (employeePaymentsMap.get(period) || 0);
      
      return {
        period,
        cashIn,
        cashOut,
        net: cashIn - cashOut,
        nonCashLoss: wasteLossesMap.get(period) || 0,
      };
    }).sort((a, b) => a.period.localeCompare(b.period));

    // Calculate totals
    const totalCashIn = breakdown.reduce((sum, item) => sum + item.cashIn, 0);
    const totalCashOut = breakdown.reduce((sum, item) => sum + item.cashOut, 0);
    const totalNonCashLosses = breakdown.reduce((sum, item) => sum + item.nonCashLoss, 0);

    res.status(200).json({
      success: true,
      data: {
        period: { from, to, groupBy },
        summary: {
          totalCashIn,
          totalCashOut,
          netCashFlow: totalCashIn - totalCashOut,
          nonCashLosses: totalNonCashLosses,
        },
        breakdown,
      },
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};