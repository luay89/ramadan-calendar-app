/**
 * VAPID Keys Management
 * مفاتيح التشفير للـ Web Push
 * 
 * @author Ramadan Calendar PWA
 * @version 1.0.0
 */

require('dotenv').config();
const webpush = require('web-push');

// ==================== VAPID Keys ====================
// يجب توليد هذه المفاتيح مرة واحدة وحفظها في .env
// node -e "const webpush = require('web-push'); const keys = webpush.generateVAPIDKeys(); console.log(JSON.stringify(keys, null, 2));"

const VAPID_SUBJECT = process.env.VAPID_SUBJECT || 'mailto:admin@ramadan-calendar.app';
const VAPID_PUBLIC_KEY = process.env.VAPID_PUBLIC_KEY;
const VAPID_PRIVATE_KEY = process.env.VAPID_PRIVATE_KEY;

/**
 * توليد مفاتيح VAPID جديدة
 * @returns {Object} - المفاتيح العامة والخاصة
 */
function generateKeys() {
    const keys = webpush.generateVAPIDKeys();
    console.log('='.repeat(60));
    console.log('تم توليد مفاتيح VAPID جديدة!');
    console.log('قم بنسخها إلى ملف .env');
    console.log('='.repeat(60));
    console.log(`VAPID_PUBLIC_KEY=${keys.publicKey}`);
    console.log(`VAPID_PRIVATE_KEY=${keys.privateKey}`);
    console.log('='.repeat(60));
    return keys;
}

/**
 * تهيئة web-push مع المفاتيح
 */
function initializeWebPush() {
    if (!VAPID_PUBLIC_KEY || !VAPID_PRIVATE_KEY) {
        console.error('⚠️ VAPID keys غير موجودة! قم بتوليدها وإضافتها لملف .env');
        const keys = generateKeys();
        // استخدم المفاتيح المولدة للجلسة الحالية
        webpush.setVapidDetails(VAPID_SUBJECT, keys.publicKey, keys.privateKey);
        return keys;
    }
    
    webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);
    console.log('✅ تم تهيئة VAPID keys');
    return { publicKey: VAPID_PUBLIC_KEY, privateKey: VAPID_PRIVATE_KEY };
}

/**
 * الحصول على المفتاح العام للاستخدام في Frontend
 * @returns {string}
 */
function getPublicKey() {
    return VAPID_PUBLIC_KEY || null;
}

/**
 * إرسال إشعار push
 * @param {Object} subscription - الاشتراك
 * @param {Object} payload - محتوى الإشعار
 * @returns {Promise}
 */
async function sendPushNotification(subscription, payload) {
    try {
        const result = await webpush.sendNotification(
            subscription,
            JSON.stringify(payload),
            {
                TTL: 86400, // 24 ساعة
                urgency: 'high',
                topic: 'prayer-notification'
            }
        );
        return { success: true, result };
    } catch (error) {
        console.error('❌ فشل إرسال Push:', error.message);
        
        // إذا كان الاشتراك منتهي أو غير صالح
        if (error.statusCode === 410 || error.statusCode === 404) {
            return { success: false, expired: true, error: error.message };
        }
        
        return { success: false, expired: false, error: error.message };
    }
}

module.exports = {
    generateKeys,
    initializeWebPush,
    getPublicKey,
    sendPushNotification,
    webpush
};
