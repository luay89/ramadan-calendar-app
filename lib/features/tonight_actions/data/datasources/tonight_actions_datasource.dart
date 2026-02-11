import 'package:hijri/hijri_calendar.dart';
import '../../domain/entities/tonight_action.dart';

/// مصدر بيانات أعمال الليلة
class TonightActionsDataSource {
  /// الحصول على أعمال الليلة بناءً على التاريخ الهجري
  List<TonightAction> getTonightActions(HijriCalendar hijriDate) {
    final List<TonightAction> actions = [];

    // الأعمال العامة لكل ليلة
    actions.addAll(_getGeneralNightActions());

    // أعمال ليلة الجمعة
    if (_isFridayNight(hijriDate)) {
      actions.addAll(_getFridayNightActions());
    }

    // أعمال شهر رمضان
    if (hijriDate.hMonth == 9) {
      actions.addAll(_getRamadanNightActions(hijriDate.hDay));
    }

    // أعمال شهر رجب
    if (hijriDate.hMonth == 7) {
      actions.addAll(_getRajabNightActions(hijriDate.hDay));
    }

    // أعمال شهر شعبان
    if (hijriDate.hMonth == 8) {
      actions.addAll(_getShabanNightActions(hijriDate.hDay));
    }

    // أعمال شهر محرم
    if (hijriDate.hMonth == 1) {
      actions.addAll(_getMuharramNightActions(hijriDate.hDay));
    }

    // أعمال شهر ذي الحجة
    if (hijriDate.hMonth == 12) {
      actions.addAll(_getDhulHijjahNightActions(hijriDate.hDay));
    }

    return actions;
  }

  /// هل الليلة هي ليلة الجمعة؟
  bool _isFridayNight(HijriCalendar hijriDate) {
    // ليلة الجمعة تبدأ من مغرب الخميس
    final gregorian = hijriDate.hijriToGregorian(
      hijriDate.hYear,
      hijriDate.hMonth,
      hijriDate.hDay,
    );
    return gregorian.weekday == DateTime.thursday;
  }

  /// الأعمال العامة لكل ليلة
  List<TonightAction> _getGeneralNightActions() {
    return [
      const TonightAction(
        id: 'general_1',
        title: 'صلاة الليل',
        description: 'صلاة النافلة ١١ ركعة في الثلث الأخير من الليل',
        priority: ActionPriority.high,
        timeFrame: ActionTimeFrame.lastThird,
      ),
      const TonightAction(
        id: 'general_2',
        title: 'الاستغفار',
        description: 'الاستغفار ٧٠ مرة',
        arabicText: 'أَسْتَغْفِرُ اللهَ رَبِّي وَأَتُوبُ إِلَيْهِ',
        repeatCount: 70,
        timeFrame: ActionTimeFrame.lastThird,
      ),
      const TonightAction(
        id: 'general_3',
        title: 'قراءة القرآن',
        description: 'قراءة ما تيسر من القرآن الكريم',
        priority: ActionPriority.normal,
        timeFrame: ActionTimeFrame.anytime,
      ),
    ];
  }

  /// أعمال ليلة الجمعة
  List<TonightAction> _getFridayNightActions() {
    return [
      const TonightAction(
        id: 'friday_1',
        title: 'دعاء كميل',
        description: 'قراءة دعاء كميل بن زياد',
        priority: ActionPriority.high,
        timeFrame: ActionTimeFrame.anytime,
        relatedDuaId: 'dua_kumayl',
      ),
      const TonightAction(
        id: 'friday_2',
        title: 'زيارة الإمام الحسين (ع)',
        description: 'قراءة زيارة الإمام الحسين في ليلة الجمعة',
        priority: ActionPriority.high,
        timeFrame: ActionTimeFrame.anytime,
        relatedDuaId: 'ziyarat_warith',
      ),
      const TonightAction(
        id: 'friday_3',
        title: 'سورة الكهف',
        description: 'قراءة سورة الكهف',
        priority: ActionPriority.normal,
        timeFrame: ActionTimeFrame.anytime,
      ),
      const TonightAction(
        id: 'friday_4',
        title: 'الصلاة على محمد وآل محمد',
        description: 'الإكثار من الصلاة على النبي وآله',
        arabicText: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَآلِ مُحَمَّدٍ',
        repeatCount: 100,
        priority: ActionPriority.high,
        timeFrame: ActionTimeFrame.anytime,
      ),
    ];
  }

  /// أعمال ليالي شهر رمضان
  List<TonightAction> _getRamadanNightActions(int day) {
    final actions = <TonightAction>[
      const TonightAction(
        id: 'ramadan_general_1',
        title: 'دعاء الإفتتاح',
        description: 'قراءة دعاء الإفتتاح بعد صلاة العشاء',
        priority: ActionPriority.high,
        timeFrame: ActionTimeFrame.afterMaghrib,
      ),
      const TonightAction(
        id: 'ramadan_general_2',
        title: 'صلاة النوافل',
        description: 'صلاة ١٠٠٠ ركعة موزعة على الشهر',
        priority: ActionPriority.normal,
        timeFrame: ActionTimeFrame.anytime,
      ),
    ];

    // ليالي القدر
    if (day == 19 || day == 21 || day == 23) {
      actions.addAll([
        const TonightAction(
          id: 'qadr_1',
          title: 'الغسل',
          description: 'غسل ليلة القدر قبل المغرب',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.afterMaghrib,
        ),
        const TonightAction(
          id: 'qadr_2',
          title: 'دعاء الجوشن الكبير',
          description: 'قراءة دعاء الجوشن الكبير',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
          relatedDuaId: 'dua_jawshan_kabir',
        ),
        const TonightAction(
          id: 'qadr_3',
          title: 'وضع القرآن على الرأس',
          description: 'وضع المصحف الشريف على الرأس والدعاء',
          arabicText:
              'اللَّهُمَّ بِحَقِّ هذَا الْقُرْآنِ وَبِحَقِّ مَنْ أَرْسَلْتَهُ بِهِ...',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
        ),
        const TonightAction(
          id: 'qadr_4',
          title: 'إحياء الليل',
          description: 'إحياء الليل بالعبادة والدعاء',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
        ),
        TonightAction(
          id: 'qadr_5',
          title: day == 19 ? 'ذكرى ضربة أمير المؤمنين' : 'ليلة القدر',
          description: day == 19
              ? 'ليلة ضربة الإمام علي (ع) وهي إحدى ليالي القدر'
              : day == 21
              ? 'ليلة شهادة الإمام علي (ع) وأفضل ليالي القدر'
              : 'ليلة القدر - ليلة الثالث والعشرين',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
        ),
      ]);
    }

    // ليلة القدر الكبرى (21)
    if (day == 21) {
      actions.add(
        const TonightAction(
          id: 'qadr_21_special',
          title: 'زيارة أمير المؤمنين',
          description: 'زيارة الإمام علي (ع) في ليلة شهادته',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
          relatedDuaId: 'ziyarat_aminallah',
        ),
      );
    }

    return actions;
  }

  /// أعمال ليالي شهر رجب
  List<TonightAction> _getRajabNightActions(int day) {
    final actions = <TonightAction>[];

    // ليلة أول رجب
    if (day == 1) {
      actions.addAll([
        const TonightAction(
          id: 'rajab_1_1',
          title: 'صلاة أول ليلة من رجب',
          description: 'صلاة عشرين ركعة',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.afterMaghrib,
        ),
        const TonightAction(
          id: 'rajab_1_2',
          title: 'الدعاء عند رؤية الهلال',
          description: 'دعاء رؤية هلال شهر رجب',
          arabicText:
              'اللَّهُمَّ أَهِلَّهُ عَلَيْنَا بِالْأَمْنِ وَالْإِيمَانِ...',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.afterMaghrib,
        ),
      ]);
    }

    // ليلة الرغائب (أول جمعة من رجب)
    // ليلة النصف من رجب
    if (day == 15) {
      actions.addAll([
        const TonightAction(
          id: 'rajab_15_1',
          title: 'الغسل',
          description: 'غسل ليلة النصف من رجب',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.afterMaghrib,
        ),
        const TonightAction(
          id: 'rajab_15_2',
          title: 'إحياء الليل',
          description: 'إحياء ليلة النصف من رجب بالعبادة',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
        ),
      ]);
    }

    // ليلة المبعث (27 رجب)
    if (day == 27) {
      actions.addAll([
        const TonightAction(
          id: 'rajab_27_1',
          title: 'الغسل',
          description: 'غسل ليلة المبعث النبوي الشريف',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.afterMaghrib,
        ),
        const TonightAction(
          id: 'rajab_27_2',
          title: 'زيارة أمير المؤمنين',
          description: 'زيارة الإمام علي (ع)',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
          relatedDuaId: 'ziyarat_aminallah',
        ),
        const TonightAction(
          id: 'rajab_27_3',
          title: 'إحياء الليل',
          description: 'إحياء ليلة المبعث بالصلاة والدعاء',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
        ),
      ]);
    }

    return actions;
  }

  /// أعمال ليالي شهر شعبان
  List<TonightAction> _getShabanNightActions(int day) {
    final actions = <TonightAction>[];

    // ليلة النصف من شعبان
    if (day == 15) {
      actions.addAll([
        const TonightAction(
          id: 'shaban_15_1',
          title: 'الغسل',
          description: 'غسل ليلة النصف من شعبان',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.afterMaghrib,
        ),
        const TonightAction(
          id: 'shaban_15_2',
          title: 'زيارة الإمام الحسين',
          description: 'زيارة الإمام الحسين (ع) في ليلة ولادة الإمام المهدي',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
          relatedDuaId: 'ziyarat_warith',
        ),
        const TonightAction(
          id: 'shaban_15_3',
          title: 'دعاء كميل',
          description: 'قراءة دعاء كميل',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
          relatedDuaId: 'dua_kumayl',
        ),
        const TonightAction(
          id: 'shaban_15_4',
          title: 'صلاة مائة ركعة',
          description: 'صلاة مائة ركعة، في كل ركعة الحمد مرة والتوحيد عشر مرات',
          priority: ActionPriority.normal,
          timeFrame: ActionTimeFrame.anytime,
        ),
        const TonightAction(
          id: 'shaban_15_5',
          title: 'إحياء الليل',
          description:
              'إحياء ليلة النصف من شعبان - ليلة ولادة الإمام المهدي (عج)',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
        ),
      ]);
    }

    return actions;
  }

  /// أعمال ليالي شهر محرم
  List<TonightAction> _getMuharramNightActions(int day) {
    final actions = <TonightAction>[];

    // ليلة عاشوراء
    if (day == 10) {
      actions.addAll([
        const TonightAction(
          id: 'muharram_10_1',
          title: 'إحياء ليلة عاشوراء',
          description: 'إحياء ليلة عاشوراء بالعبادة والبكاء على الإمام الحسين',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
        ),
        const TonightAction(
          id: 'muharram_10_2',
          title: 'زيارة الإمام الحسين',
          description: 'قراءة زيارة عاشوراء',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
          relatedDuaId: 'ziyarat_ashura',
        ),
      ]);
    }

    return actions;
  }

  /// أعمال ليالي شهر ذي الحجة
  List<TonightAction> _getDhulHijjahNightActions(int day) {
    final actions = <TonightAction>[];

    // ليلة عيد الأضحى
    if (day == 10) {
      actions.addAll([
        const TonightAction(
          id: 'dhulhijjah_10_1',
          title: 'إحياء ليلة العيد',
          description: 'إحياء ليلة عيد الأضحى بالعبادة',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
        ),
      ]);
    }

    // ليلة عيد الغدير
    if (day == 18) {
      actions.addAll([
        const TonightAction(
          id: 'dhulhijjah_18_1',
          title: 'الغسل',
          description: 'غسل ليلة عيد الغدير',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.afterMaghrib,
        ),
        const TonightAction(
          id: 'dhulhijjah_18_2',
          title: 'إحياء الليل',
          description: 'إحياء ليلة عيد الغدير الأغر',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
        ),
        const TonightAction(
          id: 'dhulhijjah_18_3',
          title: 'صلاة ليلة الغدير',
          description: 'صلاة اثنتي عشرة ركعة',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
        ),
      ]);
    }

    // ليلة المباهلة
    if (day == 24) {
      actions.addAll([
        const TonightAction(
          id: 'dhulhijjah_24_1',
          title: 'الغسل',
          description: 'غسل ليلة المباهلة',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.afterMaghrib,
        ),
        const TonightAction(
          id: 'dhulhijjah_24_2',
          title: 'إحياء ليلة المباهلة',
          description: 'إحياء ليلة المباهلة بالعبادة والدعاء',
          priority: ActionPriority.high,
          timeFrame: ActionTimeFrame.anytime,
        ),
      ]);
    }

    return actions;
  }
}
