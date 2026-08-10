# API Testing Guide - Postman

## Quick Start

### 1. Import the Collection
1. Open Postman
2. Click **Import** (top-left)
3. Select **Upload Files**
4. Choose `Postman_Collection.json` from this folder
5. Click **Import**

---

## Step-by-Step Testing Guide

### Step 1: Create a Business

**Request Details:**
- **Method:** POST
- **URL:** `http://localhost:3000/api/businesses`
- **Headers:** `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "name": "My Store",
  "type": "Retail",
  "location": "123 Main Street, City",
  "description": "A local retail store selling groceries"
}
```

**Expected Response (201 Created):**
```json
{
  "success": true,
  "message": "Business created successfully",
  "data": {
    "_id": "67a1b2c3d4e5f6g7h8i9j0k1",
    "name": "My Store",
    "type": "Retail",
    "location": "123 Main Street, City",
    "description": "A local retail store selling groceries",
    "createdAt": "2024-07-11T10:30:00.000Z",
    "updatedAt": "2024-07-11T10:30:00.000Z",
    "__v": 0
  }
}
```

**⚠️ Important:** Copy the `_id` value (business ID) from the response - you'll need it for other requests!

---

### Step 2: Get All Businesses

**Request Details:**
- **Method:** GET
- **URL:** `http://localhost:3000/api/businesses`
- **Headers:** None needed

**Expected Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "67a1b2c3d4e5f6g7h8i9j0k1",
      "name": "My Store",
      "type": "Retail",
      "location": "123 Main Street, City",
      "description": "A local retail store selling groceries",
      "createdAt": "2024-07-11T10:30:00.000Z",
      "updatedAt": "2024-07-11T10:30:00.000Z",
      "__v": 0
    }
  ]
}
```

---

### Step 3: Get Business by ID

**Request Details:**
- **Method:** GET
- **URL:** `http://localhost:3000/api/businesses/YOUR_BUSINESS_ID`
- **Replace:** `YOUR_BUSINESS_ID` with the ID from Step 1

**Example:**
```
http://localhost:3000/api/businesses/67a1b2c3d4e5f6g7h8i9j0k1
```

**Expected Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "_id": "67a1b2c3d4e5f6g7h8i9j0k1",
    "name": "My Store",
    "type": "Retail",
    "location": "123 Main Street, City",
    "description": "A local retail store selling groceries",
    "createdAt": "2024-07-11T10:30:00.000Z",
    "updatedAt": "2024-07-11T10:30:00.000Z",
    "__v": 0
  }
}
```

---

### Step 4: Update Business

**Request Details:**
- **Method:** PUT
- **URL:** `http://localhost:3000/api/businesses/YOUR_BUSINESS_ID`
- **Headers:** `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "name": "Updated Store Name",
  "type": "Wholesale",
  "location": "456 Oak Avenue, City",
  "description": "Updated description"
}
```

**Expected Response (200 OK):**
```json
{
  "success": true,
  "message": "Business updated successfully",
  "data": {
    "_id": "67a1b2c3d4e5f6g7h8i9j0k1",
    "name": "Updated Store Name",
    "type": "Wholesale",
    "location": "456 Oak Avenue, City",
    "description": "Updated description",
    "createdAt": "2024-07-11T10:30:00.000Z",
    "updatedAt": "2024-07-11T10:35:00.000Z",
    "__v": 0
  }
}
```

---

### Step 5: Create a Product

**Request Details:**
- **Method:** POST
- **URL:** `http://localhost:3000/api/products`
- **Headers:** `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "business": "YOUR_BUSINESS_ID",
  "name": "Apples",
  "purchasePrice": 0.50,
  "price": 1.20,
  "quantity": 100,
  "unit": "kg"
}
```

**Replace:** `YOUR_BUSINESS_ID` with the ID from Step 1

**Expected Response (201 Created):**
```json
{
  "success": true,
  "message": "Product created successfully",
  "data": {
    "_id": "67a1b2c3d4e5f6g7h8i9j0k2",
    "business": "67a1b2c3d4e5f6g7h8i9j0k1",
    "name": "Apples",
    "purchasePrice": 0.50,
    "price": 1.20,
    "quantity": 100,
    "unit": "kg",
    "createdAt": "2024-07-11T10:40:00.000Z",
    "updatedAt": "2024-07-11T10:40:00.000Z",
    "__v": 0
  }
}
```

**⚠️ Important:** Copy the product `_id` - you'll need it for product-specific operations!

---

### Step 6: Get Products by Business

**Request Details:**
- **Method:** GET
- **URL:** `http://localhost:3000/api/products/business/YOUR_BUSINESS_ID`
- **Replace:** `YOUR_BUSINESS_ID` with the business ID

**Example:**
```
http://localhost:3000/api/products/business/67a1b2c3d4e5f6g7h8i9j0k1
```

**Expected Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "_id": "67a1b2c3d4e5f6g7h8i9j0k2",
      "business": "67a1b2c3d4e5f6g7h8i9j0k1",
      "name": "Apples",
      "purchasePrice": 0.50,
      "price": 1.20,
      "quantity": 100,
      "unit": "kg",
      "createdAt": "2024-07-11T10:40:00.000Z",
      "updatedAt": "2024-07-11T10:40:00.000Z",
      "__v": 0
    }
  ]
}
```

---

### Step 7: Get Product by ID

**Request Details:**
- **Method:** GET
- **URL:** `http://localhost:3000/api/products/YOUR_PRODUCT_ID`
- **Replace:** `YOUR_PRODUCT_ID` with the product ID from Step 5

**Example:**
```
http://localhost:3000/api/products/67a1b2c3d4e5f6g7h8i9j0k2
```

**Expected Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "_id": "67a1b2c3d4e5f6g7h8i9j0k2",
    "business": {
      "_id": "67a1b2c3d4e5f6g7h8i9j0k1",
      "name": "My Store",
      "type": "Retail",
      "location": "123 Main Street, City",
      "description": "A local retail store selling groceries",
      "createdAt": "2024-07-11T10:30:00.000Z",
      "updatedAt": "2024-07-11T10:30:00.000Z",
      "__v": 0
    },
    "name": "Apples",
    "purchasePrice": 0.50,
    "price": 1.20,
    "quantity": 100,
    "unit": "kg",
    "createdAt": "2024-07-11T10:40:00.000Z",
    "updatedAt": "2024-07-11T10:40:00.000Z",
    "__v": 0
  }
}
```

---

### Step 8: Update Product

**Request Details:**
- **Method:** PUT
- **URL:** `http://localhost:3000/api/products/YOUR_PRODUCT_ID`
- **Headers:** `Content-Type: application/json`
- **Body (raw JSON):**
```json
{
  "name": "Red Apples",
  "purchasePrice": 0.55,
  "price": 1.30,
  "quantity": 150,
  "unit": "kg"
}
```

**Expected Response (200 OK):**
```json
{
  "success": true,
  "message": "Product updated successfully",
  "data": {
    "_id": "67a1b2c3d4e5f6g7h8i9j0k2",
    "business": "67a1b2c3d4e5f6g7h8i9j0k1",
    "name": "Red Apples",
    "purchasePrice": 0.55,
    "price": 1.30,
    "quantity": 150,
    "unit": "kg",
    "createdAt": "2024-07-11T10:40:00.000Z",
    "updatedAt": "2024-07-11T10:45:00.000Z",
    "__v": 0
  }
}
```

---

### Step 9: Delete Product

**Request Details:**
- **Method:** DELETE
- **URL:** `http://localhost:3000/api/products/YOUR_PRODUCT_ID`

**Expected Response (200 OK):**
```json
{
  "success": true,
  "message": "Product deleted successfully",
  "data": {
    "_id": "67a1b2c3d4e5f6g7h8i9j0k2",
    "business": "67a1b2c3d4e5f6g7h8i9j0k1",
    "name": "Red Apples",
    "purchasePrice": 0.55,
    "price": 1.30,
    "quantity": 150,
    "unit": "kg",
    "createdAt": "2024-07-11T10:40:00.000Z",
    "updatedAt": "2024-07-11T10:45:00.000Z",
    "__v": 0
  }
}
```

---

### Step 10: Delete Business

**Request Details:**
- **Method:** DELETE
- **URL:** `http://localhost:3000/api/businesses/YOUR_BUSINESS_ID`

**Expected Response (200 OK):**
```json
{
  "success": true,
  "message": "Business deleted successfully",
  "data": {
    "_id": "67a1b2c3d4e5f6g7h8i9j0k1",
    "name": "Updated Store Name",
    "type": "Wholesale",
    "location": "456 Oak Avenue, City",
    "description": "Updated description",
    "createdAt": "2024-07-11T10:30:00.000Z",
    "updatedAt": "2024-07-11T10:35:00.000Z",
    "__v": 0
  }
}
```

---

## Error Responses

### 400 Bad Request - Missing Fields
```json
{
  "success": false,
  "message": "Required fields: name, type, location"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "Business not found"
}
```

### 500 Server Error
```json
{
  "success": false,
  "message": "Error message details here"
}
```

---

## Testing Tips

1. **Always start with Create Business** - You need a business ID before creating products
2. **Copy IDs carefully** - Use Ctrl+C to copy MongoDB IDs from responses
3. **Test in this order:**
   - Create Business → Get Business → Update Business
   - Create Product → Get Product → Update Product → Delete Product
   - Delete Business
4. **Use Postman's Environments** - Create variables for `baseUrl`, `businessId`, and `productId` to make requests reusable
5. **Check request headers** - Make sure `Content-Type: application/json` is set for POST/PUT requests

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Connection refused | Make sure your backend server is running with `npm start` |
| 404 Not Found | Verify the ID exists - paste it correctly from previous response |
| 400 Bad Request | Check all required fields are included in the body |
| CORS errors | Verify the frontend origin in server settings matches your client |

---

## Quick Reference Table

| Operation | Method | URL | Body? |
|-----------|--------|-----|-------|
| Create Business | POST | `/api/businesses` | ✅ Yes |
| List Businesses | GET | `/api/businesses` | ❌ No |
| Get Business | GET | `/api/businesses/:id` | ❌ No |
| Update Business | PUT | `/api/businesses/:id` | ✅ Yes |
| Delete Business | DELETE | `/api/businesses/:id` | ❌ No |
| Create Product | POST | `/api/products` | ✅ Yes |
| List Products by Business | GET | `/api/products/business/:businessId` | ❌ No |
| Get Product | GET | `/api/products/:id` | ❌ No |
| Update Product | PUT | `/api/products/:id` | ✅ Yes |
| Delete Product | DELETE | `/api/products/:id` | ❌ No |
