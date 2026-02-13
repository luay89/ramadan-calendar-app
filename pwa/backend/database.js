/**
 * Database Module - SQLite
 * قاعدة بيانات الاشتراكات والجدولة
 * 
 * @author Ramadan Calendar PWA
 * @version 1.0.0
 */

const Database = require('better-sqlite3');
const path = require('path');

// مسار قاعدة البيانات
const DB_PATH = process.env.DB_PATH || path.join(__dirname, 'data', 'ramadan.db');

let db = null;

/**
 * تهيئة قاعدة البيانات
 */
function initDatabase() {
    // إنشاء مجلد البيانات إذا لم يكن موجوداً
    const fs = require('fs');
    const dataDir = path.dirname(DB_PATH);
    if (!fs.existsSync(dataDir)) {
        fs.mkdirSync(dataDir, { recursive: true });
    }

    db = new Database(DB_PATH);
    db.pragma('journal_mode = WAL');
    
    // إنشاء الجداول
    createTables();
    
    console.log('✅ تم تهيئة قاعدة البيانات:', DB_PATH);
    return db;
}

/**
 * إنشاء الجداول
 */
function createTables() {
    // جدول الاشتراكات
    db.exec(`
        CREATE TABLE IF NOT EXISTS subscriptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            endpoint TEXT UNIQUE NOT NULL,
            keys_p256dh TEXT NOT NULL,
            keys_auth TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            timezone TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            is_active INTEGER DEFAULT 1
        )
    `);

    // جدول جدولة الإشعارات
    db.exec(`
        CREATE TABLE IF NOT EXISTS scheduled_notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subscription_id INTEGER NOT NULL,
            prayer_name TEXT NOT NULL,
            scheduled_time DATETIME NOT NULL,
            sent INTEGER DEFAULT 0,
            sent_at DATETIME,
            error TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE,
            UNIQUE(subscription_id, prayer_name, scheduled_time)
        )
    `);

    // جدول سجل الإشعارات
    db.exec(`
        CREATE TABLE IF NOT EXISTS notification_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            subscription_id INTEGER NOT NULL,
            prayer_name TEXT NOT NULL,
            status TEXT NOT NULL,
            error TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    `);

    // فهارس للأداء
    db.exec(`
        CREATE INDEX IF NOT EXISTS idx_scheduled_time ON scheduled_notifications(scheduled_time);
        CREATE INDEX IF NOT EXISTS idx_subscription_active ON subscriptions(is_active);
        CREATE INDEX IF NOT EXISTS idx_scheduled_sent ON scheduled_notifications(sent, scheduled_time);
    `);
}

// ==================== إدارة الاشتراكات ====================

/**
 * حفظ أو تحديث اشتراك
 * @param {Object} subscription - بيانات الاشتراك
 * @param {number} latitude - خط العرض
 * @param {number} longitude - خط الطول
 * @param {string} timezone - المنطقة الزمنية
 * @returns {number} - معرف الاشتراك
 */
function saveSubscription(subscription, latitude, longitude, timezone) {
    const stmt = db.prepare(`
        INSERT INTO subscriptions (endpoint, keys_p256dh, keys_auth, latitude, longitude, timezone)
        VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(endpoint) DO UPDATE SET
            keys_p256dh = excluded.keys_p256dh,
            keys_auth = excluded.keys_auth,
            latitude = excluded.latitude,
            longitude = excluded.longitude,
            timezone = excluded.timezone,
            updated_at = CURRENT_TIMESTAMP,
            is_active = 1
    `);

    const result = stmt.run(
        subscription.endpoint,
        subscription.keys.p256dh,
        subscription.keys.auth,
        latitude,
        longitude,
        timezone
    );

    return result.lastInsertRowid || getSubscriptionByEndpoint(subscription.endpoint)?.id;
}

/**
 * الحصول على اشتراك بواسطة Endpoint
 * @param {string} endpoint
 * @returns {Object|null}
 */
function getSubscriptionByEndpoint(endpoint) {
    const stmt = db.prepare('SELECT * FROM subscriptions WHERE endpoint = ?');
    return stmt.get(endpoint);
}

/**
 * الحصول على جميع الاشتراكات النشطة
 * @returns {Array}
 */
function getActiveSubscriptions() {
    const stmt = db.prepare('SELECT * FROM subscriptions WHERE is_active = 1');
    return stmt.all();
}

/**
 * تعطيل اشتراك (عند فشل الإرسال)
 * @param {number} subscriptionId
 */
function deactivateSubscription(subscriptionId) {
    const stmt = db.prepare('UPDATE subscriptions SET is_active = 0 WHERE id = ?');
    stmt.run(subscriptionId);
}

/**
 * حذف اشتراك
 * @param {string} endpoint
 */
function deleteSubscription(endpoint) {
    const stmt = db.prepare('DELETE FROM subscriptions WHERE endpoint = ?');
    stmt.run(endpoint);
}

/**
 * تحديث موقع الاشتراك
 * @param {string} endpoint
 * @param {number} latitude
 * @param {number} longitude
 */
function updateSubscriptionLocation(endpoint, latitude, longitude) {
    const stmt = db.prepare(`
        UPDATE subscriptions 
        SET latitude = ?, longitude = ?, updated_at = CURRENT_TIMESTAMP
        WHERE endpoint = ?
    `);
    stmt.run(latitude, longitude, endpoint);
}

// ==================== إدارة جدولة الإشعارات ====================

/**
 * جدولة إشعار صلاة
 * @param {number} subscriptionId
 * @param {string} prayerName
 * @param {Date} scheduledTime
 */
function scheduleNotification(subscriptionId, prayerName, scheduledTime) {
    const stmt = db.prepare(`
        INSERT OR REPLACE INTO scheduled_notifications 
        (subscription_id, prayer_name, scheduled_time, sent)
        VALUES (?, ?, ?, 0)
    `);
    stmt.run(subscriptionId, prayerName, scheduledTime.toISOString());
}

/**
 * جدولة مجموعة إشعارات
 * @param {Array} notifications - [{subscriptionId, prayerName, scheduledTime}]
 */
function scheduleNotifications(notifications) {
    const stmt = db.prepare(`
        INSERT OR REPLACE INTO scheduled_notifications 
        (subscription_id, prayer_name, scheduled_time, sent)
        VALUES (?, ?, ?, 0)
    `);

    const insertMany = db.transaction((items) => {
        for (const item of items) {
            stmt.run(item.subscriptionId, item.prayerName, item.scheduledTime.toISOString());
        }
    });

    insertMany(notifications);
}

/**
 * الحصول على الإشعارات المستحقة
 * @returns {Array}
 */
function getDueNotifications() {
    const now = new Date().toISOString();
    const stmt = db.prepare(`
        SELECT sn.*, s.endpoint, s.keys_p256dh, s.keys_auth
        FROM scheduled_notifications sn
        JOIN subscriptions s ON sn.subscription_id = s.id
        WHERE sn.sent = 0 
          AND sn.scheduled_time <= ?
          AND s.is_active = 1
        ORDER BY sn.scheduled_time ASC
        LIMIT 100
    `);
    return stmt.all(now);
}

/**
 * تحديث حالة الإشعار بعد الإرسال
 * @param {number} notificationId
 * @param {boolean} success
 * @param {string} error
 */
function markNotificationSent(notificationId, success, error = null) {
    const stmt = db.prepare(`
        UPDATE scheduled_notifications 
        SET sent = 1, sent_at = CURRENT_TIMESTAMP, error = ?
        WHERE id = ?
    `);
    stmt.run(error, notificationId);
}

/**
 * حذف الإشعارات القديمة المرسلة
 * @param {number} daysOld - عدد الأيام
 */
function cleanupOldNotifications(daysOld = 7) {
    const stmt = db.prepare(`
        DELETE FROM scheduled_notifications 
        WHERE sent = 1 
          AND sent_at < datetime('now', ?)
    `);
    stmt.run(`-${daysOld} days`);
}

/**
 * حذف جميع إشعارات اشتراك معين
 * @param {number} subscriptionId
 */
function deleteSubscriptionNotifications(subscriptionId) {
    const stmt = db.prepare(`
        DELETE FROM scheduled_notifications 
        WHERE subscription_id = ? AND sent = 0
    `);
    stmt.run(subscriptionId);
}

/**
 * الحصول على إحصائيات
 * @returns {Object}
 */
function getStats() {
    const subscriptionsCount = db.prepare('SELECT COUNT(*) as count FROM subscriptions WHERE is_active = 1').get();
    const pendingNotifications = db.prepare('SELECT COUNT(*) as count FROM scheduled_notifications WHERE sent = 0').get();
    const sentToday = db.prepare(`
        SELECT COUNT(*) as count FROM scheduled_notifications 
        WHERE sent = 1 AND DATE(sent_at) = DATE('now')
    `).get();

    return {
        activeSubscriptions: subscriptionsCount.count,
        pendingNotifications: pendingNotifications.count,
        sentToday: sentToday.count
    };
}

// ==================== سجل الإشعارات ====================

/**
 * تسجيل إشعار
 * @param {number} subscriptionId
 * @param {string} prayerName
 * @param {string} status
 * @param {string} error
 */
function logNotification(subscriptionId, prayerName, status, error = null) {
    const stmt = db.prepare(`
        INSERT INTO notification_log (subscription_id, prayer_name, status, error)
        VALUES (?, ?, ?, ?)
    `);
    stmt.run(subscriptionId, prayerName, status, error);
}

module.exports = {
    initDatabase,
    saveSubscription,
    getSubscriptionByEndpoint,
    getActiveSubscriptions,
    deactivateSubscription,
    deleteSubscription,
    updateSubscriptionLocation,
    scheduleNotification,
    scheduleNotifications,
    getDueNotifications,
    markNotificationSent,
    cleanupOldNotifications,
    deleteSubscriptionNotifications,
    getStats,
    logNotification
};
