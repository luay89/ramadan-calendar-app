/**
 * Push Scheduler Module
 * جدولة وإرسال إشعارات الصلاة
 * 
 * @author Ramadan Calendar PWA
 * @version 1.0.0
 */

const cron = require('node-cron');
const { sendPushNotification } = require('./vapidKeys');
const db = require('./database');

// ==================== أوقات الصلاة بالعربية ====================
const PRAYER_NAMES_AR = {
    fajr: 'الفجر',
    sunrise: 'الشروق',
    dhuhr: 'الظهر',
    asr: 'العصر',
    maghrib: 'المغرب',
    isha: 'العشاء',
    imsak: 'الإمساك'
};

// ==================== حساب أوقات الصلاة ====================

/**
 * ثوابت فلكية
 */
const DEG_TO_RAD = Math.PI / 180;
const RAD_TO_DEG = 180 / Math.PI;

/**
 * حساب رقم اليوم الجولياني
 */
function julianDay(year, month, day) {
    if (month <= 2) {
        year -= 1;
        month += 12;
    }
    const A = Math.floor(year / 100);
    const B = 2 - A + Math.floor(A / 4);
    return Math.floor(365.25 * (year + 4716)) + Math.floor(30.6001 * (month + 1)) + day + B - 1524.5;
}

/**
 * حساب موقع الشمس
 */
function sunPosition(jd) {
    const D = jd - 2451545.0;
    const g = (357.529 + 0.98560028 * D) % 360;
    const q = (280.459 + 0.98564736 * D) % 360;
    const L = (q + 1.915 * Math.sin(g * DEG_TO_RAD) + 0.020 * Math.sin(2 * g * DEG_TO_RAD)) % 360;
    const e = 23.439 - 0.00000036 * D;
    const RA = Math.atan2(Math.cos(e * DEG_TO_RAD) * Math.sin(L * DEG_TO_RAD), Math.cos(L * DEG_TO_RAD)) * RAD_TO_DEG;
    const decl = Math.asin(Math.sin(e * DEG_TO_RAD) * Math.sin(L * DEG_TO_RAD)) * RAD_TO_DEG;
    const EqT = q / 15 - ((RA < 0 ? RA + 360 : RA) / 15);
    return { declination: decl, equation: EqT };
}

/**
 * حساب وقت بناءً على زاوية الشمس
 */
function computeTime(angle, latitude, declination, equation, longitude, timezone) {
    const cosHA = (Math.sin(angle * DEG_TO_RAD) - Math.sin(latitude * DEG_TO_RAD) * Math.sin(declination * DEG_TO_RAD)) /
                  (Math.cos(latitude * DEG_TO_RAD) * Math.cos(declination * DEG_TO_RAD));
    
    if (cosHA > 1 || cosHA < -1) return null;
    
    const HA = Math.acos(cosHA) * RAD_TO_DEG;
    return (12 - HA / 15) - equation + longitude / 15 - timezone / 60 * 4;
}

/**
 * حساب وقت الظهر
 */
function computeNoon(equation, longitude, timezone) {
    return 12 - equation + longitude / 15 - timezone / 60 * 4;
}

/**
 * حساب أوقات الصلاة ليوم معين
 * @param {number} latitude - خط العرض
 * @param {number} longitude - خط الطول
 * @param {number} timezone - فرق التوقيت بالساعات
 * @param {Date} date - التاريخ
 * @returns {Object} - أوقات الصلاة
 */
function calculatePrayerTimes(latitude, longitude, timezone, date) {
    const year = date.getFullYear();
    const month = date.getMonth() + 1;
    const day = date.getDate();
    
    const jd = julianDay(year, month, day);
    const sun = sunPosition(jd);
    
    // إعدادات الجعفري/العراق
    const fajrAngle = -18; // 18 درجة تحت الأفق
    const ishaAngle = -17; // 17 درجة تحت الأفق
    const asrFactor = 1; // الشافعي
    
    // حساب الظهر
    const noon = computeNoon(sun.equation, longitude, timezone);
    
    // حساب الفجر
    const fajrHours = computeTime(fajrAngle, latitude, sun.declination, sun.equation, longitude, timezone);
    
    // حساب الشروق
    const sunriseHours = computeTime(-0.833, latitude, sun.declination, sun.equation, longitude, timezone);
    
    // حساب الغروب
    const sunsetAngle = -0.833;
    const cosHASunset = (Math.sin(sunsetAngle * DEG_TO_RAD) - Math.sin(latitude * DEG_TO_RAD) * Math.sin(sun.declination * DEG_TO_RAD)) /
                        (Math.cos(latitude * DEG_TO_RAD) * Math.cos(sun.declination * DEG_TO_RAD));
    const HASunset = Math.acos(cosHASunset) * RAD_TO_DEG;
    const sunsetHours = (12 + HASunset / 15) - sun.equation + longitude / 15 - timezone / 60 * 4;
    
    // حساب العشاء
    const ishaHours = computeTime(ishaAngle, latitude, sun.declination, sun.equation, longitude, timezone);
    const ishaTime = ishaHours !== null ? (24 - ishaHours) : (sunsetHours + 1.5);
    
    // حساب العصر (الشافعي)
    const tanShadow = Math.abs(Math.tan((latitude - sun.declination) * DEG_TO_RAD)) + asrFactor;
    const asrAngle = Math.atan(1 / tanShadow) * RAD_TO_DEG;
    const cosHAAsr = (Math.sin((90 - asrAngle) * DEG_TO_RAD) - Math.sin(latitude * DEG_TO_RAD) * Math.sin(sun.declination * DEG_TO_RAD)) /
                     (Math.cos(latitude * DEG_TO_RAD) * Math.cos(sun.declination * DEG_TO_RAD));
    const HAAsr = Math.acos(cosHAAsr) * RAD_TO_DEG;
    const asrHours = noon + HAAsr / 15;
    
    // تحويل الساعات إلى Date objects
    const toDate = (hours) => {
        if (hours === null || isNaN(hours)) return null;
        
        // تطبيع الساعة
        while (hours < 0) hours += 24;
        while (hours >= 24) hours -= 24;
        
        const h = Math.floor(hours);
        const m = Math.floor((hours - h) * 60);
        
        // بناء Date object يدوياً (مهم جداً لتجنب مشاكل التوقيت)
        return new Date(year, month - 1, day, h, m, 0, 0);
    };
    
    const fajrTime = toDate(fajrHours);
    const imsakTime = fajrTime ? new Date(fajrTime.getTime() - 10 * 60000) : null; // 10 دقائق قبل الفجر
    
    return {
        imsak: imsakTime,
        fajr: fajrTime,
        sunrise: toDate(sunriseHours),
        dhuhr: toDate(noon),
        asr: toDate(asrHours),
        maghrib: toDate(sunsetHours),
        isha: toDate(ishaTime)
    };
}

// ==================== جدولة الإشعارات ====================

/**
 * جدولة إشعارات اليوم لجميع المشتركين
 */
async function scheduleDailyNotifications() {
    console.log('📅 جدولة إشعارات اليوم...');
    
    const subscriptions = db.getActiveSubscriptions();
    
    if (subscriptions.length === 0) {
        console.log('⚠️ لا يوجد مشتركين نشطين');
        return;
    }
    
    const now = new Date();
    const notifications = [];
    
    for (const sub of subscriptions) {
        if (!sub.latitude || !sub.longitude) {
            console.log(`⚠️ اشتراك بدون موقع: ${sub.id}`);
            continue;
        }
        
        // حساب timezone offset
        const timezoneOffset = getTimezoneOffset(sub.timezone || 'Asia/Baghdad');
        
        // حساب أوقات الصلاة
        const prayerTimes = calculatePrayerTimes(
            sub.latitude,
            sub.longitude,
            timezoneOffset,
            now
        );
        
        // جدولة كل صلاة
        for (const [prayer, time] of Object.entries(prayerTimes)) {
            if (!time) continue;
            
            // إشعار قبل دقيقة من وقت الصلاة
            const notifyTime = new Date(time.getTime() - 60000);
            
            // تخطي الأوقات الماضية
            if (notifyTime <= now) continue;
            
            notifications.push({
                subscriptionId: sub.id,
                prayerName: prayer,
                scheduledTime: notifyTime
            });
        }
    }
    
    if (notifications.length > 0) {
        db.scheduleNotifications(notifications);
        console.log(`✅ تم جدولة ${notifications.length} إشعار`);
    }
}

/**
 * الحصول على فرق التوقيت بالساعات
 */
function getTimezoneOffset(timezone) {
    try {
        const date = new Date();
        const utc = new Date(date.toLocaleString('en-US', { timeZone: 'UTC' }));
        const tz = new Date(date.toLocaleString('en-US', { timeZone: timezone }));
        return (tz - utc) / 3600000;
    } catch {
        return 3; // افتراضي: بغداد +3
    }
}

/**
 * معالجة الإشعارات المستحقة
 */
async function processDueNotifications() {
    const dueNotifications = db.getDueNotifications();
    
    if (dueNotifications.length === 0) return;
    
    console.log(`📤 معالجة ${dueNotifications.length} إشعار...`);
    
    for (const notif of dueNotifications) {
        const subscription = {
            endpoint: notif.endpoint,
            keys: {
                p256dh: notif.keys_p256dh,
                auth: notif.keys_auth
            }
        };
        
        const prayerNameAr = PRAYER_NAMES_AR[notif.prayer_name] || notif.prayer_name;
        
        const payload = {
            title: `🕌 حان وقت صلاة ${prayerNameAr}`,
            body: `حان الآن وقت صلاة ${prayerNameAr}`,
            icon: '/assets/icons/icon-192x192.png',
            badge: '/assets/icons/icon-72x72.png',
            tag: `prayer-${notif.prayer_name}`,
            requireInteraction: true,
            vibrate: [200, 100, 200],
            data: {
                prayer: notif.prayer_name,
                timestamp: Date.now(),
                playAdhan: true
            },
            actions: [
                { action: 'play-adhan', title: '🎵 تشغيل الأذان' },
                { action: 'dismiss', title: 'تجاهل' }
            ]
        };
        
        const result = await sendPushNotification(subscription, payload);
        
        if (result.success) {
            db.markNotificationSent(notif.id, true);
            db.logNotification(notif.subscription_id, notif.prayer_name, 'sent');
            console.log(`✅ تم إرسال إشعار ${prayerNameAr}`);
        } else {
            db.markNotificationSent(notif.id, false, result.error);
            db.logNotification(notif.subscription_id, notif.prayer_name, 'failed', result.error);
            
            if (result.expired) {
                db.deactivateSubscription(notif.subscription_id);
                console.log(`⚠️ تم تعطيل اشتراك منتهي: ${notif.subscription_id}`);
            }
        }
    }
}

/**
 * جدولة إشعارات لاشتراك معين
 * @param {number} subscriptionId
 * @param {number} latitude
 * @param {number} longitude
 * @param {string} timezone
 */
function scheduleForSubscription(subscriptionId, latitude, longitude, timezone) {
    // حذف الإشعارات القديمة غير المرسلة
    db.deleteSubscriptionNotifications(subscriptionId);
    
    const now = new Date();
    const notifications = [];
    const timezoneOffset = getTimezoneOffset(timezone || 'Asia/Baghdad');
    
    // جدولة اليوم والغد
    for (let dayOffset = 0; dayOffset < 2; dayOffset++) {
        const date = new Date(now);
        date.setDate(date.getDate() + dayOffset);
        
        const prayerTimes = calculatePrayerTimes(latitude, longitude, timezoneOffset, date);
        
        for (const [prayer, time] of Object.entries(prayerTimes)) {
            if (!time) continue;
            
            const notifyTime = new Date(time.getTime() - 60000);
            
            if (notifyTime <= now) continue;
            
            notifications.push({
                subscriptionId,
                prayerName: prayer,
                scheduledTime: notifyTime
            });
        }
    }
    
    if (notifications.length > 0) {
        db.scheduleNotifications(notifications);
    }
    
    return notifications.length;
}

// ==================== Cron Jobs ====================

/**
 * بدء الجدولة التلقائية
 */
function startScheduler() {
    console.log('🚀 بدء نظام الجدولة...');
    
    // فحص الإشعارات المستحقة كل دقيقة
    cron.schedule('* * * * *', () => {
        processDueNotifications().catch(err => {
            console.error('❌ خطأ في معالجة الإشعارات:', err);
        });
    });
    
    // إعادة جدولة يومية عند منتصف الليل
    cron.schedule('0 0 * * *', () => {
        console.log('🌙 منتصف الليل - إعادة الجدولة...');
        scheduleDailyNotifications().catch(err => {
            console.error('❌ خطأ في الجدولة اليومية:', err);
        });
    });
    
    // تنظيف الإشعارات القديمة كل يوم
    cron.schedule('0 3 * * *', () => {
        console.log('🧹 تنظيف الإشعارات القديمة...');
        db.cleanupOldNotifications(7);
    });
    
    // جدولة أولية
    setTimeout(() => {
        scheduleDailyNotifications().catch(err => {
            console.error('❌ خطأ في الجدولة الأولية:', err);
        });
    }, 5000);
    
    console.log('✅ نظام الجدولة يعمل');
}

module.exports = {
    calculatePrayerTimes,
    scheduleDailyNotifications,
    processDueNotifications,
    scheduleForSubscription,
    startScheduler,
    PRAYER_NAMES_AR
};
