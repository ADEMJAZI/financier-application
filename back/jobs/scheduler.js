const cron = require('node-cron');
const CustomerDebt = require('../models/CustomerDebt');
const CashRegister = require('../models/CashRegister');
const Business = require('../models/Business');
const User = require('../models/User');
const { sendPushNotification } = require('../utils/notificationService');

const initScheduler = () => {
  // 1. Daily Debts Reminder (Runs at 8:00 AM server time)
  cron.schedule('0 8 * * *', async () => {
    console.log('[Scheduler] Running Daily Debts Reminder Job...');
    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      
      const twoDaysFromNow = new Date(today);
      twoDaysFromNow.setDate(today.getDate() + 2);

      // Find all unpaid or partially paid debts that are due in <= 2 days or overdue
      const debts = await CustomerDebt.find({
        status: { $in: ['unpaid', 'partial'] },
        dueDate: { $lte: twoDaysFromNow }
      }).populate('business');

      // Group debts by business owner
      const alertsByOwner = {};

      for (const debt of debts) {
        if (!debt.business) continue;
        
        const ownerId = debt.business.owner.toString();
        if (!alertsByOwner[ownerId]) {
          alertsByOwner[ownerId] = { total: 0, overdue: 0 };
        }
        
        alertsByOwner[ownerId].total += 1;
        
        if (new Date(debt.dueDate) < today) {
          alertsByOwner[ownerId].overdue += 1;
        }
      }

      // Send notifications
      let sentCount = 0;
      for (const [ownerId, stats] of Object.entries(alertsByOwner)) {
        let body = `لديك ${stats.total} ديون تستحق خلال يومين.`;
        if (stats.overdue > 0) {
          body = `لديك ${stats.total} ديون تستحق خلال يومين، ومنها ${stats.overdue} متأخرة.`;
        }

        await sendPushNotification(ownerId, {
          title: 'ديون تستحق قريباً',
          body,
          data: { type: 'DEBTS_REMINDER' }
        });
        sentCount++;
      }
      
      console.log(`[Scheduler] Daily Debts Reminder Job completed. Sent ${sentCount} notifications.`);
    } catch (error) {
      console.error('[Scheduler] Error in Daily Debts Reminder Job:', error);
    }
  });

  // 2. Daily Cash Register Reminder (Runs at 9:00 AM server time)
  cron.schedule('0 9 * * *', async () => {
    console.log('[Scheduler] Running Daily Cash Register Reminder Job...');
    try {
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(today.getDate() + 1);

      // We need to check all active businesses
      const businesses = await Business.find({});
      let sentCount = 0;

      for (const business of businesses) {
        // Check if there is an open cash register for today
        const openRegister = await CashRegister.findOne({
          business: business._id,
          status: 'open',
          openedAt: { $gte: today, $lt: tomorrow }
        });

        if (!openRegister) {
          await sendPushNotification(business.owner.toString(), {
            title: 'تذكير: افتح الصندوق',
            body: 'لم تفتح صندوق اليوم بعد لتسجيل معاملاتك.',
            data: { type: 'CASH_REGISTER_REMINDER' }
          });
          sentCount++;
        }
      }

      console.log(`[Scheduler] Daily Cash Register Reminder Job completed. Sent ${sentCount} notifications.`);
    } catch (error) {
      console.error('[Scheduler] Error in Daily Cash Register Reminder Job:', error);
    }
  });
  
  console.log('✅ Background jobs scheduled (Debts at 8:00 AM, Cash Register at 9:00 AM).');
};

module.exports = {
  initScheduler
};
