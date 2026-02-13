/**
 * وحدة قاعدة البيانات IndexedDB
 * لتخزين البيانات محلياً للعمل أوفلاين
 * 
 * @author Ramadan Calendar PWA
 * @version 1.0.0
 */

const DB_NAME = 'RamadanCalendarDB';
const DB_VERSION = 1;

// أسماء المخازن
const STORES = {
    SETTINGS: 'settings',
    PRAYER_TIMES: 'prayerTimes',
    NOTIFICATIONS: 'notifications',
    LOCATION: 'location'
};

/**
 * فئة إدارة قاعدة البيانات
 */
class Database {
    constructor() {
        this.db = null;
        this.isReady = false;
    }

    /**
     * تهيئة قاعدة البيانات
     * @returns {Promise<IDBDatabase>}
     */
    async init() {
        if (this.db && this.isReady) {
            return this.db;
        }

        return new Promise((resolve, reject) => {
            const request = indexedDB.open(DB_NAME, DB_VERSION);

            request.onerror = (event) => {
                console.error('فشل في فتح قاعدة البيانات:', event.target.error);
                reject(event.target.error);
            };

            request.onsuccess = (event) => {
                this.db = event.target.result;
                this.isReady = true;
                console.log('تم تهيئة قاعدة البيانات بنجاح');
                resolve(this.db);
            };

            request.onupgradeneeded = (event) => {
                const db = event.target.result;
                
                // إنشاء مخزن الإعدادات
                if (!db.objectStoreNames.contains(STORES.SETTINGS)) {
                    db.createObjectStore(STORES.SETTINGS, { keyPath: 'key' });
                }

                // إنشاء مخزن أوقات الصلاة
                if (!db.objectStoreNames.contains(STORES.PRAYER_TIMES)) {
                    const prayerStore = db.createObjectStore(STORES.PRAYER_TIMES, { keyPath: 'id' });
                    prayerStore.createIndex('date', 'date', { unique: false });
                }

                // إنشاء مخزن الإشعارات
                if (!db.objectStoreNames.contains(STORES.NOTIFICATIONS)) {
                    const notifStore = db.createObjectStore(STORES.NOTIFICATIONS, { keyPath: 'id' });
                    notifStore.createIndex('scheduledTime', 'scheduledTime', { unique: false });
                    notifStore.createIndex('prayerKey', 'prayerKey', { unique: false });
                }

                // إنشاء مخزن الموقع
                if (!db.objectStoreNames.contains(STORES.LOCATION)) {
                    db.createObjectStore(STORES.LOCATION, { keyPath: 'id' });
                }

                console.log('تم إنشاء هيكل قاعدة البيانات');
            };
        });
    }

    /**
     * التأكد من جاهزية قاعدة البيانات
     */
    async ensureReady() {
        if (!this.db || !this.isReady) {
            await this.init();
        }
    }

    // ==================== إدارة الإعدادات ====================

    /**
     * حفظ إعداد
     * @param {string} key - مفتاح الإعداد
     * @param {*} value - قيمة الإعداد
     */
    async setSetting(key, value) {
        await this.ensureReady();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([STORES.SETTINGS], 'readwrite');
            const store = transaction.objectStore(STORES.SETTINGS);
            
            const request = store.put({ key, value, updatedAt: Date.now() });
            
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    }

    /**
     * قراءة إعداد
     * @param {string} key - مفتاح الإعداد
     * @param {*} defaultValue - القيمة الافتراضية
     * @returns {Promise<*>}
     */
    async getSetting(key, defaultValue = null) {
        await this.ensureReady();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([STORES.SETTINGS], 'readonly');
            const store = transaction.objectStore(STORES.SETTINGS);
            const request = store.get(key);
            
            request.onsuccess = () => {
                resolve(request.result ? request.result.value : defaultValue);
            };
            request.onerror = () => reject(request.error);
        });
    }

    /**
     * قراءة جميع الإعدادات
     * @returns {Promise<Object>}
     */
    async getAllSettings() {
        await this.ensureReady();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([STORES.SETTINGS], 'readonly');
            const store = transaction.objectStore(STORES.SETTINGS);
            const request = store.getAll();
            
            request.onsuccess = () => {
                const settings = {};
                request.result.forEach(item => {
                    settings[item.key] = item.value;
                });
                resolve(settings);
            };
            request.onerror = () => reject(request.error);
        });
    }

    // ==================== إدارة الموقع ====================

    /**
     * حفظ الموقع الجغرافي
     * @param {Object} location - {latitude, longitude, city, country}
     */
    async saveLocation(location) {
        await this.ensureReady();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([STORES.LOCATION], 'readwrite');
            const store = transaction.objectStore(STORES.LOCATION);
            
            const data = {
                id: 'current',
                ...location,
                updatedAt: Date.now()
            };
            
            const request = store.put(data);
            
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    }

    /**
     * قراءة الموقع المحفوظ
     * @returns {Promise<Object|null>}
     */
    async getLocation() {
        await this.ensureReady();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([STORES.LOCATION], 'readonly');
            const store = transaction.objectStore(STORES.LOCATION);
            const request = store.get('current');
            
            request.onsuccess = () => resolve(request.result || null);
            request.onerror = () => reject(request.error);
        });
    }

    // ==================== إدارة أوقات الصلاة ====================

    /**
     * حفظ أوقات الصلاة ليوم معين
     * @param {Date} date - التاريخ
     * @param {Object} times - أوقات الصلاة
     */
    async savePrayerTimes(date, times) {
        await this.ensureReady();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([STORES.PRAYER_TIMES], 'readwrite');
            const store = transaction.objectStore(STORES.PRAYER_TIMES);
            
            // إنشاء مفتاح فريد من التاريخ
            const dateKey = this._dateToKey(date);
            
            // تحويل أوقات Date إلى timestamps للتخزين
            const timesData = {};
            for (const [key, value] of Object.entries(times)) {
                timesData[key] = value instanceof Date ? value.getTime() : value;
            }
            
            const data = {
                id: dateKey,
                date: dateKey,
                times: timesData,
                savedAt: Date.now()
            };
            
            const request = store.put(data);
            
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    }

    /**
     * قراءة أوقات الصلاة ليوم معين
     * @param {Date} date - التاريخ
     * @returns {Promise<Object|null>}
     */
    async getPrayerTimes(date) {
        await this.ensureReady();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([STORES.PRAYER_TIMES], 'readonly');
            const store = transaction.objectStore(STORES.PRAYER_TIMES);
            const dateKey = this._dateToKey(date);
            const request = store.get(dateKey);
            
            request.onsuccess = () => {
                if (request.result) {
                    // تحويل timestamps إلى Date objects
                    const times = {};
                    for (const [key, value] of Object.entries(request.result.times)) {
                        times[key] = new Date(value);
                    }
                    resolve(times);
                } else {
                    resolve(null);
                }
            };
            request.onerror = () => reject(request.error);
        });
    }

    /**
     * حفظ أوقات الصلاة لعدة أيام
     * @param {Array} daysData - مصفوفة من {date, times}
     */
    async saveBulkPrayerTimes(daysData) {
        await this.ensureReady();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([STORES.PRAYER_TIMES], 'readwrite');
            const store = transaction.objectStore(STORES.PRAYER_TIMES);
            
            daysData.forEach(({ date, times }) => {
                const dateKey = this._dateToKey(date);
                
                const timesData = {};
                for (const [key, value] of Object.entries(times)) {
                    timesData[key] = value instanceof Date ? value.getTime() : value;
                }
                
                store.put({
                    id: dateKey,
                    date: dateKey,
                    times: timesData,
                    savedAt: Date.now()
                });
            });
            
            transaction.oncomplete = () => resolve(true);
            transaction.onerror = () => reject(transaction.error);
        });
    }

    // ==================== إدارة الإشعارات ====================

    /**
     * حفظ إشعار مجدول
     * @param {Object} notification - بيانات الإشعار
     */
    async saveNotification(notification) {
        await this.ensureReady();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([STORES.NOTIFICATIONS], 'readwrite');
            const store = transaction.objectStore(STORES.NOTIFICATIONS);
            
            const data = {
                id: notification.id || `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
                prayerKey: notification.prayerKey,
                prayerName: notification.prayerName,
                scheduledTime: notification.scheduledTime instanceof Date ? 
                    notification.scheduledTime.getTime() : notification.scheduledTime,
                sent: notification.sent || false,
                createdAt: Date.now()
            };
            
            const request = store.put(data);
            
            request.onsuccess = () => resolve(data.id);
            request.onerror = () => reject(request.error);
        });
    }

    /**
     * قراءة الإشعارات المجدولة غير المرسلة
     * @returns {Promise<Array>}
     */
    async getPendingNotifications() {
        await this.ensureReady();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([STORES.NOTIFICATIONS], 'readonly');
            const store = transaction.objectStore(STORES.NOTIFICATIONS);
            const request = store.getAll();
            
            request.onsuccess = () => {
                const pending = request.result
                    .filter(n => !n.sent)
                    .map(n => ({
                        ...n,
                        scheduledTime: new Date(n.scheduledTime)
                    }))
                    .sort((a, b) => a.scheduledTime - b.scheduledTime);
                resolve(pending);
            };
            request.onerror = () => reject(request.error);
        });
    }

    /**
     * تحديث حالة الإشعار إلى مرسل
     * @param {string} id - معرف الإشعار
     */
    async markNotificationSent(id) {
        await this.ensureReady();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([STORES.NOTIFICATIONS], 'readwrite');
            const store = transaction.objectStore(STORES.NOTIFICATIONS);
            
            const getRequest = store.get(id);
            
            getRequest.onsuccess = () => {
                if (getRequest.result) {
                    getRequest.result.sent = true;
                    getRequest.result.sentAt = Date.now();
                    const putRequest = store.put(getRequest.result);
                    putRequest.onsuccess = () => resolve(true);
                    putRequest.onerror = () => reject(putRequest.error);
                } else {
                    resolve(false);
                }
            };
            getRequest.onerror = () => reject(getRequest.error);
        });
    }

    /**
     * حذف الإشعارات القديمة
     * @param {number} beforeTime - حذف الإشعارات قبل هذا الوقت
     */
    async cleanOldNotifications(beforeTime = Date.now() - 86400000) {
        await this.ensureReady();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([STORES.NOTIFICATIONS], 'readwrite');
            const store = transaction.objectStore(STORES.NOTIFICATIONS);
            const request = store.getAll();
            
            request.onsuccess = () => {
                const toDelete = request.result
                    .filter(n => n.scheduledTime < beforeTime);
                
                toDelete.forEach(n => store.delete(n.id));
                
                transaction.oncomplete = () => resolve(toDelete.length);
            };
            request.onerror = () => reject(request.error);
        });
    }

    /**
     * حذف جميع الإشعارات
     */
    async clearAllNotifications() {
        await this.ensureReady();
        
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([STORES.NOTIFICATIONS], 'readwrite');
            const store = transaction.objectStore(STORES.NOTIFICATIONS);
            const request = store.clear();
            
            request.onsuccess = () => resolve(true);
            request.onerror = () => reject(request.error);
        });
    }

    // ==================== أدوات مساعدة ====================

    /**
     * تحويل التاريخ إلى مفتاح نصي
     * @param {Date} date 
     * @returns {string}
     */
    _dateToKey(date) {
        const d = date instanceof Date ? date : new Date(date);
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    }

    /**
     * تحويل مفتاح نصي إلى تاريخ
     * @param {string} key 
     * @returns {Date}
     */
    _keyToDate(key) {
        const [year, month, day] = key.split('-').map(Number);
        return new Date(year, month - 1, day);
    }

    /**
     * تصدير جميع البيانات
     * @returns {Promise<Object>}
     */
    async exportData() {
        await this.ensureReady();
        
        const [settings, location, prayerTimes, notifications] = await Promise.all([
            this.getAllSettings(),
            this.getLocation(),
            this._getAllPrayerTimes(),
            this.getPendingNotifications()
        ]);
        
        return {
            settings,
            location,
            prayerTimes,
            notifications,
            exportedAt: Date.now()
        };
    }

    /**
     * قراءة جميع أوقات الصلاة المخزنة
     * @returns {Promise<Array>}
     */
    async _getAllPrayerTimes() {
        return new Promise((resolve, reject) => {
            const transaction = this.db.transaction([STORES.PRAYER_TIMES], 'readonly');
            const store = transaction.objectStore(STORES.PRAYER_TIMES);
            const request = store.getAll();
            
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }

    /**
     * مسح جميع البيانات
     */
    async clearAllData() {
        await this.ensureReady();
        
        const stores = [STORES.SETTINGS, STORES.PRAYER_TIMES, STORES.NOTIFICATIONS, STORES.LOCATION];
        
        for (const storeName of stores) {
            await new Promise((resolve, reject) => {
                const transaction = this.db.transaction([storeName], 'readwrite');
                const store = transaction.objectStore(storeName);
                const request = store.clear();
                
                request.onsuccess = () => resolve();
                request.onerror = () => reject(request.error);
            });
        }
        
        return true;
    }
}

// تصدير نسخة واحدة من قاعدة البيانات
export const db = new Database();

export default db;
