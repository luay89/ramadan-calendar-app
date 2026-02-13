/**
 * Service Worker لتطبيق تقويم رمضان
 * يدير التخزين المؤقت والإشعارات الخلفية
 * 
 * @author Ramadan Calendar PWA
 * @version 1.0.0
 */

// إصدار الكاش - يجب تحديثه عند كل تغيير
const CACHE_VERSION = 'v2.0.0';
const CACHE_NAME = `ramadan-calendar-${CACHE_VERSION}`;

// الملفات التي يجب تخزينها
const STATIC_ASSETS = [
    '/',
    '/index.html',
    '/app.js',
    '/prayerEngine.js',
    '/db.js',
    '/locationManager.js',
    '/notificationManager.js',
    '/adhanPlayer.js',
    '/manifest.json',
    '/assets/audio/adhan.mp3',
    '/assets/icons/icon-192x192.png',
    '/assets/icons/icon-512x512.png'
];

// اسم قاعدة البيانات
const DB_NAME = 'RamadanCalendarDB';

// ==================== حدث التثبيت ====================
self.addEventListener('install', (event) => {
    console.log('[SW] جاري التثبيت...');
    
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then((cache) => {
                console.log('[SW] تخزين الملفات الأساسية');
                return cache.addAll(STATIC_ASSETS.map(url => {
                    return new Request(url, { cache: 'reload' });
                }));
            })
            .then(() => {
                console.log('[SW] اكتمل التثبيت');
                // تفعيل فوري بدون انتظار
                return self.skipWaiting();
            })
            .catch((error) => {
                console.error('[SW] فشل التثبيت:', error);
            })
    );
});

// ==================== حدث التفعيل ====================
self.addEventListener('activate', (event) => {
    console.log('[SW] جاري التفعيل...');
    
    event.waitUntil(
        Promise.all([
            // حذف الكاش القديم
            caches.keys().then((cacheNames) => {
                return Promise.all(
                    cacheNames
                        .filter((name) => name !== CACHE_NAME && name.startsWith('ramadan-calendar-'))
                        .map((name) => {
                            console.log('[SW] حذف كاش قديم:', name);
                            return caches.delete(name);
                        })
                );
            }),
            // التحكم بجميع الصفحات فوراً
            self.clients.claim()
        ]).then(() => {
            console.log('[SW] اكتمل التفعيل');
            // تشغيل جدولة الإشعارات
            scheduleNotificationCheck();
        })
    );
});

// ==================== حدث الطلبات ====================
self.addEventListener('fetch', (event) => {
    const url = new URL(event.request.url);
    
    // تجاهل الطلبات الخارجية
    if (url.origin !== self.location.origin) {
        return;
    }
    
    // استراتيجية مختلفة حسب نوع الملف
    if (isStaticAsset(event.request)) {
        // Cache First للأصول الثابتة
        event.respondWith(cacheFirst(event.request));
    } else {
        // Network First للبيانات
        event.respondWith(networkFirst(event.request));
    }
});

/**
 * التحقق إذا كان الطلب لأصل ثابت
 */
function isStaticAsset(request) {
    const url = new URL(request.url);
    const staticExtensions = ['.html', '.css', '.js', '.json', '.mp3', '.png', '.jpg', '.svg', '.ico'];
    return staticExtensions.some(ext => url.pathname.endsWith(ext)) || 
           url.pathname === '/' ||
           url.pathname === '';
}

/**
 * استراتيجية Cache First
 */
async function cacheFirst(request) {
    const cached = await caches.match(request);
    if (cached) {
        return cached;
    }
    
    try {
        const response = await fetch(request);
        if (response.ok) {
            const cache = await caches.open(CACHE_NAME);
            cache.put(request, response.clone());
        }
        return response;
    } catch (error) {
        console.error('[SW] فشل الجلب:', error);
        // إرجاع صفحة أوفلاين إذا كانت موجودة
        return caches.match('/index.html');
    }
}

/**
 * استراتيجية Network First
 */
async function networkFirst(request) {
    try {
        const response = await fetch(request);
        if (response.ok) {
            const cache = await caches.open(CACHE_NAME);
            cache.put(request, response.clone());
        }
        return response;
    } catch (error) {
        const cached = await caches.match(request);
        if (cached) {
            return cached;
        }
        // إرجاع صفحة الأوفلاين
        return caches.match('/index.html');
    }
}

// ==================== حدث المزامنة الخلفية ====================
self.addEventListener('sync', (event) => {
    console.log('[SW] حدث مزامنة:', event.tag);
    
    if (event.tag === 'check-prayer-times') {
        event.waitUntil(checkAndScheduleNotifications());
    }
    
    if (event.tag === 'reschedule-notifications') {
        event.waitUntil(rescheduleAllNotifications());
    }
});

// ==================== حدث المزامنة الدورية ====================
self.addEventListener('periodicsync', (event) => {
    console.log('[SW] مزامنة دورية:', event.tag);
    
    if (event.tag === 'prayer-notifications') {
        event.waitUntil(checkAndScheduleNotifications());
    }
});

// ==================== حدث الإشعار Push ====================
self.addEventListener('push', (event) => {
    console.log('[SW] استلام push notification');
    
    let data = {
        title: 'تقويم رمضان',
        body: 'حان وقت الصلاة',
        icon: '/assets/icons/icon-192x192.png'
    };
    
    if (event.data) {
        try {
            data = event.data.json();
        } catch (e) {
            data.body = event.data.text();
        }
    }
    
    event.waitUntil(
        self.registration.showNotification(data.title, {
            body: data.body,
            icon: data.icon || '/assets/icons/icon-192x192.png',
            badge: '/assets/icons/icon-96x96.png',
            vibrate: [200, 100, 200, 100, 200],
            tag: data.tag || 'prayer-notification',
            requireInteraction: true,
            actions: [
                { action: 'play-adhan', title: '🔊 تشغيل الأذان' },
                { action: 'dismiss', title: '❌ إغلاق' }
            ],
            data: data
        })
    );
});

// ==================== حدث النقر على الإشعار ====================
self.addEventListener('notificationclick', (event) => {
    console.log('[SW] نقر على الإشعار:', event.action);
    
    event.notification.close();
    
    if (event.action === 'dismiss') {
        return;
    }
    
    // الحصول على بيانات الإشعار
    const notificationData = event.notification.data || {};
    const prayerKey = notificationData.prayerKey || '';
    
    // فتح التطبيق مع تشغيل الأذان
    event.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true })
            .then((clientList) => {
                // البحث عن نافذة مفتوحة
                for (const client of clientList) {
                    if (client.url.includes(self.location.origin)) {
                        // إرسال رسالة لتشغيل الأذان
                        client.postMessage({
                            type: 'PLAY_ADHAN',
                            prayerKey: prayerKey,
                            action: event.action
                        });
                        return client.focus();
                    }
                }
                
                // فتح نافذة جديدة مع تشغيل الأذان
                const url = event.action === 'play-adhan' 
                    ? `/?playAdhan=true&prayer=${prayerKey}`
                    : '/';
                return clients.openWindow(url);
            })
    );
});

// ==================== حدث إغلاق الإشعار ====================
self.addEventListener('notificationclose', (event) => {
    console.log('[SW] تم إغلاق الإشعار');
});

// ==================== إدارة الإشعارات المجدولة ====================

/**
 * فحص وجدولة الإشعارات
 */
async function checkAndScheduleNotifications() {
    try {
        const db = await openDatabase();
        const pendingNotifications = await getPendingNotifications(db);
        const now = Date.now();
        
        for (const notif of pendingNotifications) {
            const timeUntil = notif.scheduledTime - now;
            
            // إذا حان الوقت أو تجاوزه
            if (timeUntil <= 60000) { // دقيقة واحدة أو أقل
                await showPrayerNotification(notif);
                await markNotificationSent(db, notif.id);
            }
        }
        
        // تنظيف الإشعارات القديمة
        await cleanOldNotifications(db);
        
    } catch (error) {
        console.error('[SW] خطأ في جدولة الإشعارات:', error);
    }
}

/**
 * إعادة جدولة جميع الإشعارات
 */
async function rescheduleAllNotifications() {
    try {
        // إرسال رسالة للتطبيق لإعادة الجدولة
        const clients = await self.clients.matchAll();
        clients.forEach(client => {
            client.postMessage({
                type: 'RESCHEDULE_NOTIFICATIONS'
            });
        });
    } catch (error) {
        console.error('[SW] خطأ في إعادة الجدولة:', error);
    }
}

/**
 * عرض إشعار الصلاة
 */
async function showPrayerNotification(notif) {
    const prayerEmojis = {
        fajr: '🌙',
        sunrise: '🌅',
        dhuhr: '☀️',
        asr: '🌤️',
        maghrib: '🌆',
        isha: '🌃',
        imsak: '⏰'
    };
    
    const emoji = prayerEmojis[notif.prayerKey] || '🕌';
    
    return self.registration.showNotification(`${emoji} حان وقت ${notif.prayerName}`, {
        body: 'اضغط هنا لتشغيل الأذان',
        icon: '/assets/icons/icon-192x192.png',
        badge: '/assets/icons/icon-96x96.png',
        vibrate: [200, 100, 200, 100, 200, 100, 200],
        tag: `prayer-${notif.prayerKey}-${Date.now()}`,
        requireInteraction: true,
        silent: false,
        actions: [
            { action: 'play-adhan', title: '🔊 تشغيل الأذان' },
            { action: 'dismiss', title: '❌ إغلاق' }
        ],
        data: {
            prayerKey: notif.prayerKey,
            prayerName: notif.prayerName,
            scheduledTime: notif.scheduledTime
        }
    });
}

/**
 * جدولة فحص الإشعارات
 */
function scheduleNotificationCheck() {
    // فحص كل 30 ثانية
    setInterval(() => {
        checkAndScheduleNotifications();
    }, 30000);
    
    // فحص فوري
    checkAndScheduleNotifications();
}

// ==================== دوال IndexedDB للـ Service Worker ====================

/**
 * فتح قاعدة البيانات
 */
function openDatabase() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, 1);
        
        request.onerror = () => reject(request.error);
        request.onsuccess = () => resolve(request.result);
        
        request.onupgradeneeded = (event) => {
            const db = event.target.result;
            
            if (!db.objectStoreNames.contains('notifications')) {
                const store = db.createObjectStore('notifications', { keyPath: 'id' });
                store.createIndex('scheduledTime', 'scheduledTime');
            }
            
            if (!db.objectStoreNames.contains('settings')) {
                db.createObjectStore('settings', { keyPath: 'key' });
            }
        };
    });
}

/**
 * الحصول على الإشعارات المعلقة
 */
function getPendingNotifications(db) {
    return new Promise((resolve, reject) => {
        const transaction = db.transaction(['notifications'], 'readonly');
        const store = transaction.objectStore('notifications');
        const request = store.getAll();
        
        request.onsuccess = () => {
            const pending = request.result
                .filter(n => !n.sent)
                .sort((a, b) => a.scheduledTime - b.scheduledTime);
            resolve(pending);
        };
        request.onerror = () => reject(request.error);
    });
}

/**
 * تحديث حالة الإشعار
 */
function markNotificationSent(db, id) {
    return new Promise((resolve, reject) => {
        const transaction = db.transaction(['notifications'], 'readwrite');
        const store = transaction.objectStore('notifications');
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
 * تنظيف الإشعارات القديمة
 */
function cleanOldNotifications(db) {
    return new Promise((resolve, reject) => {
        const transaction = db.transaction(['notifications'], 'readwrite');
        const store = transaction.objectStore('notifications');
        const request = store.getAll();
        
        request.onsuccess = () => {
            const oldTime = Date.now() - 86400000; // قبل 24 ساعة
            const toDelete = request.result.filter(n => n.scheduledTime < oldTime);
            
            toDelete.forEach(n => store.delete(n.id));
            transaction.oncomplete = () => resolve(toDelete.length);
        };
        request.onerror = () => reject(request.error);
    });
}

// ==================== استقبال الرسائل من التطبيق ====================
self.addEventListener('message', (event) => {
    console.log('[SW] استلام رسالة:', event.data);
    
    if (event.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }
    
    if (event.data.type === 'SCHEDULE_NOTIFICATION') {
        scheduleLocalNotification(event.data.notification);
    }
    
    if (event.data.type === 'CHECK_NOTIFICATIONS') {
        checkAndScheduleNotifications();
    }
    
    if (event.data.type === 'CLEAR_NOTIFICATIONS') {
        clearAllScheduledNotifications();
    }
});

/**
 * جدولة إشعار محلي
 */
async function scheduleLocalNotification(notification) {
    try {
        const db = await openDatabase();
        const transaction = db.transaction(['notifications'], 'readwrite');
        const store = transaction.objectStore('notifications');
        
        const data = {
            id: notification.id || `notif_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
            prayerKey: notification.prayerKey,
            prayerName: notification.prayerName,
            scheduledTime: notification.scheduledTime,
            sent: false,
            createdAt: Date.now()
        };
        
        store.put(data);
        console.log('[SW] تم جدولة إشعار:', data);
        
    } catch (error) {
        console.error('[SW] خطأ في جدولة الإشعار:', error);
    }
}

/**
 * مسح جميع الإشعارات المجدولة
 */
async function clearAllScheduledNotifications() {
    try {
        const db = await openDatabase();
        const transaction = db.transaction(['notifications'], 'readwrite');
        const store = transaction.objectStore('notifications');
        store.clear();
        console.log('[SW] تم مسح جميع الإشعارات');
    } catch (error) {
        console.error('[SW] خطأ في مسح الإشعارات:', error);
    }
}

console.log('[SW] Service Worker جاهز');
