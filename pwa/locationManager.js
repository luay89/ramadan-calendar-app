/**
 * Location Manager Module
 * إدارة الموقع الجغرافي
 * 
 * @author Ramadan Calendar PWA
 * @version 1.0.0
 */

// ==================== الثوابت ====================
const LOCATION_CHANGE_THRESHOLD = 1000; // متر (1 كم)
const DEFAULT_LOCATION = {
    latitude: 33.3152,
    longitude: 44.3661,
    name: 'بغداد، العراق'
};

// ==================== Location Manager Class ====================
class LocationManager {
    constructor() {
        this.currentLocation = null;
        this.watchId = null;
        this.onLocationChange = null;
        this.onError = null;
    }

    /**
     * التحقق من دعم الجغرافيا
     * @returns {boolean}
     */
    isSupported() {
        return 'geolocation' in navigator;
    }

    /**
     * الحصول على الموقع الحالي
     * @param {Object} options - خيارات الموقع
     * @returns {Promise<Object>}
     */
    async getCurrentPosition(options = {}) {
        if (!this.isSupported()) {
            console.warn('Geolocation غير مدعوم');
            return this.getDefaultLocation();
        }

        const defaultOptions = {
            enableHighAccuracy: true,
            timeout: 10000,
            maximumAge: 0
        };

        const mergedOptions = { ...defaultOptions, ...options };

        return new Promise((resolve, reject) => {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    const location = {
                        latitude: position.coords.latitude,
                        longitude: position.coords.longitude,
                        accuracy: position.coords.accuracy,
                        timestamp: position.timestamp,
                        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
                    };

                    this.currentLocation = location;
                    resolve(location);
                },
                (error) => {
                    console.error('خطأ في الحصول على الموقع:', error.message);
                    
                    // إرجاع الموقع الافتراضي عند الفشل
                    const defaultLoc = this.getDefaultLocation();
                    this.currentLocation = defaultLoc;
                    resolve(defaultLoc);
                },
                mergedOptions
            );
        });
    }

    /**
     * الموقع الافتراضي (بغداد)
     * @returns {Object}
     */
    getDefaultLocation() {
        return {
            ...DEFAULT_LOCATION,
            accuracy: null,
            timestamp: Date.now(),
            timezone: 'Asia/Baghdad',
            isDefault: true
        };
    }

    /**
     * بدء مراقبة الموقع
     * @param {Function} callback - دالة عند تغير الموقع
     * @param {Function} errorCallback - دالة عند حدوث خطأ
     */
    startWatching(callback, errorCallback) {
        if (!this.isSupported()) {
            console.warn('Geolocation غير مدعوم');
            return null;
        }

        this.onLocationChange = callback;
        this.onError = errorCallback;

        this.watchId = navigator.geolocation.watchPosition(
            (position) => {
                const newLocation = {
                    latitude: position.coords.latitude,
                    longitude: position.coords.longitude,
                    accuracy: position.coords.accuracy,
                    timestamp: position.timestamp,
                    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
                };

                // فحص إذا تغير الموقع بشكل ملحوظ
                if (this.currentLocation) {
                    const distance = this.calculateDistance(
                        this.currentLocation.latitude,
                        this.currentLocation.longitude,
                        newLocation.latitude,
                        newLocation.longitude
                    );

                    if (distance > LOCATION_CHANGE_THRESHOLD) {
                        console.log(`📍 تغير الموقع بمقدار ${Math.round(distance)} متر`);
                        this.currentLocation = newLocation;
                        
                        if (this.onLocationChange) {
                            this.onLocationChange(newLocation, distance);
                        }
                    }
                } else {
                    this.currentLocation = newLocation;
                    if (this.onLocationChange) {
                        this.onLocationChange(newLocation, 0);
                    }
                }
            },
            (error) => {
                console.error('خطأ في مراقبة الموقع:', error.message);
                if (this.onError) {
                    this.onError(error);
                }
            },
            {
                enableHighAccuracy: true,
                maximumAge: 60000, // دقيقة واحدة
                timeout: 30000
            }
        );

        return this.watchId;
    }

    /**
     * إيقاف مراقبة الموقع
     */
    stopWatching() {
        if (this.watchId !== null) {
            navigator.geolocation.clearWatch(this.watchId);
            this.watchId = null;
            console.log('⏹️ توقف مراقبة الموقع');
        }
    }

    /**
     * حساب المسافة بين نقطتين (صيغة Haversine)
     * @param {number} lat1 - خط العرض الأول
     * @param {number} lon1 - خط الطول الأول
     * @param {number} lat2 - خط العرض الثاني
     * @param {number} lon2 - خط الطول الثاني
     * @returns {number} - المسافة بالأمتار
     */
    calculateDistance(lat1, lon1, lat2, lon2) {
        const R = 6371000; // نصف قطر الأرض بالأمتار
        const dLat = this.toRad(lat2 - lat1);
        const dLon = this.toRad(lon2 - lon1);
        
        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                  Math.cos(this.toRad(lat1)) * Math.cos(this.toRad(lat2)) *
                  Math.sin(dLon / 2) * Math.sin(dLon / 2);
        
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        
        return R * c;
    }

    /**
     * تحويل الدرجات إلى راديان
     * @param {number} deg - الدرجات
     * @returns {number}
     */
    toRad(deg) {
        return deg * (Math.PI / 180);
    }

    /**
     * الحصول على اسم المدينة (Reverse Geocoding)
     * @param {number} latitude
     * @param {number} longitude
     * @returns {Promise<string>}
     */
    async getCityName(latitude, longitude) {
        try {
            // استخدام Nominatim API مجاني
            const response = await fetch(
                `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&zoom=10&accept-language=ar`
            );
            
            if (!response.ok) throw new Error('فشل في الحصول على اسم المدينة');
            
            const data = await response.json();
            
            return data.address?.city || 
                   data.address?.town || 
                   data.address?.village ||
                   data.address?.state ||
                   'موقع غير معروف';
        } catch (error) {
            console.error('خطأ في Reverse Geocoding:', error);
            return 'موقع غير معروف';
        }
    }

    /**
     * حفظ الموقع في IndexedDB
     * @param {Object} db - مثيل قاعدة البيانات
     * @param {Object} location - الموقع
     */
    async saveLocation(db, location) {
        if (db && typeof db.saveLocation === 'function') {
            await db.saveLocation(location);
        }
    }

    /**
     * استرجاع الموقع من IndexedDB
     * @param {Object} db - مثيل قاعدة البيانات
     * @returns {Promise<Object|null>}
     */
    async loadSavedLocation(db) {
        if (db && typeof db.getLocation === 'function') {
            return await db.getLocation();
        }
        return null;
    }

    /**
     * طلب إذن الموقع
     * @returns {Promise<string>} - 'granted', 'denied', 'prompt'
     */
    async requestPermission() {
        if (!('permissions' in navigator)) {
            // Fallback للمتصفحات التي لا تدعم Permissions API
            try {
                await this.getCurrentPosition({ timeout: 5000 });
                return 'granted';
            } catch {
                return 'denied';
            }
        }

        try {
            const result = await navigator.permissions.query({ name: 'geolocation' });
            return result.state;
        } catch {
            return 'prompt';
        }
    }

    /**
     * الحصول على المنطقة الزمنية
     * @returns {string}
     */
    getTimezone() {
        return Intl.DateTimeFormat().resolvedOptions().timeZone;
    }

    /**
     * فحص إذا كان الموقع في العراق
     * @param {number} latitude
     * @param {number} longitude
     * @returns {boolean}
     */
    isInIraq(latitude, longitude) {
        // حدود العراق التقريبية
        return (
            latitude >= 29.0 && latitude <= 37.5 &&
            longitude >= 38.0 && longitude <= 49.0
        );
    }
}

// تصدير للاستخدام كـ ES6 module أو global
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { LocationManager, DEFAULT_LOCATION };
} else {
    window.LocationManager = LocationManager;
    window.DEFAULT_LOCATION = DEFAULT_LOCATION;
}
