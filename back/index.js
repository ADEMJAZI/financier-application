require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const { generalApiLimiter } = require('./middleware/rateLimiter');

const app = express();

// ── Trust proxy ────────────────────────────────────────────────────────────────
// Required when deployed behind a single reverse proxy (Render, Railway,
// Heroku, nginx, AWS ALB, etc.) so express-rate-limit resolves the real
// client IP from X-Forwarded-For instead of the proxy's IP.
app.set('trust proxy', 1);
// ──────────────────────────────────────────────────────────────────────────────

const server = http.createServer(app);

// ── Socket.IO ─────────────────────────────────────────────────────────────────
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: false,
  },
});
// ──────────────────────────────────────────────────────────────────────────────

// ── Middleware ─────────────────────────────────────────────────────────────────
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: false,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
// ──────────────────────────────────────────────────────────────────────────────

// ── Database ───────────────────────────────────────────────────────────────────
require('./database/dbconfig');
// ──────────────────────────────────────────────────────────────────────────────

// ── Global API rate limiter ────────────────────────────────────────────────────
// Broad safety net: 100 req/min per IP across all /api/* routes.
// Auth endpoints have their own tighter authLimiter applied on top of this.
app.use('/api/', generalApiLimiter);
// ──────────────────────────────────────────────────────────────────────────────

// ── Health check (no auth required — used by Render and monitoring) ────────────
app.get('/health', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Backend is running',
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString(),
  });
});
// ──────────────────────────────────────────────────────────────────────────────

// ── Route imports ──────────────────────────────────────────────────────────────
const authRoutes         = require('./routes/auth.routes');
const businessRoutes     = require('./routes/business.routes');
const productRoutes      = require('./routes/product.routes');
const expenseRoutes      = require('./routes/expense.routes');
const reserveRoutes      = require('./routes/reserve.routes');
const customerDebtRoutes = require('./routes/customerDebt.routes');
const cashRegisterRoutes = require('./routes/cashRegister.routes');
const wasteRoutes        = require('./routes/waste.routes');
const supplierRoutes     = require('./routes/supplier.routes');
const employeeRoutes     = require('./routes/employee.routes');
const purchaseRoutes     = require('./routes/purchase.routes');
const reorderRoutes      = require('./routes/reorder.routes');
const cashFlowRoutes     = require('./routes/cashFlow.routes');
const auditLogRoutes     = require('./routes/auditLog.routes');
const saleRoutes         = require('./routes/sale.routes');
const menuItemRoutes     = require('./routes/menuItem.routes');
const menuItemSaleRoutes = require('./routes/menuItemSale.routes');
const orderRoutes        = require('./routes/order.routes');
const aiRoutes           = require('./routes/ai.routes');
// ──────────────────────────────────────────────────────────────────────────────

// ── Password reset web page ────────────────────────────────────────────────────
// Serves a self-contained HTML page at GET /reset-password?token=xxx
// This is the URL embedded in password-reset emails. It calls
// POST /api/auth/reset-password directly via fetch — no separate frontend
// deployment is required.
app.get('/reset-password', (req, res) => {
  const token = req.query.token || '';
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.send(`<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>إعادة تعيين كلمة المرور - تاجر</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background: #f5f7fa; color: #2d3748;
      min-height: 100vh; display: flex; align-items: center; justify-content: center;
      padding: 16px;
    }
    .card {
      background: #fff; border-radius: 12px; padding: 40px 32px;
      width: 100%; max-width: 420px;
      box-shadow: 0 4px 24px rgba(0,0,0,0.10);
    }
    .logo { text-align: center; font-size: 28px; font-weight: 700; color: #4c51bf; margin-bottom: 8px; }
    h1 { text-align: center; font-size: 20px; font-weight: 600; margin-bottom: 8px; }
    .subtitle { text-align: center; font-size: 14px; color: #718096; margin-bottom: 32px; }
    label { display: block; font-size: 14px; font-weight: 500; margin-bottom: 6px; }
    input[type=password] {
      width: 100%; padding: 12px 14px; border: 1.5px solid #e2e8f0;
      border-radius: 8px; font-size: 15px; outline: none; transition: border .2s;
      direction: ltr; text-align: left;
    }
    input[type=password]:focus { border-color: #4c51bf; }
    .field { margin-bottom: 20px; }
    button {
      width: 100%; padding: 13px; background: #4c51bf; color: #fff;
      border: none; border-radius: 8px; font-size: 15px; font-weight: 600;
      cursor: pointer; transition: background .2s; margin-top: 4px;
    }
    button:hover:not(:disabled) { background: #434190; }
    button:disabled { opacity: .6; cursor: not-allowed; }
    .msg {
      margin-top: 20px; padding: 14px; border-radius: 8px;
      font-size: 14px; text-align: center; display: none;
    }
    .msg.success { background: #f0fff4; color: #276749; border: 1px solid #9ae6b4; }
    .msg.error   { background: #fff5f5; color: #c53030; border: 1px solid #fc8181; }
    .login-link { display: none; text-align: center; margin-top: 20px; font-size: 14px; color: #4c51bf; }
    #invalid-token { text-align: center; padding: 20px 0; display: none; }
    #invalid-token p { color: #c53030; font-size: 15px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">تاجر</div>

    <div id="invalid-token">
      <h1>رابط غير صالح</h1>
      <p>هذا الرابط غير صالح أو منتهي الصلاحية.<br>يرجى طلب رابط جديد.</p>
    </div>

    <form id="form">
      <h1>كلمة مرور جديدة</h1>
      <p class="subtitle">يجب أن تكون كلمة المرور 6 أحرف على الأقل</p>

      <div class="field">
        <label for="pwd">كلمة المرور الجديدة</label>
        <input id="pwd" type="password" placeholder="أدخل كلمة المرور الجديدة" autocomplete="new-password" required minlength="6">
      </div>
      <div class="field">
        <label for="pwd2">تأكيد كلمة المرور</label>
        <input id="pwd2" type="password" placeholder="أعد إدخال كلمة المرور" autocomplete="new-password" required minlength="6">
      </div>

      <button type="submit" id="btn">تغيير كلمة المرور</button>
      <div id="msg" class="msg"></div>
    </form>

    <div id="login-link" class="login-link">
      يمكنك الآن تسجيل الدخول في تطبيق تاجر بكلمة المرور الجديدة.
    </div>
  </div>

  <script>
    const TOKEN = ${JSON.stringify(token)};

    if (!TOKEN) {
      document.getElementById('form').style.display = 'none';
      document.getElementById('invalid-token').style.display = 'block';
    }

    document.getElementById('form').addEventListener('submit', async (e) => {
      e.preventDefault();
      const pwd  = document.getElementById('pwd').value;
      const pwd2 = document.getElementById('pwd2').value;
      const btn  = document.getElementById('btn');
      const msg  = document.getElementById('msg');

      msg.style.display = 'none';

      if (pwd !== pwd2) {
        msg.textContent = 'كلمتا المرور غير متطابقتين';
        msg.className = 'msg error';
        msg.style.display = 'block';
        return;
      }
      if (pwd.length < 6) {
        msg.textContent = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
        msg.className = 'msg error';
        msg.style.display = 'block';
        return;
      }

      btn.disabled = true;
      btn.textContent = 'جارٍ المعالجة...';

      try {
        const res = await fetch('/api/auth/reset-password', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ token: TOKEN, newPassword: pwd }),
        });
        const data = await res.json();

        if (res.ok) {
          document.getElementById('form').style.display = 'none';
          msg.textContent = 'تم تغيير كلمة المرور بنجاح! جميع الجلسات الأخرى أُلغيت للأمان.';
          msg.className = 'msg success';
          msg.style.display = 'block';
          document.getElementById('login-link').style.display = 'block';
        } else {
          msg.textContent = data.message || 'حدث خطأ. قد يكون الرابط منتهي الصلاحية.';
          msg.className = 'msg error';
          msg.style.display = 'block';
          btn.disabled = false;
          btn.textContent = 'تغيير كلمة المرور';
        }
      } catch (err) {
        msg.textContent = 'تعذّر الاتصال بالخادم. حاول مرة أخرى.';
        msg.className = 'msg error';
        msg.style.display = 'block';
        btn.disabled = false;
        btn.textContent = 'تغيير كلمة المرور';
      }
    });
  </script>
</body>
</html>`);
});
// ──────────────────────────────────────────────────────────────────────────────

// ── API routes ─────────────────────────────────────────────────────────────────
app.use('/api/auth',           authRoutes);
app.use('/api/businesses',     businessRoutes);
app.use('/api/products',       productRoutes);
app.use('/api/expenses',       expenseRoutes);
app.use('/api/reserves',       reserveRoutes);
app.use('/api/debts',          customerDebtRoutes);
app.use('/api/cash-registers', cashRegisterRoutes);
app.use('/api/waste',          wasteRoutes);
app.use('/api/suppliers',      supplierRoutes);
app.use('/api/employees',      employeeRoutes);
app.use('/api/purchases',      purchaseRoutes);
app.use('/api/reorder',        reorderRoutes);
app.use('/api/cash-flow',      cashFlowRoutes);
app.use('/api/audit-logs',     auditLogRoutes);
app.use('/api/sales',          saleRoutes);
app.use('/api/menu-items',     menuItemRoutes);
app.use('/api/menu-item-sales', menuItemSaleRoutes);
app.use('/api/orders',         orderRoutes);
app.use('/api/ai',             aiRoutes);
// ──────────────────────────────────────────────────────────────────────────────

// ── 404 handler ────────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: `Route not found: ${req.method} ${req.originalUrl}` });
});
// ──────────────────────────────────────────────────────────────────────────────

// ── Global error handler ───────────────────────────────────────────────────────
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err.message || err);
  const status = err.status || err.statusCode || 500;
  res.status(status).json({
    success: false,
    message: err.message || 'Internal server error',
  });
});
// ──────────────────────────────────────────────────────────────────────────────

// ── Start server ───────────────────────────────────────────────────────────────
const port = process.env.PORT || 3000;
server.listen(port, '0.0.0.0', () => {
  console.log('\n🚀 ================================');
  console.log(`✅ Backend started successfully`);
  console.log(`🌐 Listening on port ${port}`);
  console.log(`🔧 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log('🔐 API ready to accept requests');
  console.log('================================\n');
});
// ──────────────────────────────────────────────────────────────────────────────
