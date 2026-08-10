# Business Management System

A full-stack business and inventory management application built with **Flutter** (frontend) and **Node.js + Express + MongoDB** (backend).

## 📋 Project Structure

```
projetmobile/
├── back/                           # Backend (Node.js + Express + MongoDB)
│   ├── models/                     # Mongoose models
│   │   ├── Business.js
│   │   └── Product.js
│   ├── controllers/                # Business logic
│   │   ├── business.controller.js
│   │   └── product.controller.js
│   ├── routes/                     # API routes
│   │   ├── business.routes.js
│   │   └── product.routes.js
│   ├── database/                   # Database configuration
│   │   └── dbconfig.js
│   ├── index.js                    # Server entry point
│   ├── package.json
│   ├── Postman_Collection.json     # Postman API collection
│   └── POSTMAN_TESTING_GUIDE.md   # Detailed API testing guide
│
└── front/                          # Frontend (Flutter)
    ├── lib/
    │   ├── theme/                  # Design system
    │   │   ├── app_colors.dart
    │   │   ├── app_spacing.dart
    │   │   ├── app_typography.dart
    │   │   └── app_theme.dart
    │   ├── models/                 # Data models
    │   │   ├── business.dart
    │   │   └── product.dart
    │   ├── services/               # API services
    │   │   ├── api_client.dart
    │   │   ├── business_service.dart
    │   │   └── product_service.dart
    │   ├── providers/              # Riverpod state management
    │   │   ├── service_providers.dart
    │   │   ├── business_provider.dart
    │   │   └── product_provider.dart
    │   ├── widgets/                # Reusable widgets
    │   │   ├── empty_state.dart
    │   │   ├── error_state.dart
    │   │   ├── loading_shimmer.dart
    │   │   └── stat_card.dart
    │   ├── screens/                # Application screens
    │   │   ├── home/
    │   │   │   └── home_screen.dart
    │   │   ├── dashboard/
    │   │   │   └── dashboard_screen.dart
    │   │   └── products/
    │   │       └── products_screen.dart
    │   ├── utils/                  # Utilities
    │   │   └── formatters.dart
    │   └── main.dart               # App entry point
    └── pubspec.yaml
```

## 🚀 Getting Started

### Prerequisites

- **Node.js** (v14 or higher)
- **MongoDB** (running locally or cloud instance)
- **Flutter SDK** (v3.0 or higher)
- **VS Code** or **Android Studio** (recommended)

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd back
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Configure database:**
   - Open `database/dbconfig.js`
   - Update MongoDB connection string if needed (currently set to MongoDB Atlas)

4. **Start the server:**
   ```bash
   npm start
   ```
   
   Server will run on `http://localhost:3000`

### Frontend Setup

1. **Navigate to frontend directory:**
   ```bash
   cd front
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   
   **For Windows:**
   ```bash
   flutter run -d windows
   ```
   
   **For Android:**
   ```bash
   flutter run -d android
   ```
   
   **For iOS:**
   ```bash
   flutter run -d ios
   ```

## 🧪 Testing the APIs

### Option 1: Using Postman (Recommended)

1. **Import the collection:**
   - Open Postman
   - Click **Import** → **Upload Files**
   - Select `back/Postman_Collection.json`

2. **Follow the testing guide:**
   - See `back/POSTMAN_TESTING_GUIDE.md` for detailed step-by-step instructions
   - Test all CRUD operations for Business and Product

### Option 2: Using curl

**Create a Business:**
```bash
curl -X POST http://localhost:3000/api/businesses \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"My Store\",\"type\":\"Retail\",\"location\":\"Tunis\",\"description\":\"A retail store\"}"
```

**Get All Businesses:**
```bash
curl http://localhost:3000/api/businesses
```

**Create a Product:**
```bash
curl -X POST http://localhost:3000/api/products \
  -H "Content-Type: application/json" \
  -d "{\"business\":\"PASTE_BUSINESS_ID\",\"name\":\"Apples\",\"purchasePrice\":0.5,\"price\":1.2,\"quantity\":100,\"unit\":\"kg\"}"
```

## 📱 Features

### ✅ Implemented Features

#### Backend APIs
- ✅ Business CRUD operations
- ✅ Product CRUD operations
- ✅ Products filtered by business
- ✅ Input validation
- ✅ Error handling
- ✅ MongoDB integration with Mongoose

#### Frontend
- ✅ Professional design system (light/dark themes)
- ✅ Dashboard with business selector
- ✅ Product listing with search
- ✅ Real-time API integration
- ✅ Loading states (shimmer effects)
- ✅ Empty states with call-to-action
- ✅ Error states with retry
- ✅ Pull-to-refresh
- ✅ Responsive UI
- ✅ State management with Riverpod

### 🚧 Coming Soon
- Expense tracking
- Customer debt management
- Cash register
- Supplier management
- Employee management
- Reports and analytics
- Multi-language support (Arabic/French/English)
- Authentication

## 🎨 Design System

### Colors
- **Primary:** Blue (#2563EB light, #3B82F6 dark)
- **Secondary:** Violet (#7C3AED light, #8B5CF6 dark)
- **Success:** Green (#16A34A light, #22C55E dark)
- **Warning:** Orange (#EA580C light, #F97316 dark)
- **Danger:** Red (#DC2626 light, #EF4444 dark)

### Spacing Scale
- XS: 4px
- SM: 8px
- MD: 12px
- LG: 16px
- XL: 24px
- XXL: 32px

### Typography
- Display: 32px bold
- H1: 28px bold
- H2: 24px bold
- H3: 20px semibold
- Body: 14-16px regular

## 🛠️ Tech Stack

### Backend
- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** MongoDB with Mongoose ODM
- **CORS:** Enabled for cross-origin requests

### Frontend
- **Framework:** Flutter
- **State Management:** Riverpod
- **HTTP Client:** Dio
- **Charts:** fl_chart
- **Animations:** Shimmer
- **Utilities:** intl (formatting)

## 📝 API Endpoints

### Business Routes (`/api/businesses`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/` | Create a new business |
| GET | `/` | Get all businesses |
| GET | `/:id` | Get business by ID |
| PUT | `/:id` | Update business |
| DELETE | `/:id` | Delete business |

### Product Routes (`/api/products`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/` | Create a new product |
| GET | `/business/:businessId` | Get products by business |
| GET | `/:id` | Get product by ID |
| PUT | `/:id` | Update product |
| DELETE | `/:id` | Delete product |

## 🐛 Troubleshooting

### Backend Issues

**Server not starting:**
- Check if MongoDB is running
- Verify MongoDB connection string
- Ensure port 3000 is not in use

**Database connection failed:**
- Check MongoDB Atlas credentials
- Verify IP whitelist in MongoDB Atlas
- Test connection string separately

### Frontend Issues

**Flutter not found:**
```bash
flutter doctor
```

**Dependencies not installing:**
```bash
flutter clean
flutter pub get
```

**App not connecting to backend:**
- Ensure backend is running on `http://localhost:3000`
- Check if you can access `http://localhost:3000/api/businesses` in browser
- For Android emulator, use `http://10.0.2.2:3000` instead
- For physical device, use your machine's IP address

## 📄 License

This project is for educational purposes.

## 👥 Authors

- ADEM - Initial work

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Express.js and MongoDB communities
- Material Design for design guidelines
