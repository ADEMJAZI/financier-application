# Postman API Testing Guide

## How to Import and Use the Collection

### 1. Import Collection into Postman
1. Open Postman
2. Click **Import** button (top left)
3. Click **Upload Files**
4. Select `Postman_Collection.json` from this folder
5. Click **Import**

### 2. Start Your Backend Server
```bash
cd back
npm start
```
Server should start on http://localhost:3000

### 3. Testing Workflow (Step by Step)

#### STEP 1: Create a Business First
1. Open **Business Management** → **Create Business**
2. The body is already filled with sample data
3. Click **Send**
4. **Expected Response** (201 Created):
```json
{
  "success": true,
  "message": "Business created successfully",
  "data": {
    "_id": "67890abc123def456...",
    "name": "My Store",
    "type": "Retail",
    "location": "123 Main Street, City",
    "description": "A local retail store selling groceries",
    "createdAt": "2026-07-11T...",
    "updatedAt": "2026-07-11T..."
  }
}
```
5. **COPY THE `_id` VALUE** — you'll need it for product operations!

#### STEP 2: Get All Businesses
1. Open **Business Management** → **Get All Businesses**
2. Click **Send**
3. You should see a list of all businesses

#### STEP 3: Get Business by ID
1. Open **Business Management** → **Get Business by ID**
2. Click on **Params** tab
3. Replace `PASTE_BUSINESS_ID_HERE` with the actual `_id` from Step 1
4. Click **Send**

#### STEP 4: Create a Product
1. Open **Product Management** → **Create Product**
2. In the **Body** tab, replace `PASTE_BUSINESS_ID_HERE` with your business `_id`
```json
{
  "business": "67890abc123def456...",  // ← Paste your business ID here
  "name": "Apples",
  "purchasePrice": 0.50,
  "price": 1.20,
  "quantity": 100,
  "unit": "kg"
}
```
3. Click **Send**
4. **Expected Response** (201 Created):
```json
{
  "success": true,
  "message": "Product created successfully",
  "data": {
    "_id": "prod123...",
    "business": "67890abc123def456...",
    "name": "Apples",
    "purchasePrice": 0.5,
    "price": 1.2,
    "quantity": 100,
    "unit": "kg",
    "createdAt": "2026-07-11T...",
    "updatedAt": "2026-07-11T..."
  }
}
```

#### STEP 5: Get Products by Business
1. Open **Product Management** → **Get Products by Business**
2. In **Params** tab, replace `PASTE_BUSINESS_ID_HERE` with your business `_id`
3. Click **Send**
4. You should see all products for that business

#### STEP 6: Update a Product
1. Open **Product Management** → **Update Product**
2. In **Params** tab, replace `PASTE_PRODUCT_ID_HERE` with your product `_id`
3. Modify the fields you want to update in the **Body** tab
4. Click **Send**

#### STEP 7: Delete a Product
1. Open **Product Management** → **Delete Product**
2. In **Params** tab, replace `PASTE_PRODUCT_ID_HERE` with your product `_id`
3. Click **Send**
4. **Expected Response** (200 OK):
```json
{
  "success": true,
  "message": "Product deleted successfully",
  "data": { ... }
}
```

## Common Test Scenarios

### Test 1: Validation - Missing Required Fields
**Request:** POST /api/businesses
```json
{
  "name": "My Store"
  // Missing 'type' and 'location'
}
```
**Expected Response:** 400 Bad Request
```json
{
  "success": false,
  "message": "Required fields: name, type, location"
}
```

### Test 2: Product with Non-existent Business
**Request:** POST /api/products
```json
{
  "business": "000000000000000000000000",
  "name": "Test Product",
  "purchasePrice": 10,
  "price": 20,
  "quantity": 5,
  "unit": "piece"
}
```
**Expected Response:** 404 Not Found
```json
{
  "success": false,
  "message": "Business not found"
}
```

### Test 3: Get Non-existent Resource
**Request:** GET /api/businesses/000000000000000000000000
**Expected Response:** 404 Not Found
```json
{
  "success": false,
  "message": "Business not found"
}
```

### Test 4: Update Product with New Business
**Request:** PUT /api/products/:productId
```json
{
  "business": "NEW_BUSINESS_ID",
  "price": 15.50
}
```
This should validate that the new business exists before updating.

## Quick Reference - All Endpoints

### Business Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/businesses | Create business |
| GET | /api/businesses | Get all businesses |
| GET | /api/businesses/:id | Get business by ID |
| PUT | /api/businesses/:id | Update business |
| DELETE | /api/businesses/:id | Delete business |

### Product Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | /api/products | Create product |
| GET | /api/products/business/:businessId | Get products by business |
| GET | /api/products/:id | Get product by ID |
| PUT | /api/products/:id | Update product |
| DELETE | /api/products/:id | Delete product |

## Tips for Testing
1. **Always create a business first** before creating products
2. **Save IDs** - Copy and save the `_id` values returned from create operations
3. **Check validation** - Try sending requests with missing required fields
4. **Test edge cases** - Try deleting non-existent resources
5. **Monitor server logs** - Check the terminal where your server is running for errors

## Troubleshooting

### Server not responding?
- Make sure your backend server is running (`npm start`)
- Check if MongoDB connection is established (see server logs)
- Verify the URL is `http://localhost:3000`

### Getting "Business not found" when creating products?
- Make sure you copied the correct business `_id`
- Check that the business actually exists (GET /api/businesses)

### Getting validation errors?
- Check the request body has all required fields
- Verify JSON format is correct (no trailing commas)
- Ensure numeric fields (price, quantity) are numbers, not strings
