/**
 * تطبيق تقويم رمضان - الملف الرئيسي
 * يدمج جميع الوحدات: الموقع، الصلاة، الإشعارات، الأذان
 * 
 * @author Ramadan Calendar PWA
 * @version 2.0.0
 */

// ==================== المتغيرات العامة ====================
let prayerEngine = null;
let locationManager = null;
let notificationManager = null;
let localScheduler = null;
let database = null;
let adhanPlayer = null;
let swRegistration = null;

let currentLocation = null;
let currentPrayerTimes = null;
let isOnline = navigator.onLine;

// ==================== تهيئة التطبيق ====================
document.addEventListener('DOMContentLoaded', async () => {
    console.log('🌙 تقويم رمضان - جاري التحميل...');
    
    try {
        // تهيئة الوحدات
        await initializeModules();
        
        // تسجيل Service Worker
        await registerServiceWorker();
        
        // الحصول على الموقع
        await initializeLocation();
        
        // حساب أوقات الصلاة
        await calculatePrayerTimes();
        
        // تهيئة الإشعارات
        await initializeNotifications();
        
        // تهيئة مشغل الأذان
        initializeAdhanPlayer();
        
        // تهيئة واجهة المستخدم
        setupUI();
        
        // جدولة التحديثات
        setupAutoUpdates();
        
        console.log('✅ تم تحميل التطبيق بنجاح');
        
    } catch (error) {
        console.error('❌ خطأ في التهيئة:', error);
        showError('حدث خطأ في تحميل التطبيق');
    }
});

// ==================== تهيئة الوحدات ====================
async function initializeModules() {
    // محرك الصلاة
    prayerEngine = new PrayerEngine({
        method: CalculationMethods.IRAQ_JAFARI,
        madhab: Madhab.SHAFI,
        imsakMinutes: 10
    });
    
    // مدير الموقع
    locationManager = new LocationManager();
    
    // مدير الإشعارات
    notificationManager = new NotificationManager();
    
    // جدولة محلية
    localScheduler = new LocalNotificationScheduler();
    
    // قاعدة البيانات
    if (typeof Database !== 'undefined') {
        database = new Database();
        await database.init();
    }
    
    console.log('✅ تم تهيئة الوحدات');
}

// ==================== Service Worker ====================
async function registerServiceWorker() {
    if (!('serviceWorker' in navigator)) {
        console.warn('Service Workers غير مدعومة');
        return;
    }
    
    try {
        swRegistration = await navigator.serviceWorker.register('/service-worker.js');
        console.log('✅ تم تسجيل Service Worker');
        
        // استماع للرسائل
        navigator.serviceWorker.addEventListener('message', handleSWMessage);
        
        // تهيئة مدير الإشعارات
        await notificationManager.init(swRegistration);
        
    } catch (error) {
        console.error('❌ فشل تسجيل Service Worker:', error);
    }
}

function handleSWMessage(event) {
    console.log('📨 رسالة من SW:', event.data);
    
    if (event.data.type === 'PLAY_ADHAN') {
        playAdhan(event.data.prayerKey);
    }
    
    if (event.data.type === 'RESCHEDULE_NOTIFICATIONS') {
        rescheduleNotifications();
    }
}

// ==================== الموقع ====================
async function initializeLocation() {
    // محاولة استرجاع الموقع المحفوظ
    let savedLocation = null;
    if (database) {
        savedLocation = await database.getLocation();
    }
    
    // الحصول على الموقع الحالي
    showLoadingMessage('جاري تحديد موقعك...');
    
    currentLocation = await locationManager.getCurrentPosition({
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
    });
    
    // حفظ الموقع
    if (database && currentLocation) {
        await database.saveLocation({
            id: 'current',
            ...currentLocation,
            updatedAt: Date.now()
        });
    }
    
    // بدء مراقبة الموقع
    locationManager.startWatching(onLocationChange, onLocationError);
    
    // تحديث عرض الموقع
    updateLocationDisplay();
    
    console.log('📍 الموقع:', currentLocation);
}

async function onLocationChange(newLocation, distance) {
    console.log(`📍 تغير الموقع - المسافة: ${Math.round(distance)}م`);
    
    currentLocation = newLocation;
    
    // إعادة حساب الأوقات
    await calculatePrayerTimes();
    
    // تحديث السيرفر إذا كان هناك اشتراك
    if (notificationManager.isSubscribed && isOnline) {
        await notificationManager.updateServerLocation(newLocation);
    }
    
    // إعادة جدولة الإشعارات المحلية
    await scheduleLocalNotifications();
    
    updateLocationDisplay();
}

function onLocationError(error) {
    console.warn('⚠️ خطأ في الموقع:', error.message);
}

function updateLocationDisplay() {
    const locationElement = document.getElementById('location-name');
    if (locationElement && currentLocation) {
        if (currentLocation.isDefault) {
            locationElement.textContent = 'بغداد، العراق (افتراضي)';
        } else {
            // الحصول على اسم المدينة
            locationManager.getCityName(currentLocation.latitude, currentLocation.longitude)
                .then(name => {
                    locationElement.textContent = name;
                });
        }
    }
}

// ==================== أوقات الصلاة ====================
async function calculatePrayerTimes() {
    if (!currentLocation) {
        console.warn('لا يوجد موقع لحساب الأوقات');
        return;
    }
    
    const today = new Date();
    
    currentPrayerTimes = prayerEngine.calculate(
        currentLocation.latitude,
        currentLocation.longitude,
        today
    );
    
    // حفظ في قاعدة البيانات
    if (database) {
        await database.savePrayerTimes({
            id: today.toISOString().split('T')[0],
            date: today,
            times: currentPrayerTimes,
            location: currentLocation
        });
    }
    
    // تحديث العرض
    updatePrayerTimesDisplay();
    updateNextPrayerDisplay();
    
    console.log('🕌 أوقات الصلاة:', currentPrayerTimes);
}

function updatePrayerTimesDisplay() {
    if (!currentPrayerTimes) return;
    
    const prayers = ['imsak', 'fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
    
    prayers.forEach(prayer => {
        const element = document.getElementById(`time-${prayer}`);
        if (element && currentPrayerTimes[prayer]) {
            element.textContent = prayerEngine.formatTime(currentPrayerTimes[prayer]);
        }
    });
}

function updateNextPrayerDisplay() {
    if (!currentPrayerTimes) return;
    
    const nextPrayer = prayerEngine.getNextPrayer(currentPrayerTimes);
    
    const nameElement = document.getElementById('next-prayer-name');
    const timeElement = document.getElementById('next-prayer-time');
    const countdownElement = document.getElementById('countdown');
    
    if (nameElement) {
        nameElement.textContent = nextPrayer.nameAr;
    }
    
    if (timeElement && nextPrayer.time) {
        timeElement.textContent = prayerEngine.formatTime(nextPrayer.time);
    }
    
    // تحديث العد التنازلي
    if (countdownElement && nextPrayer.remaining) {
        updateCountdown(nextPrayer.time);
    }
    
    // تحديد الصلاة الحالية
    highlightCurrentPrayer();
}

function updateCountdown(targetTime) {
    const countdownElement = document.getElementById('countdown');
    if (!countdownElement || !targetTime) return;
    
    const update = () => {
        const now = new Date();
        const diff = targetTime - now;
        
        if (diff <= 0) {
            countdownElement.textContent = 'حان الوقت!';
            // إعادة حساب للصلاة التالية
            setTimeout(updateNextPrayerDisplay, 1000);
            return;
        }
        
        const hours = Math.floor(diff / 3600000);
        const minutes = Math.floor((diff % 3600000) / 60000);
        const seconds = Math.floor((diff % 60000) / 1000);
        
        countdownElement.textContent = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    };
    
    update();
    setInterval(update, 1000);
}

function highlightCurrentPrayer() {
    const currentPrayer = prayerEngine.getCurrentPrayer(currentPrayerTimes);
    
    // إزالة التحديد السابق
    document.querySelectorAll('.prayer-row').forEach(row => {
        row.classList.remove('current', 'next');
    });
    
    // تحديد الصلاة الحالية
    if (currentPrayer) {
        const currentRow = document.getElementById(`row-${currentPrayer.name}`);
        if (currentRow) {
            currentRow.classList.add('current');
        }
    }
    
    // تحديد الصلاة التالية
    const nextPrayer = prayerEngine.getNextPrayer(currentPrayerTimes);
    if (nextPrayer && !nextPrayer.isNextDay) {
        const nextRow = document.getElementById(`row-${nextPrayer.name}`);
        if (nextRow) {
            nextRow.classList.add('next');
        }
    }
}

// ==================== الإشعارات ====================
async function initializeNotifications() {
    const permission = notificationManager.getPermissionState();
    
    if (permission === 'default') {
        // عرض طلب الإذن
        showNotificationPrompt();
    } else if (permission === 'granted') {
        await enableNotifications();
    }
    
    updateNotificationUI();
}

async function enableNotifications() {
    // محاولة الاشتراك في Push
    if (isOnline && notificationManager.vapidPublicKey) {
        await notificationManager.subscribe(currentLocation);
    }
    
    // جدولة الإشعارات المحلية كـ fallback
    await scheduleLocalNotifications();
}

async function scheduleLocalNotifications() {
    if (!currentPrayerTimes || !swRegistration) return;
    
    // مسح الجدولة السابقة
    localScheduler.cancelAll();
    
    const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    const prayerEmojis = {
        fajr: '🌙',
        dhuhr: '☀️',
        asr: '🌤️',
        maghrib: '🌆',
        isha: '🌃'
    };
    
    const now = new Date();
    
    for (const prayer of prayers) {
        const time = currentPrayerTimes[prayer];
        if (!time) continue;
        
        // إشعار قبل دقيقة
        const notifyTime = new Date(time.getTime() - 60000);
        
        if (notifyTime > now) {
            localScheduler.schedule(
                `prayer-${prayer}-${Date.now()}`,
                notifyTime,
                {
                    title: `${prayerEmojis[prayer]} حان وقت صلاة ${PrayerNames[prayer.toUpperCase()]}`,
                    body: 'اضغط لتشغيل الأذان',
                    tag: `prayer-${prayer}`,
                    data: {
                        prayer: prayer,
                        playAdhan: true
                    },
                    actions: [
                        { action: 'play-adhan', title: '🔊 تشغيل الأذان' }
                    ]
                },
                swRegistration
            );
        }
    }
    
    console.log(`📅 تم جدولة ${localScheduler.getScheduledCount()} إشعار محلي`);
}

async function rescheduleNotifications() {
    await calculatePrayerTimes();
    await scheduleLocalNotifications();
    
    if (notificationManager.isSubscribed && isOnline) {
        await notificationManager.updateServerLocation(currentLocation);
    }
}

function showNotificationPrompt() {
    const prompt = document.getElementById('notification-prompt');
    if (prompt) {
        prompt.style.display = 'block';
    }
}

function updateNotificationUI() {
    const status = notificationManager.getStatus();
    const toggleBtn = document.getElementById('notification-toggle');
    const statusText = document.getElementById('notification-status');
    
    if (toggleBtn) {
        toggleBtn.textContent = status.isSubscribed ? 'إيقاف الإشعارات' : 'تفعيل الإشعارات';
        toggleBtn.classList.toggle('active', status.isSubscribed);
    }
    
    if (statusText) {
        if (status.permission === 'denied') {
            statusText.textContent = 'الإشعارات محظورة في المتصفح';
        } else if (status.isSubscribed) {
            statusText.textContent = 'الإشعارات مفعلة ✓';
        } else {
            statusText.textContent = 'الإشعارات غير مفعلة';
        }
    }
}

// ==================== الأذان ====================
function initializeAdhanPlayer() {
    // التحقق من معاملات URL
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('playAdhan') === 'true') {
        const prayer = urlParams.get('prayer');
        playAdhan(prayer);
        // تنظيف URL
        window.history.replaceState({}, document.title, window.location.pathname);
    }
    
    // إعداد زر تشغيل الأذان
    const playBtn = document.getElementById('play-adhan');
    if (playBtn) {
        playBtn.addEventListener('click', () => playAdhan());
    }
}

function playAdhan(prayerName = '') {
    const audio = document.getElementById('adhan-audio') || createAdhanAudio();
    
    audio.currentTime = 0;
    audio.play()
        .then(() => {
            console.log('🔊 جاري تشغيل الأذان');
            showAdhanOverlay(prayerName);
        })
        .catch(error => {
            console.error('❌ فشل تشغيل الأذان:', error);
            // محاولة بعد تفاعل المستخدم
            showPlayAdhanButton(prayerName);
        });
}

function createAdhanAudio() {
    const audio = document.createElement('audio');
    audio.id = 'adhan-audio';
    audio.src = '/assets/audio/adhan.mp3';
    audio.preload = 'auto';
    document.body.appendChild(audio);
    return audio;
}

function showAdhanOverlay(prayerName) {
    let overlay = document.getElementById('adhan-overlay');
    
    if (!overlay) {
        overlay = document.createElement('div');
        overlay.id = 'adhan-overlay';
        overlay.className = 'adhan-overlay';
        overlay.innerHTML = `
            <div class="adhan-content">
                <div class="adhan-icon">🕌</div>
                <h2 id="adhan-prayer-name">حان وقت الصلاة</h2>
                <div class="adhan-animation">
                    <div class="wave"></div>
                    <div class="wave"></div>
                    <div class="wave"></div>
                </div>
                <button id="stop-adhan" class="btn btn-primary">إيقاف الأذان</button>
            </div>
        `;
        document.body.appendChild(overlay);
        
        document.getElementById('stop-adhan').addEventListener('click', stopAdhan);
    }
    
    if (prayerName) {
        document.getElementById('adhan-prayer-name').textContent = 
            `حان وقت صلاة ${PrayerNames[prayerName.toUpperCase()] || prayerName}`;
    }
    
    overlay.classList.add('active');
    
    // إخفاء عند انتهاء الأذان
    const audio = document.getElementById('adhan-audio');
    if (audio) {
        audio.onended = () => {
            overlay.classList.remove('active');
        };
    }
}

function stopAdhan() {
    const audio = document.getElementById('adhan-audio');
    if (audio) {
        audio.pause();
        audio.currentTime = 0;
    }
    
    const overlay = document.getElementById('adhan-overlay');
    if (overlay) {
        overlay.classList.remove('active');
    }
}

function showPlayAdhanButton(prayerName) {
    let button = document.getElementById('manual-play-adhan');
    
    if (!button) {
        button = document.createElement('button');
        button.id = 'manual-play-adhan';
        button.className = 'floating-btn';
        button.innerHTML = '🔊 تشغيل الأذان';
        document.body.appendChild(button);
    }
    
    button.style.display = 'block';
    button.onclick = () => {
        playAdhan(prayerName);
        button.style.display = 'none';
    };
}

// ==================== واجهة المستخدم ====================
function setupUI() {
    // تحديث التاريخ
    updateDateDisplay();
    
    // أزرار الإشعارات
    const notifToggle = document.getElementById('notification-toggle');
    if (notifToggle) {
        notifToggle.addEventListener('click', toggleNotifications);
    }
    
    const allowNotif = document.getElementById('allow-notifications');
    if (allowNotif) {
        allowNotif.addEventListener('click', async () => {
            const permission = await notificationManager.requestPermission();
            if (permission === 'granted') {
                await enableNotifications();
                hideNotificationPrompt();
            }
            updateNotificationUI();
        });
    }
    
    const denyNotif = document.getElementById('deny-notifications');
    if (denyNotif) {
        denyNotif.addEventListener('click', hideNotificationPrompt);
    }
    
    // زر تحديث الموقع
    const refreshLocation = document.getElementById('refresh-location');
    if (refreshLocation) {
        refreshLocation.addEventListener('click', async () => {
            showLoadingMessage('جاري تحديث الموقع...');
            await initializeLocation();
            await calculatePrayerTimes();
            hideLoadingMessage();
        });
    }
    
    // زر المشاركة
    const shareBtn = document.getElementById('share-btn');
    if (shareBtn) {
        shareBtn.addEventListener('click', shareApp);
    }
    
    // حالة الاتصال
    window.addEventListener('online', () => {
        isOnline = true;
        showToast('تم استعادة الاتصال');
        syncWithServer();
    });
    
    window.addEventListener('offline', () => {
        isOnline = false;
        showToast('أنت الآن بدون اتصال');
    });
}

function updateDateDisplay() {
    const dateElement = document.getElementById('current-date');
    if (dateElement) {
        const today = new Date();
        const options = {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        };
        dateElement.textContent = today.toLocaleDateString('ar-IQ', options);
    }
    
    // التاريخ الهجري (تقريبي)
    const hijriElement = document.getElementById('hijri-date');
    if (hijriElement) {
        try {
            const hijriDate = new Intl.DateTimeFormat('ar-SA-u-ca-islamic', {
                day: 'numeric',
                month: 'long',
                year: 'numeric'
            }).format(new Date());
            hijriElement.textContent = hijriDate;
        } catch {
            hijriElement.textContent = '';
        }
    }
}

async function toggleNotifications() {
    if (notificationManager.isSubscribed) {
        await notificationManager.unsubscribe();
        localScheduler.cancelAll();
    } else {
        const permission = await notificationManager.requestPermission();
        if (permission === 'granted') {
            await enableNotifications();
        }
    }
    updateNotificationUI();
}

function hideNotificationPrompt() {
    const prompt = document.getElementById('notification-prompt');
    if (prompt) {
        prompt.style.display = 'none';
    }
}

async function syncWithServer() {
    if (!isOnline) return;
    
    // تحديث الموقع في السيرفر
    if (notificationManager.isSubscribed && currentLocation) {
        await notificationManager.updateServerLocation(currentLocation);
    }
}

function shareApp() {
    if (navigator.share) {
        navigator.share({
            title: 'تقويم رمضان - إمساكية',
            text: 'تطبيق مواقيت الصلاة والأذان',
            url: window.location.href
        });
    } else {
        // نسخ الرابط
        navigator.clipboard.writeText(window.location.href)
            .then(() => showToast('تم نسخ الرابط'));
    }
}

// ==================== التحديثات التلقائية ====================
function setupAutoUpdates() {
    // تحديث عند منتصف الليل
    scheduleMidnightUpdate();
    
    // فحص التوقيت كل دقيقة
    setInterval(() => {
        updateNextPrayerDisplay();
    }, 60000);
}

function scheduleMidnightUpdate() {
    const now = new Date();
    const midnight = new Date(now);
    midnight.setHours(24, 0, 0, 0);
    
    const msUntilMidnight = midnight - now;
    
    setTimeout(async () => {
        console.log('🌙 منتصف الليل - تحديث الأوقات');
        await calculatePrayerTimes();
        await scheduleLocalNotifications();
        updateDateDisplay();
        
        // جدولة التحديث التالي
        scheduleMidnightUpdate();
    }, msUntilMidnight);
}

// ==================== دوال مساعدة ====================
function showLoadingMessage(message) {
    let loading = document.getElementById('loading-overlay');
    if (!loading) {
        loading = document.createElement('div');
        loading.id = 'loading-overlay';
        loading.className = 'loading-overlay';
        loading.innerHTML = `
            <div class="loading-content">
                <div class="spinner"></div>
                <p id="loading-message">${message}</p>
            </div>
        `;
        document.body.appendChild(loading);
    } else {
        document.getElementById('loading-message').textContent = message;
    }
    loading.classList.add('active');
}

function hideLoadingMessage() {
    const loading = document.getElementById('loading-overlay');
    if (loading) {
        loading.classList.remove('active');
    }
}

function showToast(message, duration = 3000) {
    let toast = document.getElementById('toast');
    if (!toast) {
        toast = document.createElement('div');
        toast.id = 'toast';
        toast.className = 'toast';
        document.body.appendChild(toast);
    }
    
    toast.textContent = message;
    toast.classList.add('show');
    
    setTimeout(() => {
        toast.classList.remove('show');
    }, duration);
}

function showError(message) {
    console.error(message);
    showToast(message, 5000);
}

// ==================== تصدير للاختبار ====================
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        calculatePrayerTimes,
        scheduleLocalNotifications,
        playAdhan
    };
}
