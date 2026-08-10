# Testing Guide - Cart-Based Ordering System

## Prerequisites
✅ Backend server running on http://localhost:3000
✅ MongoDB connected
✅ Flutter dependencies installed

## How to Test

### 1. Start the Frontend Application
```bash
cd front
flutter run -d windows
```

### 2. Login
- Email: `ademjazi@gmail.com`
- Password: `adem00159`

### 3. Select Your Manufacturing Business
- Should see "resto" (manufacturing type)

### 4. Test Menu Items with Recipes

#### Create Menu Item with Recipe
1. Navigate to Sales screen
2. Click settings icon (top right)
3. Click "Add Menu Item"
4. Enter name: "Pizza"
5. Enter price: "15.000"
6. Click "Add Ingredient"
7. Select a raw material (e.g., "ee")
8. Enter quantity: "0.5"
9. Click "Add Ingredient"
10. Verify ingredient shows in list
11. Click "Add Item"

Expected: Menu item created with recipe

#### View Menu Items
1. Go back to Sales screen
2. Verify "Pizza" shows in grid
3. Should show ingredient count badge

### 5. Test Cart-Based Ordering

#### Add Items to Cart
1. Tap "Pizza" card once
2. Badge should show "1"
3. Bottom cart summary should appear
4. Tap again to increment
5. Badge should show "2"

Expected: 
- Badge updates correctly
- Cart summary shows total items and amount

#### Review Cart
1. Tap on cart summary bar at bottom
2. Should see cart review sheet
3. Verify items list correctly
4. Try +/- buttons to adjust quantity
5. Try remove button (X icon)

Expected:
- Quantity updates work
- Remove works
- Total updates correctly

#### Checkout with Sufficient Stock
1. Add items to cart
2. Click "Checkout" button
3. Wait for success message

Expected:
- Order created successfully
- Cart clears
- Today's Orders summary updates
- Stock deducted from raw materials

#### Checkout with Insufficient Stock
1. Navigate to Stock screen
2. Set a raw material quantity very low (e.g., 0.1)
3. Go back to Sales
4. Add menu item that needs that material
5. Set quantity high
6. Try checkout

Expected:
- Error dialog appears
- Shows which materials are insufficient
- Shows required vs available quantities
- Order NOT created
- Cart NOT cleared

### 6. Test Order History

#### View Today's Orders
1. On Sales screen
2. Check "Today's Orders" summary bar
3. Should show order count and revenue

#### View Order Details
(Future feature - to be implemented)
- Click on an order
- See items, quantities, prices
- See stock consumption details

### 7. Test Order Voiding

(Future feature - to be implemented)
1. View order details
2. Click "Void Order"
3. Enter reason
4. Confirm

Expected:
- Order marked as voided
- Stock restored
- Summary updates

### 8. Test Business Isolation

#### Test as Current User
1. Note down your businesses
2. Note down some data (orders, products, etc.)

#### Test as Different User
1. Logout
2. Create new account or login with different credentials
3. Verify you CANNOT see:
   - Other user's businesses
   - Other user's products
   - Other user's orders
   - Any data from other users

Expected:
- Complete data isolation
- Each user only sees their own data
- No 404 or 403 errors when accessing own data

### 9. Test Recipe Management

#### Add Multiple Ingredients
1. Edit a menu item
2. Add 3-4 different ingredients
3. Set different quantities
4. Save

Expected:
- All ingredients saved
- Quantities correct
- Can view/edit later

#### Remove Ingredients
1. Edit menu item
2. Click X on ingredient
3. Save

Expected:
- Ingredient removed
- Recipe updates correctly

#### Menu Item Without Recipe
1. Create menu item
2. Don't add any ingredients
3. Save

Expected:
- Menu item created successfully
- No stock deduction on sale
- Works normally for businesses that don't track ingredients

## Common Issues & Solutions

### Issue: "Insufficient stock" error
**Solution**: Check raw material quantities in Stock screen

### Issue: Cart not updating
**Solution**: 
1. Hot reload (press 'r' in terminal)
2. Check provider is watching correctly
3. Verify cart provider implementation

### Issue: Orders not showing
**Solution**:
1. Check backend console for errors
2. Verify business ID is correct
3. Check MongoDB connection

### Issue: "Business not found"
**Solution**:
1. Logout and login again
2. Select business from picker
3. Verify JWT token is valid

### Issue: Stock not deducting
**Solution**:
1. Check menu item has recipe
2. Check recipe ingredients are valid
3. Check backend logs for errors
4. Verify transaction completes

## Performance Checks

✅ Cart updates instantly (no API calls)
✅ Menu items load quickly
✅ Grid scrolls smoothly
✅ Checkout completes in <2 seconds
✅ No lag when adding items

## UI/UX Checks

✅ Cart badge visible and updates
✅ Cart summary always accessible
✅ Insufficient stock error is clear
✅ Success messages appear
✅ Loading states show properly
✅ Empty states have actions
✅ All buttons work
✅ Navigation works correctly

## Security Checks

✅ Cannot access other users' businesses
✅ Cannot create order for other's business
✅ Cannot see other users' data
✅ JWT required for all operations
✅ Business ownership verified

## Backend Health Checks

```bash
# Check if server is running
curl http://localhost:3000/api/auth/me -H "Authorization: Bearer YOUR_TOKEN"

# Check orders endpoint
curl http://localhost:3000/api/orders/business/YOUR_BUSINESS_ID -H "Authorization: Bearer YOUR_TOKEN"

# Check daily summary
curl http://localhost:3000/api/orders/business/YOUR_BUSINESS_ID/daily-summary -H "Authorization: Bearer YOUR_TOKEN"
```

## Next Steps After Testing

1. **If all tests pass**: 
   - Deploy to production
   - Update user documentation
   - Train users on new cart flow

2. **If tests fail**:
   - Check console errors
   - Review backend logs
   - Verify database state
   - Check API responses

3. **Future Enhancements**:
   - Add order history view
   - Add order details modal
   - Add void order functionality
   - Add order search/filter
   - Add export orders feature
   - Add print invoice feature

## Support

If you encounter issues not covered here:
1. Check Flutter console for errors
2. Check backend terminal for logs
3. Check MongoDB for data consistency
4. Review CRITICAL_FIXES_SUMMARY.md for recent changes
