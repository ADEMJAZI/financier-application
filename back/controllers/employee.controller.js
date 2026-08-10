const Employee = require('../models/Employee');
const Business = require('../models/Business');
const mongoose = require('mongoose');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');

// Create a new employee
exports.createEmployee = async (req, res) => {
  try {
    const { business, name, role, phone, salary, salaryType, startDate } = req.body;

    // Validate required fields
    if (!business || !name || salary === undefined) {
      return res.status(400).json({
        message: 'business, name and salary are required',
      });
    }

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(business)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Validate salary
    if (salary < 0) {
      return res.status(400).json({
        message: 'Salary cannot be negative',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Business not found',
      });
    }

    const employee = new Employee({
      business,
      name: name.trim(),
      role,
      phone,
      salary,
      salaryType,
      startDate: startDate || Date.now(),
      isActive: true,
      payments: [],
    });

    const savedEmployee = await employee.save();

    res.status(201).json({
      success: true,
      message: 'Employee created successfully',
      data: savedEmployee,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Get employees by business ID
exports.getEmployeesByBusiness = async (req, res) => {
  try {
    const { businessId } = req.params;
    const { isActive } = req.query;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(businessId)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Business not found',
      });
    }

    let query = { business: businessId };

    // Add isActive filter if provided
    if (isActive !== undefined) {
      query.isActive = isActive === 'true';
    }

    const employees = await Employee.find(query).populate('business');

    res.status(200).json({
      success: true,
      data: employees,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};
// Update employee by ID
exports.updateEmployee = async (req, res) => {
  try {
    const { id } = req.params;
    const { business, name, role, phone, salary, salaryType, startDate, isActive } = req.body;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    const employee = await Employee.findById(id);

    if (!employee) {
      return res.status(404).json({
        message: 'Employee not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(employee.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Employee not found',
      });
    }

    // If business is being updated, verify it exists
    if (business !== undefined) {
      if (!mongoose.Types.ObjectId.isValid(business)) {
        return res.status(400).json({
          message: 'Invalid ID format',
        });
      }
      
      const isNewOwner = await verifyBusinessOwnership(business, req.user._id);
      if (!isNewOwner) {
        return res.status(404).json({
          message: 'Business not found',
        });
      }
      employee.business = business;
    }

    // Validate salary if provided
    if (salary !== undefined && salary < 0) {
      return res.status(400).json({
        message: 'Salary cannot be negative',
      });
    }

    // Update fields if provided
    if (name !== undefined) employee.name = name.trim();
    if (role !== undefined) employee.role = role;
    if (phone !== undefined) employee.phone = phone;
    if (salary !== undefined) employee.salary = salary;
    if (salaryType !== undefined) employee.salaryType = salaryType;
    if (startDate !== undefined) employee.startDate = startDate;
    if (isActive !== undefined) employee.isActive = isActive;

    const updatedEmployee = await employee.save();

    res.status(200).json({
      success: true,
      message: 'Employee updated successfully',
      data: updatedEmployee,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};
// Delete employee by ID
exports.deleteEmployee = async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Find first — we need the business field to verify ownership
    // before touching the document (find-then-verify-then-delete).
    const employee = await Employee.findById(id);

    if (!employee) {
      return res.status(404).json({
        message: 'Employee not found',
      });
    }

    // Verify business ownership BEFORE deleting
    const isOwner = await verifyBusinessOwnership(employee.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Employee not found',
      });
    }

    await Employee.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: 'Employee deleted successfully',
      data: employee,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Record salary payment
exports.recordSalaryPayment = async (req, res) => {
  try {
    const { id } = req.params;
    const { amount, periodLabel, note } = req.body;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Validate required fields
    if (amount === undefined) {
      return res.status(400).json({
        message: 'amount is required',
      });
    }

    // Validate amount
    if (amount <= 0) {
      return res.status(400).json({
        message: 'Amount must be greater than 0',
      });
    }

    const employee = await Employee.findById(id);

    if (!employee) {
      return res.status(404).json({
        message: 'Employee not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(employee.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Employee not found',
      });
    }

    // Add payment
    employee.payments.push({
      amount,
      periodLabel,
      note,
      date: new Date(),
    });

    const updatedEmployee = await employee.save();

    res.status(200).json({
      success: true,
      message: 'Salary payment recorded successfully',
      data: updatedEmployee,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};
// Deactivate employee
exports.deactivateEmployee = async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    const employee = await Employee.findById(id);

    if (!employee) {
      return res.status(404).json({
        message: 'Employee not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(employee.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Employee not found',
      });
    }

    employee.isActive = false;
    const updatedEmployee = await employee.save();

    res.status(200).json({
      success: true,
      message: 'Employee deactivated successfully',
      data: updatedEmployee,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};