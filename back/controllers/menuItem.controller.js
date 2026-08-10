const MenuItem = require('../models/MenuItem');
const MenuItemSale = require('../models/MenuItemSale');
const Product = require('../models/Product');
const Business = require('../models/Business');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');
const mongoose = require('mongoose');

/**
 * Validate a recipe array.
 * Returns { valid: true } on success, or { valid: false, message } on failure.
 * Each rawMaterial must be a valid ObjectId that references a Product
 * belonging to the given business. quantityRequired must be > 0.
 */
async function validateRecipe(recipe, businessId) {
  if (!Array.isArray(recipe)) {
    return { valid: false, message: 'recipe must be an array' };
  }

  for (const entry of recipe) {
    const { rawMaterial, quantityRequired } = entry;

    // Validate rawMaterial ObjectId format
    if (!rawMaterial || !mongoose.Types.ObjectId.isValid(rawMaterial)) {
      return {
        valid: false,
        message: `Invalid rawMaterial ID format: ${rawMaterial}`,
      };
    }

    // Validate quantityRequired
    if (quantityRequired === undefined || quantityRequired === null) {
      return {
        valid: false,
        message: `quantityRequired is required for rawMaterial ${rawMaterial}`,
      };
    }
    if (typeof quantityRequired !== 'number' || quantityRequired <= 0) {
      return {
        valid: false,
        message: `quantityRequired must be a number greater than 0 for rawMaterial ${rawMaterial}`,
      };
    }

    // Verify the Product exists and belongs to the same business
    const product = await Product.findOne({ _id: rawMaterial, business: businessId });
    if (!product) {
      return {
        valid: false,
        message: `Raw material with ID ${rawMaterial} not found or does not belong to this business`,
      };
    }
  }

  return { valid: true };
}

// Create a new menu item
exports.createMenuItem = async (req, res) => {
  try {
    const { business, name, sellingPrice, recipe } = req.body;

    // Validate required fields
    if (!business || !name || sellingPrice === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Required fields: business, name, sellingPrice',
      });
    }

    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(business)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid business ID format',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    // Check for duplicate menu item (case-insensitive, trimmed)
    const existingMenuItem = await MenuItem.findOne({
      business,
      name: { $regex: new RegExp(`^${name.trim()}$`, 'i') },
    });

    if (existingMenuItem) {
      return res.status(409).json({
        success: false,
        message: 'This menu item already exists. Please update the existing item instead.',
        existingMenuItem,
      });
    }

    // Validate recipe if provided
    let validatedRecipe = [];
    if (recipe !== undefined && recipe !== null) {
      const recipeValidation = await validateRecipe(recipe, business);
      if (!recipeValidation.valid) {
        return res.status(400).json({
          success: false,
          message: recipeValidation.message,
        });
      }
      validatedRecipe = recipe;
    }

    const menuItem = new MenuItem({
      business,
      name: name.trim(),
      sellingPrice,
      recipe: validatedRecipe,
    });

    const savedMenuItem = await menuItem.save();

    // Populate recipe.rawMaterial for response
    const populatedMenuItem = await MenuItem.findById(savedMenuItem._id).populate(
      'recipe.rawMaterial',
      'name unit quantity'
    );

    res.status(201).json({
      success: true,
      message: 'Menu item created successfully',
      data: populatedMenuItem,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Get menu items by business ID
exports.getMenuItemsByBusiness = async (req, res) => {
  try {
    const { businessId } = req.params;
    const { isActive } = req.query;

    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(businessId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid business ID format',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    // Build query filter
    const filter = { business: businessId };
    if (isActive !== undefined) {
      filter.isActive = isActive === 'true';
    }

    const menuItems = await MenuItem.find(filter)
      .populate('recipe.rawMaterial', 'name unit quantity')
      .sort({ name: 1 });

    res.status(200).json({
      success: true,
      data: menuItems,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Get a single menu item by ID
exports.getMenuItemById = async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid menu item ID format',
      });
    }

    const menuItem = await MenuItem.findById(id).populate(
      'recipe.rawMaterial',
      'name unit quantity'
    );

    if (!menuItem) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(menuItem.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    res.status(200).json({
      success: true,
      data: menuItem,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Update menu item by ID
exports.updateMenuItem = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, sellingPrice, isActive, recipe } = req.body;

    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid menu item ID format',
      });
    }

    const menuItem = await MenuItem.findById(id);

    if (!menuItem) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    // Verify business ownership via the item's business field
    const isOwner = await verifyBusinessOwnership(menuItem.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    // Update fields if provided
    if (name !== undefined) {
      menuItem.name = name.trim();
    }
    if (sellingPrice !== undefined) {
      menuItem.sellingPrice = sellingPrice;
    }
    if (isActive !== undefined) {
      menuItem.isActive = isActive;
    }

    // Full-replace recipe if provided (send complete desired array)
    if (recipe !== undefined) {
      const recipeValidation = await validateRecipe(recipe, menuItem.business.toString());
      if (!recipeValidation.valid) {
        return res.status(400).json({
          success: false,
          message: recipeValidation.message,
        });
      }
      menuItem.recipe = recipe;
    }

    const updatedMenuItem = await menuItem.save();

    // Populate recipe.rawMaterial for response
    const populatedMenuItem = await MenuItem.findById(updatedMenuItem._id).populate(
      'recipe.rawMaterial',
      'name unit quantity'
    );

    res.status(200).json({
      success: true,
      message: 'Menu item updated successfully',
      data: populatedMenuItem,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Deactivate menu item (soft delete)
exports.deactivateMenuItem = async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid menu item ID format',
      });
    }

    const menuItem = await MenuItem.findById(id);

    if (!menuItem) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(menuItem.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    menuItem.isActive = false;
    const deactivatedMenuItem = await menuItem.save();

    res.status(200).json({
      success: true,
      message: 'Menu item deactivated successfully',
      data: deactivatedMenuItem,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Delete menu item (hard delete, only if no sales)
exports.deleteMenuItem = async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid menu item ID format',
      });
    }

    const menuItem = await MenuItem.findById(id);

    if (!menuItem) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(menuItem.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    // Check if there are any sales for this menu item
    const salesCount = await MenuItemSale.countDocuments({ menuItem: id });

    if (salesCount > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete a menu item with recorded sales, deactivate it instead',
      });
    }

    // Store full document for response
    const deletedMenuItem = menuItem.toObject();

    await MenuItem.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: 'Menu item deleted successfully',
      data: deletedMenuItem,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
