/**
 * Notification Manager Module
 * إدارة الإشعارات والاشتراك في Web Push
 * 
 * @author Ramadan Calendar PWA
 * @version 1.0.0
 */

// ==================== الثوابت ====================
const API_BASE = ''; // سيتم استخدام نفس الـ origin

// ==================== Notification Manager Class ====================
class NotificationManager {
    constructor() {
        this.subscription = null;
        this.vapidPublicKey = null;
        this.isSubscribed = false;
        this.swRegistration = null;
    }

    /**
     * التحقق من دعم الإشعارات
     * @returns {boolean}
     */
    isSupported() {
        return 'Notification' in window && 
               'serviceWorker' in navigator && 
               'PushManager' in window;
    }

    /**
     * حالة الإذن الحالية
     * @returns {string} - 'granted', 'denied', 'default'
     */
    getPermissionState() {
        if (!('Notification' in window)) return 'unsupported';
        return Notification.permission;
    }

    /**
     * طلب إذن الإشعارات
     * @returns {Promise<string>}
     */
    async requestPermission() {
        if (!('Notification' in window)) {
            console.warn('الإشعارات غير مدعومة');
            return 'unsupported';
        }

        if (Notification.permission === 'granted') {
            return 'granted';
        }

        const permission = await Notification.requestPermission();
        console.log(`📢 إذن الإشعارات: ${permission}`);
        return permission;
    }

    /**
     * تهيئة نظام الإشعارات
     * @param {ServiceWorkerRegistration} registration
     */
    async init(registration) {
        if (!this.isSupported()) {
            console.warn('Push Notifications غير مدعومة');
            return false;
        }

        this.swRegistration = registration;

        // الحصول على مفتاح VAPID العام
        await this.fetchVapidKey();

        // فحص الاشتراك الحالي
        await this.checkExistingSubscription();

        return true;
    }

    /**
     * جلب مفتاح VAPID العام من السيرفر
     */
    async fetchVapidKey() {
        try {
            const response = await fetch(`${API_BASE}/api/vapid-public-key`);
            
            if (!response.ok) {
                throw new Error('فشل في جلب مفتاح VAPID');
            }

            const data = await response.json();
            this.vapidPublicKey = data.publicKey;
            console.log('✅ تم جلب مفتاح VAPID');
        } catch (error) {
            console.error('❌ خطأ في جلب VAPID:', error);
            // استمر بدون Push
        }
    }

    /**
     * فحص الاشتراك الموجود
     */
    async checkExistingSubscription() {
        if (!this.swRegistration) return;

        try {
            this.subscription = await this.swRegistration.pushManager.getSubscription();
            this.isSubscribed = this.subscription !== null;
            
            if (this.isSubscribed) {
                console.log('✅ يوجد اشتراك Push');
            }
        } catch (error) {
            console.error('خطأ في فحص الاشتراك:', error);
        }
    }

    /**
     * الاشتراك في Push Notifications
     * @param {Object} location - الموقع الجغرافي
     * @returns {Promise<Object>}
     */
    async subscribe(location = {}) {
        if (!this.swRegistration || !this.vapidPublicKey) {
            console.error('لم يتم تهيئة نظام الإشعارات');
            return null;
        }

        // طلب الإذن أولاً
        const permission = await this.requestPermission();
        if (permission !== 'granted') {
            console.warn('لم يتم منح إذن الإشعارات');
            return null;
        }

        try {
            // تحويل VAPID key إلى Uint8Array
            const applicationServerKey = this.urlBase64ToUint8Array(this.vapidPublicKey);

            // إنشاء الاشتراك
            this.subscription = await this.swRegistration.pushManager.subscribe({
                userVisibleOnly: true,
                applicationServerKey: applicationServerKey
            });

            this.isSubscribed = true;
            console.log('✅ تم إنشاء اشتراك Push');

            // إرسال الاشتراك للسيرفر
            await this.sendSubscriptionToServer(this.subscription, location);

            return this.subscription;
        } catch (error) {
            console.error('❌ فشل في الاشتراك:', error);
            this.isSubscribed = false;
            return null;
        }
    }

    /**
     * إلغاء الاشتراك
     * @returns {Promise<boolean>}
     */
    async unsubscribe() {
        if (!this.subscription) {
            console.warn('لا يوجد اشتراك للإلغاء');
            return true;
        }

        try {
            // إلغاء الاشتراك من السيرفر
            await this.removeSubscriptionFromServer(this.subscription.endpoint);

            // إلغاء الاشتراك محلياً
            await this.subscription.unsubscribe();

            this.subscription = null;
            this.isSubscribed = false;
            console.log('✅ تم إلغاء الاشتراك');
            return true;
        } catch (error) {
            console.error('❌ فشل في إلغاء الاشتراك:', error);
            return false;
        }
    }

    /**
     * إرسال الاشتراك للسيرفر
     * @param {PushSubscription} subscription
     * @param {Object} location
     */
    async sendSubscriptionToServer(subscription, location = {}) {
        try {
            const response = await fetch(`${API_BASE}/api/subscribe`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    subscription: subscription.toJSON(),
                    latitude: location.latitude || null,
                    longitude: location.longitude || null,
                    timezone: location.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone
                })
            });

            if (!response.ok) {
                throw new Error('فشل في حفظ الاشتراك');
            }

            const data = await response.json();
            console.log(`✅ تم حفظ الاشتراك (${data.scheduledNotifications} إشعار مجدول)`);
            return data;
        } catch (error) {
            console.error('❌ خطأ في إرسال الاشتراك:', error);
            throw error;
        }
    }

    /**
     * إزالة الاشتراك من السيرفر
     * @param {string} endpoint
     */
    async removeSubscriptionFromServer(endpoint) {
        try {
            await fetch(`${API_BASE}/api/unsubscribe`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ endpoint })
            });
        } catch (error) {
            console.error('خطأ في إزالة الاشتراك:', error);
        }
    }

    /**
     * تحديث الموقع في السيرفر
     * @param {Object} location
     */
    async updateServerLocation(location) {
        if (!this.subscription) {
            console.warn('لا يوجد اشتراك لتحديث الموقع');
            return;
        }

        try {
            const response = await fetch(`${API_BASE}/api/update-location`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    endpoint: this.subscription.endpoint,
                    latitude: location.latitude,
                    longitude: location.longitude,
                    timezone: location.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone
                })
            });

            if (!response.ok) {
                throw new Error('فشل في تحديث الموقع');
            }

            const data = await response.json();
            console.log(`✅ تم تحديث الموقع (${data.scheduledNotifications} إشعار معاد جدولته)`);
            return data;
        } catch (error) {
            console.error('❌ خطأ في تحديث الموقع:', error);
        }
    }

    /**
     * إرسال إشعار محلي
     * @param {string} title - العنوان
     * @param {Object} options - الخيارات
     */
    async showLocalNotification(title, options = {}) {
        if (!this.swRegistration) {
            console.warn('Service Worker غير مسجل');
            return;
        }

        const defaultOptions = {
            icon: '/assets/icons/icon-192x192.png',
            badge: '/assets/icons/icon-72x72.png',
            vibrate: [200, 100, 200],
            requireInteraction: true,
            dir: 'rtl',
            lang: 'ar'
        };

        await this.swRegistration.showNotification(title, {
            ...defaultOptions,
            ...options
        });
    }

    /**
     * تحويل Base64 URL-safe إلى Uint8Array
     * @param {string} base64String
     * @returns {Uint8Array}
     */
    urlBase64ToUint8Array(base64String) {
        const padding = '='.repeat((4 - base64String.length % 4) % 4);
        const base64 = (base64String + padding)
            .replace(/-/g, '+')
            .replace(/_/g, '/');

        const rawData = window.atob(base64);
        const outputArray = new Uint8Array(rawData.length);

        for (let i = 0; i < rawData.length; ++i) {
            outputArray[i] = rawData.charCodeAt(i);
        }

        return outputArray;
    }

    /**
     * الحصول على حالة الاشتراك
     * @returns {Object}
     */
    getStatus() {
        return {
            isSupported: this.isSupported(),
            permission: this.getPermissionState(),
            isSubscribed: this.isSubscribed,
            hasVapidKey: !!this.vapidPublicKey
        };
    }
}

// ==================== Local Notification Scheduler ====================
// للعمل أوفلاين عندما لا يكون السيرفر متاحاً

class LocalNotificationScheduler {
    constructor() {
        this.scheduledTimeouts = new Map();
    }

    /**
     * جدولة إشعار محلي
     * @param {string} id - معرف الإشعار
     * @param {Date} time - وقت الإشعار
     * @param {Object} notification - محتوى الإشعار
     * @param {ServiceWorkerRegistration} swRegistration
     */
    schedule(id, time, notification, swRegistration) {
        const now = Date.now();
        const delay = time.getTime() - now;

        if (delay <= 0) {
            console.log(`⏭️ تخطي إشعار منتهي: ${id}`);
            return;
        }

        // إلغاء أي جدولة سابقة
        this.cancel(id);

        const timeoutId = setTimeout(async () => {
            try {
                await swRegistration.showNotification(notification.title, {
                    body: notification.body,
                    icon: notification.icon || '/assets/icons/icon-192x192.png',
                    badge: notification.badge || '/assets/icons/icon-72x72.png',
                    tag: notification.tag || id,
                    vibrate: [200, 100, 200],
                    requireInteraction: true,
                    data: notification.data || {},
                    actions: notification.actions || []
                });
                
                console.log(`🔔 تم عرض إشعار: ${notification.title}`);
            } catch (error) {
                console.error('خطأ في عرض الإشعار:', error);
            }

            this.scheduledTimeouts.delete(id);
        }, delay);

        this.scheduledTimeouts.set(id, timeoutId);
        console.log(`⏰ تم جدولة إشعار: ${id} بعد ${Math.round(delay / 60000)} دقيقة`);
    }

    /**
     * إلغاء إشعار مجدول
     * @param {string} id
     */
    cancel(id) {
        if (this.scheduledTimeouts.has(id)) {
            clearTimeout(this.scheduledTimeouts.get(id));
            this.scheduledTimeouts.delete(id);
        }
    }

    /**
     * إلغاء جميع الإشعارات المجدولة
     */
    cancelAll() {
        for (const [id, timeoutId] of this.scheduledTimeouts) {
            clearTimeout(timeoutId);
        }
        this.scheduledTimeouts.clear();
        console.log('🗑️ تم إلغاء جميع الإشعارات المجدولة');
    }

    /**
     * عدد الإشعارات المجدولة
     * @returns {number}
     */
    getScheduledCount() {
        return this.scheduledTimeouts.size;
    }
}

// تصدير
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { NotificationManager, LocalNotificationScheduler };
} else {
    window.NotificationManager = NotificationManager;
    window.LocalNotificationScheduler = LocalNotificationScheduler;
}
