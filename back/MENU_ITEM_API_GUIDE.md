# MenuItem API Documentation

This guide covers the complete MenuItem and MenuItemSale API endpoints for manufacturing businesses (e.g., restaurants).

## Overview

The MenuItem resource supports businesses with `businessType = 'manufacturing'` that sell prepared items without tracking raw material consumption per sale.

---

## Authentication

All endpoints require a Bearer token in the Authorization header:
```
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## MenuItem Endpoints

### 1. Create Menu Item
**POST** `/api/menu-items`

Creates a new menu item for a business.

**Request Body:**
```json
{
  "business": "business_id_here",
  "name": "Cheese Sandwich",
  "sellingPrice": 8.50
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Menu item created successfully",
  "data": {
    "_id": "menu_item_id",
    "business": "business_id",
    "name": "Cheese Sandwich",
    "sellingPrice": 8.50,
    "isActive": true,
    "createdAt": "2024-01-15T10:00:00.000Z",
    "updatedAt": "2024-01-15T10:00:00.000Z"
  }
}
```

**Error Responses:**
- `400`: Missing required fields (business, name, sellingPrice)
- `404`: Business not found or you don't have access
- `409`: Menu item with this name already exists

---

### 2. Get Menu Items by Business
**GET** `/api/menu-items/business/:businessId`

Gets all menu items for a specific business.

**Query Parameters:**
- `isActive` (optional): Filter by active status (`true` or `false`)

**Example:** `/api/menu-items/business/67890?isActive=true`

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "menu_item_id_1",
      "business": "business_id",
      "name": "Cheese Sandwich",
      "sellingPrice": 8.50,
      "isActive": true,
      "createdAt": "2024-01-15T10:00:00.000Z"
    },
    {
      "_id": "menu_item_id_2",
      "business": "business_id",
      "name": "Coffee",
      "sellingPrice": 3.50,
      "isActive": true,
      "createdAt": "2024-01-15T11:00:00.000Z"
    }
  ]
}
```

---

### 3. Update Menu Item
**PUT** `/api/menu-items/:id`

Updates a menu item's details.

**Request Body (all fields optional):**
```json
{
  "name": "Premium Cheese Sandwich",
  "sellingPrice": 10.00,
  "isActive": true
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Menu item updated successfully",
  "data": {
    "_id": "menu_item_id",
    "business": "business_id",
    "name": "Premium Cheese Sandwich",
    "sellingPrice": 10.00,
    "isActive": true,
    "updatedAt": "2024-01-15T12:00:00.000Z"
  }
}
```

---

### 4. Deactivate Menu Item (Soft Delete)
**PATCH** `/api/menu-items/:id/deactivate`

Sets `isActive` to `false` without deleting the item. Use this for items with recorded sales.

**Response (200):**
```json
{
  "success": true,
  "message": "Menu item deactivated successfully",
  "data": {
    "_id": "menu_item_id",
    "name": "Cheese Sandwich",
    "isActive": false
  }
}
```

---

### 5. Delete Menu Item (Hard Delete)
**DELETE** `/api/menu-items/:id`

Permanently deletes a menu item. Only allowed if no sales are recorded for this item.

**Response (200):**
```json
{
  "success": true,
  "message": "Menu item deleted successfully",
  "data": {
    "_id": "menu_item_id",
    "name": "Cheese Sandwich"
  }
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "Cannot delete a menu item with recorded sales, deactivate it instead"
}
```

---

## MenuItemSale Endpoints

### 1. Record Sale
**POST** `/api/menu-item-sales`

Records a sale of a menu item. The selling price is automatically snapshotted.

**Request Body:**
```json
{
  "business": "business_id_here",
  "menuItem": "menu_item_id_here",
  "quantity": 2
}
```

**Note:** `quantity` is optional and defaults to 1.

**Response (201):**
```json
{
  "success": true,
  "message": "Sale recorded successfully",
  "data": {
    "_id": "sale_id",
    "business": "business_id",
    "menuItem": {
      "_id": "menu_item_id",
      "name": "Cheese Sandwich",
      "sellingPrice": 8.50
    },
    "quantity": 2,
    "unitPrice": 8.50,
    "totalAmount": 17.00,
    "date": "2024-01-15T14:30:00.000Z"
  }
}
```

---

### 2. Get Sales by Business
**GET** `/api/menu-item-sales/business/:businessId`

Gets all sales for a business with optional date filtering.

**Query Parameters:**
- `from` (optional): Start date (ISO format)
- `to` (optional): End date (ISO format)

**Example:** `/api/menu-item-sales/business/67890?from=2024-01-01&to=2024-01-31`

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "sale_id_1",
      "business": "business_id",
      "menuItem": {
        "_id": "menu_item_id",
        "name": "Cheese Sandwich"
      },
      "quantity": 2,
      "unitPrice": 8.50,
      "totalAmount": 17.00,
      "date": "2024-01-15T14:30:00.000Z"
    }
  ]
}
```

---

### 3. Get Daily Summary
**GET** `/api/menu-item-sales/business/:businessId/daily-summary`

Gets aggregated sales data for a specific day.

**Query Parameters:**
- `date` (optional): Target date (ISO format). Defaults to today.

**Example:** `/api/menu-item-sales/business/67890/daily-summary?date=2024-01-15`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "date": "2024-01-15T00:00:00.000Z",
    "totalRevenue": 145.50,
    "saleCount": 23,
    "byMenuItem": [
      {
        "name": "Cheese Sandwich",
        "quantitySold": 12,
        "revenue": 102.00
      },
      {
        "name": "Coffee",
        "quantitySold": 11,
        "revenue": 38.50
      }
    ]
  }
}
```

---

### 4. Get Daily Profit Report
**GET** `/api/menu-item-sales/business/:businessId/daily-profit`

Combines daily revenue from menu item sales with daily expenses to calculate net profit.

**Query Parameters:**
- `date` (optional): Target date (ISO format). Defaults to today.

**Example:** `/api/menu-item-sales/business/67890/daily-profit?date=2024-01-15`

**Response (200):**
```json
{
  "success": true,
  "data": {
    "date": "2024-01-15T00:00:00.000Z",
    "totalRevenue": 145.50,
    "totalExpenses": 45.00,
    "netProfit": 100.50
  }
}
```

---

### 5. Delete Sale (Undo)
**DELETE** `/api/menu-item-sales/:id`

Deletes a sale record. No stock restoration is performed.

**Response (200):**
```json
{
  "success": true,
  "message": "Sale deleted successfully",
  "data": {
    "_id": "sale_id",
    "menuItem": "menu_item_id",
    "quantity": 2,
    "totalAmount": 17.00
  }
}
```

---

## Complete Testing Flow

### Step 1: Login and Get Token
```
POST /api/auth/login
{
  "email": "user@example.com",
  "password": "password123"
}
```
Save the token from the response.

### Step 2: Create or Get Business ID
Use an existing manufacturing business or create one with `businessType: "manufacturing"`.

### Step 3: Create Menu Items
```
POST /api/menu-items
{
  "business": "YOUR_BUSINESS_ID",
  "name": "Cheese Sandwich",
  "sellingPrice": 8.50
}
```

### Step 4: Record Sales
```
POST /api/menu-item-sales
{
  "business": "YOUR_BUSINESS_ID",
  "menuItem": "YOUR_MENU_ITEM_ID",
  "quantity": 2
}
```

### Step 5: View Reports
```
GET /api/menu-item-sales/business/YOUR_BUSINESS_ID/daily-summary
GET /api/menu-item-sales/business/YOUR_BUSINESS_ID/daily-profit
```

---

## Error Handling

All endpoints follow consistent error response patterns:

**400 Bad Request:**
```json
{
  "success": false,
  "message": "Validation error message"
}
```

**404 Not Found:**
```json
{
  "success": false,
  "message": "Business not found or you do not have access"
}
```

**409 Conflict:**
```json
{
  "success": false,
  "message": "Duplicate resource message"
}
```

**500 Internal Server Error:**
```json
{
  "success": false,
  "message": "Error details"
}
```

---

## Business Logic Notes

1. **Ownership Verification**: All operations verify that the authenticated user owns the business
2. **Price Snapshotting**: Sales record the `unitPrice` at the time of sale, not a reference
3. **Soft Delete**: Deactivate items with sales history instead of deleting
4. **Hard Delete**: Only allowed for items with zero recorded sales
5. **No Stock Tracking**: Menu items don't interact with Product inventory
6. **Duplicate Prevention**: Case-insensitive name checking within the same business

---

## Implementation Complete ✅

All files created:
- ✅ `models/MenuItem.js`
- ✅ `models/MenuItemSale.js`
- ✅ `controllers/menuItem.controller.js`
- ✅ `controllers/menuItemSale.controller.js`
- ✅ `routes/menuItem.routes.js`
- ✅ `routes/menuItemSale.routes.js`
- ✅ Routes mounted in `index.js`

Server is running at: **http://localhost:3000**
