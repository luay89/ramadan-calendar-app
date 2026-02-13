/**
 * Ramadan Calendar PWA - Backend Server
 * سيرفر إدارة Push Notifications
 * 
 * @author Ramadan Calendar PWA
 * @version 1.0.0
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

const { initializeWebPush, getPublicKey } = require('./vapidKeys');
const db = require('./database');
const scheduler = require('./pushScheduler');

// ==================== إعداد Express ====================
const app = express();
const PORT = process.env.PORT || 3030;

// Middleware
app.use(cors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
    credentials: true
}));
app.use(express.json());

// خدمة الملفات الثابتة (PWA)
app.use(express.static(path.join(__dirname, '..')));

// ==================== تهيئة النظام ====================
let vapidKeys = null;

function initializeSystem() {
    console.log('═'.repeat(50));
    console.log('🌙 Ramadan Calendar PWA - Backend Server');
    console.log('═'.repeat(50));
    
    // تهيئة قاعدة البيانات
    db.initDatabase();
    
    // تهيئة VAPID
    vapidKeys = initializeWebPush();
    
    // بدء الجدولة
    scheduler.startScheduler();
    
    console.log('═'.repeat(50));
}

// ==================== API Routes ====================

/**
 * الحصول على مفتاح VAPID العام
 */
app.get('/api/vapid-public-key', (req, res) => {
    const publicKey = getPublicKey();
    
    if (!publicKey) {
        // إذا لم يكن هناك مفتاح محفوظ، استخدم المفتاح المولد
        if (vapidKeys?.publicKey) {
            return res.json({ publicKey: vapidKeys.publicKey });
        }
        return res.status(500).json({ error: 'VAPID key not configured' });
    }
    
    res.json({ publicKey });
});

/**
 * تسجيل اشتراك جديد
 */
app.post('/api/subscribe', (req, res) => {
    try {
        const { subscription, latitude, longitude, timezone } = req.body;
        
        if (!subscription || !subscription.endpoint) {
            return res.status(400).json({ error: 'Invalid subscription' });
        }
        
        // حفظ الاشتراك
        const subscriptionId = db.saveSubscription(
            subscription,
            latitude || null,
            longitude || null,
            timezone || 'Asia/Baghdad'
        );
        
        // جدولة الإشعارات إذا كان هناك موقع
        let scheduledCount = 0;
        if (latitude && longitude) {
            scheduledCount = scheduler.scheduleForSubscription(
                subscriptionId,
                latitude,
                longitude,
                timezone
            );
        }
        
        console.log(`✅ اشتراك جديد: ${subscriptionId} (${scheduledCount} إشعار مجدول)`);
        
        res.json({ 
            success: true, 
            subscriptionId,
            scheduledNotifications: scheduledCount
        });
    } catch (error) {
        console.error('❌ خطأ في التسجيل:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * إلغاء الاشتراك
 */
app.post('/api/unsubscribe', (req, res) => {
    try {
        const { endpoint } = req.body;
        
        if (!endpoint) {
            return res.status(400).json({ error: 'Endpoint required' });
        }
        
        db.deleteSubscription(endpoint);
        console.log('🗑️ تم إلغاء اشتراك');
        
        res.json({ success: true });
    } catch (error) {
        console.error('❌ خطأ في إلغاء الاشتراك:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * تحديث الموقع
 */
app.post('/api/update-location', (req, res) => {
    try {
        const { endpoint, latitude, longitude, timezone } = req.body;
        
        if (!endpoint || !latitude || !longitude) {
            return res.status(400).json({ error: 'Missing required fields' });
        }
        
        // تحديث الموقع في قاعدة البيانات
        db.updateSubscriptionLocation(endpoint, latitude, longitude);
        
        // الحصول على معرف الاشتراك
        const subscription = db.getSubscriptionByEndpoint(endpoint);
        
        if (subscription) {
            // إعادة جدولة الإشعارات
            const scheduledCount = scheduler.scheduleForSubscription(
                subscription.id,
                latitude,
                longitude,
                timezone || subscription.timezone
            );
            
            console.log(`📍 تحديث موقع: ${subscription.id} (${scheduledCount} إشعار مجدول)`);
            
            res.json({ 
                success: true, 
                scheduledNotifications: scheduledCount 
            });
        } else {
            res.status(404).json({ error: 'Subscription not found' });
        }
    } catch (error) {
        console.error('❌ خطأ في تحديث الموقع:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * الحصول على أوقات الصلاة
 */
app.get('/api/prayer-times', (req, res) => {
    try {
        const { latitude, longitude, date } = req.query;
        
        if (!latitude || !longitude) {
            return res.status(400).json({ error: 'Location required' });
        }
        
        const targetDate = date ? new Date(date) : new Date();
        const timezone = req.query.timezone || 'Asia/Baghdad';
        
        // حساب فرق التوقيت
        const timezoneOffset = getTimezoneOffset(timezone);
        
        const prayerTimes = scheduler.calculatePrayerTimes(
            parseFloat(latitude),
            parseFloat(longitude),
            timezoneOffset,
            targetDate
        );
        
        // تحويل إلى تنسيق مقروء
        const formatted = {};
        for (const [prayer, time] of Object.entries(prayerTimes)) {
            if (time) {
                formatted[prayer] = {
                    time: time.toISOString(),
                    formatted: time.toLocaleTimeString('ar-IQ', {
                        hour: '2-digit',
                        minute: '2-digit',
                        hour12: true
                    })
                };
            }
        }
        
        res.json({
            date: targetDate.toISOString().split('T')[0],
            location: { latitude, longitude },
            timezone,
            prayerTimes: formatted
        });
    } catch (error) {
        console.error('❌ خطأ في حساب الأوقات:', error);
        res.status(500).json({ error: error.message });
    }
});

/**
 * إحصائيات النظام
 */
app.get('/api/stats', (req, res) => {
    try {
        const stats = db.getStats();
        res.json(stats);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

/**
 * فحص صحة السيرفر
 */
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

// ==================== Helper Functions ====================

function getTimezoneOffset(timezone) {
    try {
        const date = new Date();
        const utc = new Date(date.toLocaleString('en-US', { timeZone: 'UTC' }));
        const tz = new Date(date.toLocaleString('en-US', { timeZone: timezone }));
        return (tz - utc) / 3600000;
    } catch {
        return 3;
    }
}

// ==================== Error Handling ====================

app.use((err, req, res, next) => {
    console.error('❌ Server Error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// ==================== بدء السيرفر ====================

initializeSystem();

app.listen(PORT, () => {
    console.log(`🚀 السيرفر يعمل على http://localhost:${PORT}`);
    console.log(`📱 PWA متاح على http://localhost:${PORT}`);
});

module.exports = app;
