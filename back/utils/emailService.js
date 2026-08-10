const { Resend } = require('resend');

const FROM_ADDRESS = 'onboarding@resend.dev';

// Lazy-initialize the Resend client so the module can be required without
// crashing when RESEND_API_KEY hasn't been loaded into the environment yet
// (e.g. during syntax checks or early require chains before dotenv runs).
function getResendClient() {
  return new Resend(process.env.RESEND_API_KEY);
}

/**
 * Send email verification link to user
 * @param {string} to - Recipient email address
 * @param {string} name - Recipient name
 * @param {string} verificationLink - Full verification URL
 */
async function sendVerificationEmail(to, name, verificationLink) {
  try {
    const resend = getResendClient();
    const { data, error } = await resend.emails.send({
      from: FROM_ADDRESS,
      to: [to],
      subject: 'تأكيد البريد الإلكتروني - تاجر',
      html: getVerificationEmailHTML(name, verificationLink),
    });

    if (error) {
      console.error('Email verification send failed:', error);
      return false;
    }

    console.log('Verification email sent successfully:', data?.id);
    return true;
  } catch (error) {
    console.error('Email service error (verification):', error.message);
    return false;
  }
}

/**
 * Send password reset link to user
 * @param {string} to - Recipient email address
 * @param {string} name - Recipient name
 * @param {string} resetLink - Full password reset URL
 */
async function sendPasswordResetEmail(to, name, resetLink) {
  try {
    const resend = getResendClient();
    const { data, error } = await resend.emails.send({
      from: FROM_ADDRESS,
      to: [to],
      subject: 'إعادة تعيين كلمة المرور - تاجر',
      html: getPasswordResetEmailHTML(name, resetLink),
    });

    if (error) {
      console.error('Password reset email send failed:', error);
      return false;
    }

    console.log('Password reset email sent successfully:', data?.id);
    return true;
  } catch (error) {
    console.error('Email service error (password reset):', error.message);
    return false;
  }
}

/**
 * Send password change confirmation email
 * @param {string} to - Recipient email address
 * @param {string} name - Recipient name
 */
async function sendPasswordChangeConfirmation(to, name) {
  try {
    const resend = getResendClient();
    const { data, error } = await resend.emails.send({
      from: FROM_ADDRESS,
      to: [to],
      subject: 'تم تغيير كلمة المرور - تاجر',
      html: getPasswordChangeConfirmationHTML(name),
    });

    if (error) {
      console.error('Password change confirmation email send failed:', error);
      return false;
    }

    console.log('Password change confirmation email sent successfully:', data?.id);
    return true;
  } catch (error) {
    console.error('Email service error (password change confirmation):', error.message);
    return false;
  }
}

/**
 * Generate HTML template for email verification
 */
function getVerificationEmailHTML(name, verificationLink) {
  return `
    <!DOCTYPE html>
    <html dir="rtl" lang="ar">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>تأكيد البريد الإلكتروني</title>
      <style>
        body { 
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
          margin: 0; 
          padding: 0; 
          background-color: #f5f7fa; 
          color: #2d3748;
          direction: rtl;
        }
        .container { 
          max-width: 600px; 
          margin: 0 auto; 
          background-color: #ffffff; 
          border-radius: 8px; 
          overflow: hidden; 
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }
        .header { 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
          color: #ffffff; 
          padding: 30px 20px; 
          text-align: center; 
        }
        .logo { 
          font-size: 32px; 
          font-weight: bold; 
          margin-bottom: 10px; 
        }
        .content { 
          padding: 30px; 
        }
        .greeting { 
          font-size: 18px; 
          margin-bottom: 20px; 
          color: #2d3748; 
        }
        .message { 
          font-size: 16px; 
          line-height: 1.6; 
          margin-bottom: 30px; 
          color: #4a5568; 
        }
        .button { 
          display: inline-block; 
          background-color: #4c51bf; 
          color: #ffffff; 
          padding: 15px 30px; 
          text-decoration: none; 
          border-radius: 6px; 
          font-weight: bold; 
          font-size: 16px; 
          text-align: center; 
          margin: 20px 0; 
        }
        .button:hover { 
          background-color: #434190; 
        }
        .footer { 
          background-color: #f7fafc; 
          padding: 20px; 
          text-align: center; 
          font-size: 14px; 
          color: #718096; 
          border-top: 1px solid #e2e8f0; 
        }
        .expiry-notice { 
          background-color: #fef5e7; 
          border: 1px solid #f6e05e; 
          border-radius: 4px; 
          padding: 15px; 
          margin-top: 20px; 
          font-size: 14px; 
          color: #b7791f; 
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="logo">تاجر</div>
          <p>مدير الأعمال الذكي</p>
        </div>
        
        <div class="content">
          <div class="greeting">مرحباً ${name}،</div>
          
          <div class="message">
            شكراً لك على التسجيل في تاجر! لإكمال إعداد حسابك، يرجى تأكيد عنوان بريدك الإلكتروني بالنقر على الزر أدناه.
          </div>
          
          <div style="text-align: center;">
            <a href="${verificationLink}" class="button">تأكيد البريد الإلكتروني</a>
          </div>
          
          <div class="expiry-notice">
            <strong>ملاحظة:</strong> هذا الرابط صالح لمدة 24 ساعة فقط من وقت إرسال هذه الرسالة.
          </div>
          
          <div class="message" style="margin-top: 30px; font-size: 14px;">
            إذا لم تقم بإنشاء حساب في تاجر، يمكنك تجاهل هذه الرسالة بأمان.
          </div>
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

/**
 * Generate HTML template for password reset
 */
function getPasswordResetEmailHTML(name, resetLink) {
  return `
    <!DOCTYPE html>
    <html dir="rtl" lang="ar">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>إعادة تعيين كلمة المرور</title>
      <style>
        body { 
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
          margin: 0; 
          padding: 0; 
          background-color: #f5f7fa; 
          color: #2d3748;
          direction: rtl;
        }
        .container { 
          max-width: 600px; 
          margin: 0 auto; 
          background-color: #ffffff; 
          border-radius: 8px; 
          overflow: hidden; 
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }
        .header { 
          background: linear-gradient(135deg, #e53e3e 0%, #c53030 100%); 
          color: #ffffff; 
          padding: 30px 20px; 
          text-align: center; 
        }
        .logo { 
          font-size: 32px; 
          font-weight: bold; 
          margin-bottom: 10px; 
        }
        .content { 
          padding: 30px; 
        }
        .greeting { 
          font-size: 18px; 
          margin-bottom: 20px; 
          color: #2d3748; 
        }
        .message { 
          font-size: 16px; 
          line-height: 1.6; 
          margin-bottom: 30px; 
          color: #4a5568; 
        }
        .button { 
          display: inline-block; 
          background-color: #e53e3e; 
          color: #ffffff; 
          padding: 15px 30px; 
          text-decoration: none; 
          border-radius: 6px; 
          font-weight: bold; 
          font-size: 16px; 
          text-align: center; 
          margin: 20px 0; 
        }
        .button:hover { 
          background-color: #c53030; 
        }
        .footer { 
          background-color: #f7fafc; 
          padding: 20px; 
          text-align: center; 
          font-size: 14px; 
          color: #718096; 
          border-top: 1px solid #e2e8f0; 
        }
        .expiry-notice { 
          background-color: #fed7d7; 
          border: 1px solid #fc8181; 
          border-radius: 4px; 
          padding: 15px; 
          margin-top: 20px; 
          font-size: 14px; 
          color: #c53030; 
        }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="logo">تاجر</div>
          <p>إعادة تعيين كلمة المرور</p>
        </div>
        
        <div class="content">
          <div class="greeting">مرحباً ${name}،</div>
          
          <div class="message">
            تلقينا طلباً لإعادة تعيين كلمة المرور لحسابك في تاجر. انقر على الزر أدناه لإنشاء كلمة مرور جديدة.
          </div>
          
          <div style="text-align: center;">
            <a href="${resetLink}" class="button">إعادة تعيين كلمة المرور</a>
          </div>
          
          <div class="expiry-notice">
            <strong>تنبيه أمني:</strong> هذا الرابط صالح لمدة ساعة واحدة فقط من وقت إرسال هذه الرسالة.
          </div>
          
          <div class="message" style="margin-top: 30px; font-size: 14px;">
            إذا لم تطلب إعادة تعيين كلمة المرور، يمكنك تجاهل هذه الرسالة بأمان. كلمة مرورك الحالية لن تتغير.
          </div>
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

/**
 * Generate HTML template for password change confirmation
 */
function getPasswordChangeConfirmationHTML(name) {
  return `
    <!DOCTYPE html>
    <html dir="rtl" lang="ar">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>تم تغيير كلمة المرور</title>
      <style>
        body { 
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
          margin: 0; 
          padding: 0; 
          background-color: #f5f7fa; 
          color: #2d3748;
          direction: rtl;
        }
        .container { 
          max-width: 600px; 
          margin: 0 auto; 
          background-color: #ffffff; 
          border-radius: 8px; 
          overflow: hidden; 
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        }
        .header { 
          background: linear-gradient(135deg, #38a169 0%, #2f855a 100%); 
          color: #ffffff; 
          padding: 30px 20px; 
          text-align: center; 
        }
        .logo { 
          font-size: 32px; 
          font-weight: bold; 
          margin-bottom: 10px; 
        }
        .content { 
          padding: 30px; 
        }
        .greeting { 
          font-size: 18px; 
          margin-bottom: 20px; 
          color: #2d3748; 
        }
        .message { 
          font-size: 16px; 
          line-height: 1.6; 
          margin-bottom: 30px; 
          color: #4a5568; 
        }
        .footer { 
          background-color: #f7fafc; 
          padding: 20px; 
          text-align: center; 
          font-size: 14px; 
          color: #718096; 
          border-top: 1px solid #e2e8f0; 
        }
        .success-notice { 
          background-color: #f0fff4; 
          border: 1px solid #9ae6b4; 
          border-radius: 4px; 
          padding: 15px; 
          margin-top: 20px; 
          font-size: 14px; 
          color: #2f855a; 
        }
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
          
          <div class="message">
            تم تغيير كلمة المرور لحسابك في تاجر بنجاح. إذا قمت بهذا التغيير، فلا حاجة لاتخاذ أي إجراء إضافي.
          </div>
          
          <div class="success-notice">
            <strong>تم بنجاح:</strong> تم تغيير كلمة المرور في ${new Date().toLocaleString('ar-SA', { timeZone: 'Asia/Riyadh' })}
          </div>
          
          <div class="message" style="margin-top: 30px; font-size: 14px;">
            إذا لم تقم بتغيير كلمة المرور، يرجى الاتصال بنا فوراً لحماية حسابك.
          </div>
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