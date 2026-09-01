'use strict';
const https = require('https');

// ─── Brevo REST API helper ─────────────────────────────────────────────────────
// Uses Node's built-in https rather than the @getbrevo/brevo SDK.
// The SDK silently swallows error response bodies on 4xx; the direct REST call
// gives us the full JSON body for every error, making diagnosis much easier.

/**
 * POST to Brevo's transactional email endpoint.
 * Returns { ok: true, messageId } on success, or throws with full error detail.
 */
async function _brevoSend(payload) {
  const apiKey = process.env.BREVO_API_KEY;
  const body = JSON.stringify(payload);

  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.brevo.com',
      path: '/v3/smtp/email',
      method: 'POST',
      headers: {
        'accept': 'application/json',
        'api-key': apiKey,
        'content-type': 'application/json',
        'content-length': Buffer.byteLength(body),
      },
    };

    const req = https.request(options, (res) => {
      let raw = '';
      res.on('data', (chunk) => { raw += chunk; });
      res.on('end', () => {
        let parsed = null;
        try { parsed = JSON.parse(raw); } catch (_) { parsed = raw; }

        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve({ ok: true, messageId: parsed?.messageId ?? null });
        } else {
          const err = new Error(`Brevo API error ${res.statusCode}: ${JSON.stringify(parsed)}`);
          err.status = res.statusCode;
          err.brevoBody = parsed;
          reject(err);
        }
      });
    });

    req.on('error', (err) => {
      err.isNetworkError = true;
      reject(err);
    });

    req.write(body);
    req.end();
  });
}

function _getSender() {
  return {
    email: process.env.BREVO_SENDER_EMAIL,
    name: process.env.BREVO_SENDER_NAME || 'تاجر',
  };
}

// ─── Public functions (signatures unchanged) ───────────────────────────────────

/**
 * Send email verification OTP code to user.
 * @param {string} to - Recipient email address
 * @param {string} name - Recipient name
 * @param {string} otp - Raw 6-digit numeric code
 */
async function sendVerificationEmail(to, name, otp) {
  try {
    const result = await _brevoSend({
      sender: _getSender(),
      to: [{ email: to }],
      subject: 'رمز التحقق - تاجر',
      htmlContent: getVerificationEmailHTML(name, otp),
    });
    console.log('[Brevo] Verification email SENT →', to, '| messageId:', result.messageId ?? '(none)');
    return true;
  } catch (error) {
    console.error('[Brevo] Verification email FAILED →', to,
                  '| status:', error.status ?? 'network',
                  '| detail:', JSON.stringify(error.brevoBody ?? error.message));
    return false;
  }
}

/**
 * Send password reset OTP code to user.
 * @param {string} to - Recipient email address
 * @param {string} name - Recipient name
 * @param {string} otp - Raw 6-digit numeric code
 */
async function sendPasswordResetEmail(to, name, otp) {
  try {
    const result = await _brevoSend({
      sender: _getSender(),
      to: [{ email: to }],
      subject: 'رمز إعادة تعيين كلمة المرور - تاجر',
      htmlContent: getPasswordResetEmailHTML(name, otp),
    });
    console.log('[Brevo] Password reset email SENT →', to, '| messageId:', result.messageId ?? '(none)');
    return true;
  } catch (error) {
    console.error('[Brevo] Password reset email FAILED →', to,
                  '| status:', error.status ?? 'network',
                  '| detail:', JSON.stringify(error.brevoBody ?? error.message));
    return false;
  }
}

/**
 * Send password change confirmation email.
 * @param {string} to - Recipient email address
 * @param {string} name - Recipient name
 */
async function sendPasswordChangeConfirmation(to, name) {
  try {
    const result = await _brevoSend({
      sender: _getSender(),
      to: [{ email: to }],
      subject: 'تم تغيير كلمة المرور - تاجر',
      htmlContent: getPasswordChangeConfirmationHTML(name),
    });
    console.log('[Brevo] Password change confirmation SENT →', to, '| messageId:', result.messageId ?? '(none)');
    return true;
  } catch (error) {
    console.error('[Brevo] Password change confirmation FAILED →', to,
                  '| status:', error.status ?? 'network',
                  '| detail:', JSON.stringify(error.brevoBody ?? error.message));
    return false;
  }
}

// ─── HTML Templates ────────────────────────────────────────────────────────────

function getVerificationEmailHTML(name, otp) {
  const otpDisplay = `${otp.slice(0, 3)} ${otp.slice(3)}`;
  return `
    <!DOCTYPE html>
    <html dir="rtl" lang="ar">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>رمز التحقق</title>
      <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f7fa; color: #2d3748; direction: rtl; }
        .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #10b981 0%, #0d9488 100%); color: #ffffff; padding: 30px 20px; text-align: center; }
        .logo { font-size: 32px; font-weight: bold; margin-bottom: 8px; }
        .header-subtitle { font-size: 15px; opacity: 0.9; margin: 0; }
        .content { padding: 36px 30px 28px; }
        .greeting { font-size: 18px; margin-bottom: 16px; color: #2d3748; }
        .message { font-size: 15px; line-height: 1.7; color: #4a5568; margin-bottom: 32px; }
        .otp-wrapper { text-align: center; margin: 0 0 32px; }
        .otp-label { font-size: 13px; color: #718096; margin-bottom: 12px; letter-spacing: 0.05em; }
        .otp-box { display: inline-block; background: linear-gradient(135deg, #f0fdf4 0%, #ecfdf5 100%); border: 2px solid #10b981; border-radius: 12px; padding: 20px 40px; }
        .otp-code { font-family: 'Courier New', Courier, monospace; font-size: 48px; font-weight: 700; letter-spacing: 0.18em; color: #065f46; line-height: 1; direction: ltr; display: block; }
        .expiry-notice { background-color: #fef3c7; border: 1px solid #f59e0b; border-radius: 6px; padding: 14px 18px; margin-bottom: 28px; font-size: 14px; color: #92400e; line-height: 1.5; }
        .attempt-notice { background-color: #fef2f2; border: 1px solid #fca5a5; border-radius: 6px; padding: 14px 18px; margin-bottom: 20px; font-size: 13px; color: #991b1b; line-height: 1.5; }
        .ignore-notice { font-size: 13px; color: #718096; line-height: 1.6; margin-top: 8px; }
        .footer { background-color: #f7fafc; padding: 20px; text-align: center; font-size: 13px; color: #718096; border-top: 1px solid #e2e8f0; line-height: 1.6; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="logo">تاجر</div>
          <p class="header-subtitle">مدير الأعمال الذكي</p>
        </div>
        <div class="content">
          <div class="greeting">مرحباً ${name}،</div>
          <div class="message">شكراً لتسجيلك في تاجر! أدخل رمز التحقق أدناه في التطبيق لتأكيد عنوان بريدك الإلكتروني.</div>
          <div class="otp-wrapper">
            <div class="otp-label">رمز التحقق المكوّن من 6 أرقام</div>
            <div class="otp-box"><span class="otp-code">${otpDisplay}</span></div>
          </div>
          <div class="expiry-notice"><strong>⏱ تنبيه:</strong> هذا الرمز صالح لمدة <strong>10 دقائق فقط</strong> من وقت إرسال هذه الرسالة.</div>
          <div class="attempt-notice"><strong>🔒 تنبيه أمني:</strong> لديك 5 محاولات لإدخال الرمز. بعد 5 محاولات فاشلة سيتم إلغاء الرمز.</div>
          <div class="ignore-notice">إذا لم تقم بإنشاء حساب في تاجر، يمكنك تجاهل هذه الرسالة بأمان.</div>
        </div>
        <div class="footer">
          <p>© 2026 تاجر - مدير الأعمال</p>
          <p>هذه رسالة تلقائية، يرجى عدم الرد عليها.</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

function getPasswordResetEmailHTML(name, otp) {
  const otpDisplay = `${otp.slice(0, 3)} ${otp.slice(3)}`;
  return `
    <!DOCTYPE html>
    <html dir="rtl" lang="ar">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>رمز إعادة تعيين كلمة المرور</title>
      <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f7fa; color: #2d3748; direction: rtl; }
        .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #e53e3e 0%, #c53030 100%); color: #ffffff; padding: 30px 20px; text-align: center; }
        .logo { font-size: 32px; font-weight: bold; margin-bottom: 8px; }
        .header-subtitle { font-size: 15px; opacity: 0.9; margin: 0; }
        .content { padding: 36px 30px 28px; }
        .greeting { font-size: 18px; margin-bottom: 16px; color: #2d3748; }
        .message { font-size: 15px; line-height: 1.7; color: #4a5568; margin-bottom: 32px; }
        .otp-wrapper { text-align: center; margin: 0 0 32px; }
        .otp-label { font-size: 13px; color: #718096; margin-bottom: 12px; letter-spacing: 0.05em; }
        .otp-box { display: inline-block; background: linear-gradient(135deg, #fff5f5 0%, #fed7d7 100%); border: 2px solid #e53e3e; border-radius: 12px; padding: 20px 40px; }
        .otp-code { font-family: 'Courier New', Courier, monospace; font-size: 48px; font-weight: 700; letter-spacing: 0.18em; color: #742a2a; line-height: 1; direction: ltr; display: block; }
        .expiry-notice { background-color: #fef3c7; border: 1px solid #f59e0b; border-radius: 6px; padding: 14px 18px; margin-bottom: 28px; font-size: 14px; color: #92400e; line-height: 1.5; }
        .attempt-notice { background-color: #fef2f2; border: 1px solid #fca5a5; border-radius: 6px; padding: 14px 18px; margin-bottom: 20px; font-size: 13px; color: #991b1b; line-height: 1.5; }
        .ignore-notice { font-size: 13px; color: #718096; line-height: 1.6; margin-top: 8px; }
        .footer { background-color: #f7fafc; padding: 20px; text-align: center; font-size: 13px; color: #718096; border-top: 1px solid #e2e8f0; line-height: 1.6; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="logo">تاجر</div>
          <p class="header-subtitle">إعادة تعيين كلمة المرور</p>
        </div>
        <div class="content">
          <div class="greeting">مرحباً ${name}،</div>
          <div class="message">تلقينا طلباً لإعادة تعيين كلمة المرور لحسابك في تاجر. أدخل رمز إعادة التعيين أدناه في التطبيق.</div>
          <div class="otp-wrapper">
            <div class="otp-label">رمز إعادة التعيين المكوّن من 6 أرقام</div>
            <div class="otp-box"><span class="otp-code">${otpDisplay}</span></div>
          </div>
          <div class="expiry-notice"><strong>⏱ تنبيه:</strong> هذا الرمز صالح لمدة <strong>10 دقائق فقط</strong> من وقت إرسال هذه الرسالة.</div>
          <div class="attempt-notice"><strong>🔒 تنبيه أمني:</strong> لديك 5 محاولات لإدخال الرمز. بعد 5 محاولات فاشلة سيتم إلغاء الرمز.</div>
          <div class="ignore-notice">إذا لم تطلب إعادة تعيين كلمة المرور، يمكنك تجاهل هذه الرسالة بأمان.</div>
        </div>
        <div class="footer">
          <p>© 2026 تاجر - مدير الأعمال</p>
          <p>هذه رسالة تلقائية، يرجى عدم الرد عليها.</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

function getPasswordChangeConfirmationHTML(name) {
  return `
    <!DOCTYPE html>
    <html dir="rtl" lang="ar">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>تم تغيير كلمة المرور</title>
      <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f5f7fa; color: #2d3748; direction: rtl; }
        .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #38a169 0%, #2f855a 100%); color: #ffffff; padding: 30px 20px; text-align: center; }
        .logo { font-size: 32px; font-weight: bold; margin-bottom: 10px; }
        .content { padding: 30px; }
        .greeting { font-size: 18px; margin-bottom: 20px; color: #2d3748; }
        .message { font-size: 16px; line-height: 1.6; margin-bottom: 30px; color: #4a5568; }
        .success-notice { background-color: #f0fff4; border: 1px solid #9ae6b4; border-radius: 4px; padding: 15px; margin-top: 20px; font-size: 14px; color: #2f855a; }
        .footer { background-color: #f7fafc; padding: 20px; text-align: center; font-size: 14px; color: #718096; border-top: 1px solid #e2e8f0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="logo">تاجر</div>
          <p>تأكيد تغيير كلمة المرور</p>
        </div>
        <div class="content">
          <div class="greeting">مرحباً ${name}،</div>
          <div class="message">تم تغيير كلمة المرور لحسابك في تاجر بنجاح. إذا قمت بهذا التغيير، فلا حاجة لاتخاذ أي إجراء إضافي.</div>
          <div class="success-notice">
            <strong>تم بنجاح:</strong> تم تغيير كلمة المرور في ${new Date().toLocaleString('ar-SA', { timeZone: 'Asia/Riyadh' })}
          </div>
          <div class="message" style="margin-top:30px;font-size:14px;">إذا لم تقم بتغيير كلمة المرور، يرجى الاتصال بنا فوراً لحماية حسابك.</div>
        </div>
        <div class="footer">
          <p>© 2026 تاجر - مدير الأعمال</p>
          <p>هذه رسالة تلقائية، يرجى عدم الرد عليها.</p>
        </div>
      </div>
    </body>
    </html>
  `;
}

module.exports = {
  sendVerificationEmail,
  sendPasswordResetEmail,
  sendPasswordChangeConfirmation,
};
