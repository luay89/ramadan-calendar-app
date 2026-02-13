/**
 * وحدة تشغيل الأذان
 * تدير تشغيل صوت الأذان مع دعم الخلفية
 * 
 * @author Ramadan Calendar PWA
 * @version 1.0.0
 */

import { db } from './db.js';

// مسارات ملفات الأذان
const ADHAN_FILES = {
    default: '/assets/audio/adhan.mp3',
    fajr: '/assets/audio/adhan-fajr.mp3',  // أذان الفجر مختلف (اختياري)
};

/**
 * فئة مشغل الأذان
 */
export class AdhanPlayer {
    constructor() {
        this.audio = null;
        this.isPlaying = false;
        this.isEnabled = true;
        this.volume = 1.0;
        this.currentPrayer = null;
        this.onPlayStateChange = null;
    }

    /**
     * تهيئة المشغل
     */
    async init() {
        // تحميل الإعدادات
        this.isEnabled = await db.getSetting('adhanEnabled', true);
        this.volume = await db.getSetting('adhanVolume', 1.0);
        
        // إنشاء عنصر الصوت
        this.audio = new Audio();
        this.audio.preload = 'auto';
        this.audio.volume = this.volume;
        
        // أحداث الصوت
        this.audio.addEventListener('play', () => {
            this.isPlaying = true;
            this._notifyStateChange();
        });
        
        this.audio.addEventListener('pause', () => {
            this.isPlaying = false;
            this._notifyStateChange();
        });
        
        this.audio.addEventListener('ended', () => {
            this.isPlaying = false;
            this.currentPrayer = null;
            this._notifyStateChange();
        });
        
        this.audio.addEventListener('error', (e) => {
            console.error('[AdhanPlayer] خطأ في تشغيل الصوت:', e);
            this.isPlaying = false;
            this._notifyStateChange();
        });
        
        // تحميل الملف مسبقاً
        await this.preload();
        
        console.log('[AdhanPlayer] تم التهيئة');
    }

    /**
     * تحميل ملف الأذان مسبقاً
     */
    async preload() {
        try {
            // محاولة تحميل من الكاش أولاً
            if ('caches' in window) {
                const cache = await caches.open('ramadan-calendar-v1.0.0');
                const response = await cache.match(ADHAN_FILES.default);
                if (response) {
                    const blob = await response.blob();
                    this.audio.src = URL.createObjectURL(blob);
                    return;
                }
            }
            
            // تحميل من الشبكة
            this.audio.src = ADHAN_FILES.default;
            await this.audio.load();
            
        } catch (error) {
            console.error('[AdhanPlayer] فشل تحميل الأذان:', error);
        }
    }

    /**
     * تشغيل الأذان
     * @param {string} prayerKey - مفتاح الصلاة (اختياري)
     * @returns {Promise<boolean>}
     */
    async play(prayerKey = null) {
        if (!this.isEnabled) {
            console.log('[AdhanPlayer] الأذان معطل');
            return false;
        }
        
        if (this.isPlaying) {
            console.log('[AdhanPlayer] الأذان قيد التشغيل');
            return true;
        }
        
        try {
            this.currentPrayer = prayerKey;
            
            // اختيار ملف الأذان المناسب
            let adhanFile = ADHAN_FILES.default;
            if (prayerKey === 'fajr' && ADHAN_FILES.fajr) {
                adhanFile = ADHAN_FILES.fajr;
            }
            
            // التأكد من تحميل الملف
            if (this.audio.src !== adhanFile && !this.audio.src.includes('blob:')) {
                this.audio.src = adhanFile;
                await this.audio.load();
            }
            
            // محاولة التشغيل
            this.audio.currentTime = 0;
            await this.audio.play();
            
            console.log(`[AdhanPlayer] تشغيل الأذان لصلاة ${prayerKey || 'عام'}`);
            return true;
            
        } catch (error) {
            console.error('[AdhanPlayer] فشل التشغيل:', error);
            
            // محاولة التشغيل بعد تفاعل المستخدم
            if (error.name === 'NotAllowedError') {
                this._showPlayPrompt();
            }
            
            return false;
        }
    }

    /**
     * إيقاف الأذان
     */
    stop() {
        if (this.audio) {
            this.audio.pause();
            this.audio.currentTime = 0;
        }
        this.isPlaying = false;
        this.currentPrayer = null;
        this._notifyStateChange();
        console.log('[AdhanPlayer] تم إيقاف الأذان');
    }

    /**
     * إيقاف مؤقت
     */
    pause() {
        if (this.audio && this.isPlaying) {
            this.audio.pause();
        }
    }

    /**
     * استئناف التشغيل
     */
    async resume() {
        if (this.audio && !this.isPlaying) {
            try {
                await this.audio.play();
            } catch (error) {
                console.error('[AdhanPlayer] فشل الاستئناف:', error);
            }
        }
    }

    /**
     * ضبط مستوى الصوت
     * @param {number} volume - 0 إلى 1
     */
    async setVolume(volume) {
        this.volume = Math.max(0, Math.min(1, volume));
        if (this.audio) {
            this.audio.volume = this.volume;
        }
        await db.setSetting('adhanVolume', this.volume);
    }

    /**
     * تفعيل/تعطيل الأذان
     * @param {boolean} enabled
     */
    async setEnabled(enabled) {
        this.isEnabled = enabled;
        await db.setSetting('adhanEnabled', enabled);
        
        if (!enabled && this.isPlaying) {
            this.stop();
        }
    }

    /**
     * الحصول على الوقت الحالي للتشغيل
     * @returns {number} - الثواني
     */
    getCurrentTime() {
        return this.audio ? this.audio.currentTime : 0;
    }

    /**
     * الحصول على المدة الكلية
     * @returns {number} - الثواني
     */
    getDuration() {
        return this.audio ? this.audio.duration : 0;
    }

    /**
     * الحصول على نسبة التقدم
     * @returns {number} - 0 إلى 1
     */
    getProgress() {
        if (!this.audio || !this.audio.duration) {
            return 0;
        }
        return this.audio.currentTime / this.audio.duration;
    }

    /**
     * إظهار نافذة تشغيل الأذان (للتعامل مع قيود المتصفح)
     */
    _showPlayPrompt() {
        // إنشاء طبقة overlay للضغط
        const overlay = document.createElement('div');
        overlay.id = 'adhan-play-prompt';
        overlay.innerHTML = `
            <div class="adhan-prompt-content">
                <div class="adhan-prompt-icon">🔊</div>
                <h3>تشغيل الأذان</h3>
                <p>اضغط هنا لتشغيل الأذان</p>
                <button id="adhan-play-btn" class="btn btn-primary">
                    تشغيل الأذان
                </button>
            </div>
        `;
        
        overlay.style.cssText = `
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.9);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 10000;
            animation: fadeIn 0.3s ease;
        `;
        
        const content = overlay.querySelector('.adhan-prompt-content');
        content.style.cssText = `
            text-align: center;
            padding: 2rem;
            background: var(--card-bg, #1a4d2e);
            border-radius: 1rem;
            color: white;
        `;
        
        document.body.appendChild(overlay);
        
        // زر التشغيل
        const playBtn = overlay.querySelector('#adhan-play-btn');
        playBtn.addEventListener('click', async () => {
            overlay.remove();
            await this.play(this.currentPrayer);
        });
        
        // إغلاق عند الضغط خارج المحتوى
        overlay.addEventListener('click', (e) => {
            if (e.target === overlay) {
                overlay.remove();
            }
        });
    }

    /**
     * إشعار بتغيير حالة التشغيل
     */
    _notifyStateChange() {
        if (typeof this.onPlayStateChange === 'function') {
            this.onPlayStateChange({
                isPlaying: this.isPlaying,
                currentPrayer: this.currentPrayer,
                currentTime: this.getCurrentTime(),
                duration: this.getDuration()
            });
        }
        
        // إرسال حدث مخصص
        window.dispatchEvent(new CustomEvent('adhanStateChange', {
            detail: {
                isPlaying: this.isPlaying,
                currentPrayer: this.currentPrayer
            }
        }));
    }

    /**
     * اختبار تشغيل الصوت
     * @returns {Promise<boolean>}
     */
    async test() {
        try {
            // تشغيل لثانية واحدة ثم إيقاف
            await this.play('test');
            
            return new Promise((resolve) => {
                setTimeout(() => {
                    this.stop();
                    resolve(true);
                }, 2000);
            });
            
        } catch (error) {
            return false;
        }
    }

    /**
     * تنظيف الموارد
     */
    destroy() {
        this.stop();
        if (this.audio) {
            this.audio.src = '';
            this.audio = null;
        }
    }
}

// تصدير نسخة واحدة
export const adhanPlayer = new AdhanPlayer();

export default adhanPlayer;
