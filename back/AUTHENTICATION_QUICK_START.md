# 🚀 Authentication Quick Start Guide

## ✅ What's Been Done:

1. ✅ JWT authentication system implemented
2. ✅ All routes protected with JWT middleware
3. ✅ Multi-tenant architecture (businesses belong to users)
4. ✅ User registration & login endpoints
5. ✅ Environment variables configured

---

## 🔧 **How to Use:**

### **Step 1: Start the Server**
```bash
npm start
```

The server should start on http://localhost:3000

---

### **Step 2: Register a New User**

**Endpoint:** `POST /api/auth/register`

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "123abc...",
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

**Save the token!** You'll need it for all other requests.

---

### **Step 3: Login (if already registered)**

**Endpoint:** `POST /api/auth/login`

```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:** Same as registration (includes token)

---

### **Step 4: Use Protected Endpoints**

**All other endpoints now require the Authorization header:**

```
Authorization: Bearer YOUR_TOKEN_HERE
```

#### **Example: Create a Business**

**Endpoint:** `POST /api/businesses`
**Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
Content-Type: application/json
```

**Body:**
```json
{
  "name": "My Restaurant",
  "type": "Restaurant",
  "businessType": "manufacturing",
  "location": "New York",
  "description": "Italian cuisine"
}
```

**Note:** The `owner` field is automatically set from your JWT. The business will belong to you!

---

### **Step 5: Get Your Businesses**

**Endpoint:** `GET /api/businesses`
**Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**Response:** Only returns businesses you own!

---

## 🎯 **businessType Explained:**

When creating a business, you must specify a `businessType`:

### **"manufacturing"**
- You produce sellable items from purchased raw materials
- **Example:** Restaurant (buy ingredients → cook → sell meals)
- **Example:** Bakery (buy flour, sugar → bake → sell bread)

### **"resale"**
- You buy finished products and resell them as-is
- **Example:** Retail shop (buy clothes → resell clothes)
- **Example:** Electronics store (buy phones → resell phones)

---

## 🔐 **Security Notes:**

### **Tokens Expire in 7 Days**
- After 7 days, you'll need to login again
- The token will return a 401 error when expired

### **Password Requirements:**
- Minimum 6 characters
- Stored as bcrypt hash (never plain text)

### **Multi-Tenant Isolation:**
- You can only see/edit your own data
- Other users' data returns 404 (not found)
- No way to access another user's businesses

---

## 🧪 **Testing with Postman:**

### **1. Register/Login**
- Method: POST
- URL: `http://localhost:3000/api/auth/register` or `/login`
- Body: raw JSON with email, password, name

### **2. Copy the Token**
- From the response, copy the `token` value

### **3. Set Authorization**
- In Postman, go to the "Authorization" tab
- Type: Bearer Token
- Token: Paste your token

### **4. Make Requests**
- Now you can use any protected endpoint
- The token will automatically be sent with each request

---

## ⚠️ **Common Errors:**

### **401 Unauthorized**
- **Cause:** Missing or invalid token
- **Fix:** Check Authorization header format: `Bearer YOUR_TOKEN`

### **404 Business not found**
- **Cause:** Trying to access another user's business
- **Fix:** Only use business IDs from your own businesses

### **409 Email already registered**
- **Cause:** Email is already in use
- **Fix:** Use a different email or login with existing account

### **Invalid credentials**
- **Cause:** Wrong email or password
- **Fix:** Check spelling and case sensitivity

---

## 📝 **Example Workflow:**

```bash
# 1. Register
POST /api/auth/register
{ "name": "Alice", "email": "alice@test.com", "password": "test123" }
→ Save token: abc123...

# 2. Create Business
POST /api/businesses
Headers: Authorization: Bearer abc123...
{ "name": "Alice's Shop", "type": "Retail", "businessType": "resale", "location": "LA" }
→ Business created with owner = Alice

# 3. Get Businesses
GET /api/businesses
Headers: Authorization: Bearer abc123...
→ Returns only Alice's businesses

# 4. Create Product for Business
POST /api/products
Headers: Authorization: Bearer abc123...
{ "business": "BUSINESS_ID", "name": "Product 1", ... }
→ Product created under Alice's business
```

---

## 🎉 **You're Ready!**

Your backend now has:
✅ Secure JWT authentication
✅ User registration & login
✅ Protected API endpoints
✅ Multi-tenant isolation
✅ Business ownership enforcement

**Start building your Flutter app with confidence!** 🚀