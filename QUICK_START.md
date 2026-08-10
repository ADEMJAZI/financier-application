# 🚀 Quick Start Guide

## Step 1: Start the Backend

Open a terminal in the `back` folder:

```bash
cd back
npm start
```

You should see:
```
Serveur démarré sur http://localhost:3000
Connexion à la base de données établie avec succès
```

## Step 2: Test the Backend with Postman

1. Open Postman
2. Import `back/Postman_Collection.json`
3. Run **Business Management** → **Create Business**
4. Copy the `_id` from the response
5. Run **Product Management** → **Create Product** (paste the business ID)

See `back/POSTMAN_TESTING_GUIDE.md` for detailed instructions.

## Step 3: Start the Flutter App

Open a **new terminal** in the `front` folder:

```bash
cd front
flutter run -d windows
```

The app will build and launch automatically!

## What You Should See

### Dashboard Screen
- Business selector dropdown (select your created business)
- 4 stat cards showing:
  - Total Products
  - Low Stock Items
  - Inventory Value
  - Pending Debts
- Quick action buttons

### Products Screen
- Search bar
- List of all products for the selected business
- Each product shows:
  - Name and unit
  - Quantity (with low stock warning if < 10)
  - Purchase price and selling price
  - Profit margin
  - Total value
- FAB (Floating Action Button) to add products

## Testing the App

1. **Create a business** in Postman first
2. **Create some products** with that business ID
3. **Open the Flutter app**
4. **Select the business** from the dropdown
5. **Navigate** between Dashboard and Products tabs
6. **Search** for products by name

## Common Issues

### Backend Won't Start
- Make sure MongoDB is accessible
- Check if port 3000 is free

### Flutter Build Fails
Run:
```bash
flutter clean
flutter pub get
flutter run -d windows
```

### App Shows "No Business Yet"
- Create a business in Postman first
- The app needs at least one business to display data

### Products Don't Show
- Make sure you selected a business from the dropdown
- Create products using Postman with the correct business ID
- Pull down to refresh the list

## Next Steps

- Add more businesses and products
- Explore the API using Postman
- Check the console logs to see API requests/responses
- The app auto-refreshes when you change the selected business

## Hot Reload (Flutter)

While the app is running, you can edit the code and press:
- **r** in the terminal to hot reload
- **R** to hot restart
- **q** to quit

Enjoy! 🎉
