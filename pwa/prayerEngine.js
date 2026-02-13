/**
 * محرك حساب أوقات الصلاة الفلكي
 * متوافق مع Adhan.js - طريقة الجعفري/العراق
 * 
 * المواصفات:
 * - Fajr: 18°
 * - Isha: 17°
 * - Madhab: Shafi
 * 
 * @author Ramadan Calendar PWA
 * @version 2.0.0
 */

// ==================== الثوابت الفلكية ====================
const DEG_TO_RAD = Math.PI / 180;
const RAD_TO_DEG = 180 / Math.PI;

// ==================== طرق الحساب ====================
const CalculationMethods = {
    // المطلوب: Fajr: 18°, Isha: 17°
    IRAQ_JAFARI: {
        name: 'العراق - الجعفري',
        fajrAngle: 18,
        ishaAngle: 17,
        maghribAngle: 0,
        midnight: 'JAFARI'
    },
    MUSLIM_WORLD_LEAGUE: {
        name: 'رابطة العالم الإسلامي',
        fajrAngle: 18,
        ishaAngle: 17,
        maghribAngle: 0,
        midnight: 'STANDARD'
    },
    ISNA: {
        name: 'ISNA - أمريكا الشمالية',
        fajrAngle: 15,
        ishaAngle: 15,
        maghribAngle: 0,
        midnight: 'STANDARD'
    },
    UMM_AL_QURA: {
        name: 'أم القرى - مكة',
        fajrAngle: 18.5,
        ishaAngle: 0,
        ishaMinutes: 90,
        maghribAngle: 0,
        midnight: 'STANDARD'
    },
    EGYPT: {
        name: 'هيئة المساحة المصرية',
        fajrAngle: 19.5,
        ishaAngle: 17.5,
        maghribAngle: 0,
        midnight: 'STANDARD'
    }
};

// ==================== المذاهب ====================
const Madhab = {
    SHAFI: 1, // ظل مثل واحد (الشافعي، المالكي، الحنبلي)
    HANAFI: 2 // ظل مثلين (الحنفي)
};

// ==================== أسماء الصلوات ====================
const PrayerNames = {
    IMSAK: 'الإمساك',
    FAJR: 'الفجر',
    SUNRISE: 'الشروق',
    DHUHR: 'الظهر',
    ASR: 'العصر',
    MAGHRIB: 'المغرب',
    ISHA: 'العشاء',
    MIDNIGHT: 'منتصف الليل'
};

// ==================== فئة محرك الصلاة ====================
class PrayerEngine {
    constructor(settings = {}) {
        // استخدام الإعدادات المطلوبة كافتراضي
        this.method = settings.method || CalculationMethods.IRAQ_JAFARI;
        this.madhab = settings.madhab || Madhab.SHAFI;
        this.imsakMinutes = settings.imsakMinutes || 10;
        this.adjustments = settings.adjustments || {};
    }

    /**
     * حساب أوقات الصلاة ليوم معين
     * @param {number} latitude - خط العرض
     * @param {number} longitude - خط الطول
     * @param {Date} date - التاريخ
     * @returns {Object} - أوقات الصلاة
     */
    calculate(latitude, longitude, date) {
        const year = date.getFullYear();
        const month = date.getMonth() + 1;
        const day = date.getDate();
        
        // حساب اليوم الجولياني
        const jd = this.julianDay(year, month, day);
        
        // حساب موقع الشمس
        const sun = this.sunPosition(jd);
        
        // الحصول على فرق التوقيت من نظام المستخدم
        const timezone = this.getTimezoneOffset(date);
        
        // حساب كل وقت
        const noon = this.computeNoon(sun.equation, longitude, timezone);
        const fajr = this.computeFajr(latitude, sun.declination, sun.equation, longitude, timezone);
        const sunrise = this.computeSunrise(latitude, sun.declination, sun.equation, longitude, timezone);
        const asr = this.computeAsr(latitude, sun.declination, noon);
        const sunset = this.computeSunset(latitude, sun.declination, sun.equation, longitude, timezone);
        const maghrib = this.computeMaghrib(sunset);
        const isha = this.computeIsha(latitude, sun.declination, sun.equation, longitude, timezone, sunset);
        const midnight = this.computeMidnight(sunset, fajr);
        
        // تحويل الساعات إلى Date objects
        const result = {
            imsak: this.hoursToDate(year, month, day, fajr - this.imsakMinutes / 60),
            fajr: this.hoursToDate(year, month, day, fajr),
            sunrise: this.hoursToDate(year, month, day, sunrise),
            dhuhr: this.hoursToDate(year, month, day, noon),
            asr: this.hoursToDate(year, month, day, asr),
            maghrib: this.hoursToDate(year, month, day, maghrib),
            isha: this.hoursToDate(year, month, day, isha),
            midnight: this.hoursToDate(year, month, day, midnight)
        };

        // تطبيق التعديلات إذا وجدت
        return this.applyAdjustments(result);
    }

    /**
     * حساب رقم اليوم الجولياني
     */
    julianDay(year, month, day) {
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
    sunPosition(jd) {
        const D = jd - 2451545.0;
        const g = this.normalizeAngle(357.529 + 0.98560028 * D);
        const q = this.normalizeAngle(280.459 + 0.98564736 * D);
        const L = this.normalizeAngle(q + 1.915 * Math.sin(g * DEG_TO_RAD) + 0.020 * Math.sin(2 * g * DEG_TO_RAD));
        const e = 23.439 - 0.00000036 * D;
        
        const RA = Math.atan2(Math.cos(e * DEG_TO_RAD) * Math.sin(L * DEG_TO_RAD), Math.cos(L * DEG_TO_RAD)) * RAD_TO_DEG;
        const decl = Math.asin(Math.sin(e * DEG_TO_RAD) * Math.sin(L * DEG_TO_RAD)) * RAD_TO_DEG;
        const normalizedRA = RA < 0 ? RA + 360 : RA;
        const EqT = (q - normalizedRA) / 15;
        
        return { declination: decl, equation: EqT };
    }

    /**
     * حساب وقت الظهر
     */
    computeNoon(equation, longitude, timezone) {
        return 12 + timezone - longitude / 15 - equation;
    }

    /**
     * حساب وقت الفجر (18 درجة)
     */
    computeFajr(latitude, declination, equation, longitude, timezone) {
        const angle = -this.method.fajrAngle;
        return this.computeTimeForAngle(angle, latitude, declination, equation, longitude, timezone, false);
    }

    /**
     * حساب وقت الشروق
     */
    computeSunrise(latitude, declination, equation, longitude, timezone) {
        return this.computeTimeForAngle(-0.833, latitude, declination, equation, longitude, timezone, false);
    }

    /**
     * حساب وقت العصر (الشافعي)
     */
    computeAsr(latitude, declination, noon) {
        const shadowFactor = this.madhab; // 1 للشافعي، 2 للحنفي
        const shadowLength = shadowFactor + Math.tan(Math.abs(latitude - declination) * DEG_TO_RAD);
        const angle = RAD_TO_DEG * Math.atan(1 / shadowLength);
        
        const cosHA = (Math.sin((90 - angle) * DEG_TO_RAD) - Math.sin(latitude * DEG_TO_RAD) * Math.sin(declination * DEG_TO_RAD)) /
                      (Math.cos(latitude * DEG_TO_RAD) * Math.cos(declination * DEG_TO_RAD));
        
        if (cosHA > 1 || cosHA < -1) return noon + 4; // fallback
        
        const HA = Math.acos(cosHA) * RAD_TO_DEG;
        return noon + HA / 15;
    }

    /**
     * حساب وقت الغروب
     */
    computeSunset(latitude, declination, equation, longitude, timezone) {
        return this.computeTimeForAngle(-0.833, latitude, declination, equation, longitude, timezone, true);
    }

    /**
     * حساب وقت المغرب
     */
    computeMaghrib(sunset) {
        return sunset;
    }

    /**
     * حساب وقت العشاء (17 درجة)
     */
    computeIsha(latitude, declination, equation, longitude, timezone, sunset) {
        if (this.method.ishaMinutes) {
            return sunset + this.method.ishaMinutes / 60;
        }
        
        const angle = -this.method.ishaAngle;
        const isha = this.computeTimeForAngle(angle, latitude, declination, equation, longitude, timezone, true);
        
        if (isha === null || isNaN(isha)) {
            return sunset + 1.5;
        }
        
        return isha;
    }

    /**
     * حساب منتصف الليل
     */
    computeMidnight(sunset, fajrNextDay) {
        if (this.method.midnight === 'JAFARI') {
            const fajr = fajrNextDay < sunset ? fajrNextDay + 24 : fajrNextDay;
            return (sunset + fajr) / 2;
        } else {
            return sunset + (24 - sunset + 6) / 2;
        }
    }

    /**
     * حساب وقت لزاوية معينة
     */
    computeTimeForAngle(angle, latitude, declination, equation, longitude, timezone, afterNoon) {
        const cosHA = (Math.sin(angle * DEG_TO_RAD) - Math.sin(latitude * DEG_TO_RAD) * Math.sin(declination * DEG_TO_RAD)) /
                      (Math.cos(latitude * DEG_TO_RAD) * Math.cos(declination * DEG_TO_RAD));
        
        if (cosHA > 1 || cosHA < -1) return null;
        
        const HA = Math.acos(cosHA) * RAD_TO_DEG / 15;
        const noon = 12 + timezone - longitude / 15 - equation;
        
        return afterNoon ? noon + HA : noon - HA;
    }

    /**
     * تحويل الساعات إلى Date object
     * مهم: بناء Date يدوياً لتجنب مشاكل التوقيت
     */
    hoursToDate(year, month, day, hours) {
        if (hours === null || isNaN(hours)) return null;
        
        while (hours < 0) hours += 24;
        while (hours >= 24) {
            hours -= 24;
            day += 1;
        }
        
        const h = Math.floor(hours);
        const m = Math.floor((hours - h) * 60);
        const s = Math.floor(((hours - h) * 60 - m) * 60);
        
        // بناء Date object يدوياً - لا نستخدم Date.parse أبداً!
        return new Date(year, month - 1, day, h, m, s, 0);
    }

    /**
     * الحصول على فرق التوقيت بالساعات
     */
    getTimezoneOffset(date) {
        return -date.getTimezoneOffset() / 60;
    }

    /**
     * تطبيع الزاوية بين 0 و 360
     */
    normalizeAngle(angle) {
        return angle - 360 * Math.floor(angle / 360);
    }

    /**
     * تطبيق التعديلات
     */
    applyAdjustments(times) {
        const adjustments = this.adjustments;
        for (const [prayer, minutes] of Object.entries(adjustments)) {
            if (times[prayer] && typeof minutes === 'number') {
                times[prayer] = new Date(times[prayer].getTime() + minutes * 60000);
            }
        }
        return times;
    }

    /**
     * تنسيق الوقت للعرض
     */
    formatTime(date, format = '12h') {
        if (!date) return '--:--';
        
        const options = {
            hour: '2-digit',
            minute: '2-digit',
            hour12: format === '12h'
        };
        
        return date.toLocaleTimeString('ar-IQ', options);
    }

    /**
     * حساب أوقات الصلاة لفترة
     */
    calculateRange(latitude, longitude, startDate, days) {
        const result = [];
        const date = new Date(startDate);
        
        for (let i = 0; i < days; i++) {
            result.push({
                date: new Date(date),
                times: this.calculate(latitude, longitude, date)
            });
            date.setDate(date.getDate() + 1);
        }
        
        return result;
    }

    /**
     * الحصول على الصلاة التالية
     */
    getNextPrayer(times, now = new Date()) {
        const prayers = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
        
        for (const prayer of prayers) {
            if (times[prayer] && times[prayer] > now) {
                return {
                    name: prayer,
                    nameAr: PrayerNames[prayer.toUpperCase()],
                    time: times[prayer],
                    remaining: times[prayer] - now
                };
            }
        }
        
        return {
            name: 'fajr',
            nameAr: PrayerNames.FAJR,
            time: null,
            remaining: null,
            isNextDay: true
        };
    }

    /**
     * الحصول على الصلاة الحالية
     */
    getCurrentPrayer(times, now = new Date()) {
        const prayers = ['isha', 'maghrib', 'asr', 'dhuhr', 'sunrise', 'fajr'];
        
        for (const prayer of prayers) {
            if (times[prayer] && times[prayer] <= now) {
                return {
                    name: prayer,
                    nameAr: PrayerNames[prayer.toUpperCase()],
                    time: times[prayer]
                };
            }
        }
        
        return null;
    }
}

// ==================== تصدير ====================
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { PrayerEngine, CalculationMethods, Madhab, PrayerNames };
} else {
    window.PrayerEngine = PrayerEngine;
    window.CalculationMethods = CalculationMethods;
    window.Madhab = Madhab;
    window.PrayerNames = PrayerNames;
}
