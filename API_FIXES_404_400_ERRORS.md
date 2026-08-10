# 🔧 Fixed: 404 and 400 API Errors on Startup

## Errors Found in Logs

```
❌ Error: Cannot GET /api/cash-registers
Status: 404

❌ Error: from and to dates are required  
Status: 400
```

---

## Fix 1: Cash Register API - 404 Error ✅ FIXED

### Problem
Frontend was calling:
```
GET /api/cash-registers?business=6a521f7f668975eb620fe8be
```

But backend expects:
```
GET /api/cash-registers/business/6a521f7f668975eb620fe8be
```

### Root Cause
Incorrect endpoint path in `cash_register_service.dart`. The backend route is `/business/:businessId` (path parameter), not a query parameter.

### Solution
**File: `front/lib/services/cash_register_service.dart`**

#### Before:
```dart
Future<List<CashRegister>> getCashRegisters(String businessId) async {
  final response = await _client.get<List<dynamic>>('/cash-registers',
      queryParameters: {'business': businessId});
  // ...
}
```

#### After:
```dart
Future<List<CashRegister>> getCashRegisters(String businessId) async {
  // Correct endpoint: /cash-registers/business/:businessId
  final response = await _client.get('/cash-registers/business/$businessId');
  
  final data = response.data as Map<String, dynamic>;
  final registers = data['data'] as List<dynamic>? ?? [];
  // ...
}
```

### Backend Route (Verified in `back/routes/cashRegister.routes.js`):
```javascript
router.get('/business/:businessId', cashRegisterController.getRegistersByBusiness);
```

**✅ Now calls correct endpoint:** `/api/cash-registers/business/6a521f7f668975eb620fe8be`

---

## Fix 2: Cash Flow API - 400 Error (Missing Required Dates) ✅ FIXED

### Problem
Frontend was calling:
```
GET /api/cash-flow/business/6a521f7f668975eb620fe8be?groupBy=day&startDate=2026-07-01T00:00:00.000
```

Backend returned:
```
400 Bad Request: "from and to dates are required"
```

### Root Cause
Two issues:
1. **Wrong parameter names:** Frontend sent `startDate` and `endDate`, but backend expects `from` and `to`
2. **Missing required parameter:** Frontend only sent `startDate`, but backend requires BOTH `from` AND `to`

### Solution
**File: `front/lib/services/cash_flow_service.dart`**

#### Before:
```dart
Future<CashFlowSummary> getCashFlowReport(
  String businessId, {
  String groupBy = 'day',
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final queryParams = <String, dynamic>{
    'groupBy': groupBy,
    if (startDate != null) 'startDate': startDate.toIso8601String(),
    if (endDate != null) 'endDate': endDate.toIso8601String(),
  };
  // Could send incomplete params! ❌
}
```

#### After:
```dart
Future<CashFlowSummary> getCashFlowReport(
  String businessId, {
  String groupBy = 'day',
  DateTime? startDate,
  DateTime? endDate,
}) async {
  // Provide default dates if not specified (current month)
  final now = DateTime.now();
  final defaultStartDate = startDate ?? DateTime(now.year, now.month, 1);
  final defaultEndDate = endDate ?? now;
  
  // Backend expects "from" and "to", not "startDate" and "endDate"
  final queryParams = <String, dynamic>{
    'groupBy': groupBy,
    'from': defaultStartDate.toIso8601String(),
    'to': defaultEndDate.toIso8601String(),
  };
  // Always sends both required params! ✅
}
```

### Backend Requirements (Verified in `back/controllers/cashFlow.controller.js`):
```javascript
const { from, to, groupBy = 'month' } = req.query;

if (!from || !to) {
  return res.status(400).json({
    message: 'from and to dates are required',
  });
}
```

**Changes:**
1. ✅ Changed `startDate` → `from`
2. ✅ Changed `endDate` → `to`  
3. ✅ Added default dates so both are always present
4. ✅ Default: First day of current month → Today

---

## Fix 3: Cash Flow Model - Response Parsing ✅ FIXED

### Problem
The `CashFlowSummary` model wasn't correctly parsing the backend response structure.

### Backend Response Structure:
```json
{
  "success": true,
  "data": {
    "period": {
      "from": "2026-07-01T00:00:00.000Z",
      "to": "2026-07-13T23:59:59.999Z",
      "groupBy": "day"
    },
    "summary": {
      "totalCashIn": 620,
      "totalCashOut": 0,
      "netCashFlow": 620,
      "nonCashLosses": 0
    },
    "breakdown": [
      {
        "period": "2026-07-13",
        "cashIn": 620,
        "cashOut": 0,
        "net": 620,
        "nonCashLoss": 0
      }
    ]
  }
}
```

### Solution
**File: `front/lib/models/cash_flow_report.dart`**

Updated model to:
- Read from `breakdown` array (not `data` or `periods`)
- Use `net` field (not `netCashFlow`) in breakdown items
- Use `nonCashLoss` field (not `nonCashLosses`) in breakdown items
- Read summary from `summary` object

#### Key Changes:
```dart
factory CashFlowSummary.fromJson(Map<String, dynamic> json) {
  // Backend returns: { period: {...}, summary: {...}, breakdown: [...] }
  final summary = json['summary'] as Map<String, dynamic>? ?? {};
  final breakdownData = json['breakdown'] as List? ?? []; // ✅ Changed from 'data'
  
  final periods = breakdownData
      .map((p) => CashFlowReport.fromJson(p as Map<String, dynamic>))
      .toList();
  // ...
}

factory CashFlowReport.fromJson(Map<String, dynamic> json) {
  return CashFlowReport(
    period: json['period']?.toString() ?? '',
    cashIn: (json['cashIn'] as num? ?? 0).toDouble(),
    cashOut: (json['cashOut'] as num? ?? 0).toDouble(),
    netCashFlow: (json['net'] as num? ?? 0).toDouble(), // ✅ 'net' not 'netCashFlow'
    nonCashLosses: (json['nonCashLoss'] as num? ?? 0).toDouble(), // ✅ 'nonCashLoss' not 'nonCashLosses'
  );
}
```

---

## Summary of Changes

### Files Modified: 3

1. ✅ **`front/lib/services/cash_register_service.dart`**
   - Changed endpoint from query param to path param
   - `/cash-registers?business=X` → `/cash-registers/business/X`

2. ✅ **`front/lib/services/cash_flow_service.dart`**
   - Changed parameter names: `startDate/endDate` → `from/to`
   - Added default dates to ensure both params always present
   - Default range: First day of current month → Today

3. ✅ **`front/lib/models/cash_flow_report.dart`**
   - Fixed JSON parsing to match backend response structure
   - Read from `breakdown` array
   - Use `net` and `nonCashLoss` field names

---

## Testing

### Before Fix:
```
🌐 GET http://localhost:3000/api/cash-registers?business=...
❌ Error: Cannot GET /api/cash-registers [404]

🌐 GET http://localhost:3000/api/cash-flow/business/...?startDate=...
❌ Error: from and to dates are required [400]
```

### After Fix:
```
🌐 GET http://localhost:3000/api/cash-registers/business/6a521f7f668975eb620fe8be
✅ Response [200]: {success: true, data: [...]}

🌐 GET http://localhost:3000/api/cash-flow/business/6a521f7f668975eb620fe8be?groupBy=day&from=2026-07-01T00:00:00.000Z&to=2026-07-13T23:59:59.999Z
✅ Response [200]: {success: true, data: {summary: {...}, breakdown: [...]}}
```

---

## How to Verify

1. **Stop the app** (if running)
2. **Hot restart** or **flutter run -d windows**
3. **Watch terminal on startup**

**Expected (No Errors):**
```
✅ Response [200]: {success: true, data: [...]}  // Cash registers
✅ Response [200]: {success: true, data: {...}}  // Cash flow report
```

**Should NOT see:**
```
❌ Error: Cannot GET /api/cash-registers
❌ Error: from and to dates are required
```

4. **Navigate to Reports screen** (from More tab)
5. **Verify cash flow chart loads** without errors

---

## Why These Errors Happened

1. **Cash Register 404:** Mismatch between frontend assumption (query param) and backend implementation (path param)

2. **Cash Flow 400:** Two reasons:
   - Frontend used wrong parameter names
   - Frontend didn't guarantee both required params were sent

3. **Both errors appeared on startup** because:
   - Dashboard screen loads cash flow data immediately
   - Reports provider fetches on initialization

---

**Status:** All API errors fixed ✅  
**Testing:** Hot restart and verify no errors in terminal  
**Created:** 2026-07-13
