import '../../domain/entities/laylatal_qadr_action.dart';

/// مصدر البيانات المحلية لرمضان
class RamadanLocalDataSource {
  /// الأعمال المشتركة لجميع ليالي القدر
  List<LaylatalQadrAction> getCommonActions() {
    return [
      const LaylatalQadrAction(
        id: 'common_ghusl',
        title: 'الغسل',
        description: 'يستحب الغسل في ليالي القدر، ووقته من أول الليل إلى آخره',
        type: ActionType.ghusl,
        order: 1,
      ),
      const LaylatalQadrAction(
        id: 'common_prayer_2rakaat',
        title: 'صلاة ركعتين',
        description:
            'يقرأ في كل ركعة الحمد مرة والإخلاص سبع مرات، ثم يستغفر 70 مرة',
        type: ActionType.prayer,
        repeatCount: 70,
        order: 2,
      ),
      const LaylatalQadrAction(
        id: 'common_quran_open',
        title: 'فتح المصحف',
        description: 'يفتح المصحف ويضعه بين يديه ويقول الدعاء',
        arabicText:
            'اللّهُمَّ إنّي أَسْأَلُكَ بِكِتابِكَ الْمُنْزَلِ وَما فِيهِ، وَفِيهِ اسْمُكَ الاَْكْبَرُ وَأَسْماؤُكَ الْحُسْنى، وَما يُخافُ وَيُرْجى، أَنْ تَجْعَلَني مِنْ عُتَقائِكَ مِنَ النّارِ',
        type: ActionType.quran,
        order: 3,
      ),
      const LaylatalQadrAction(
        id: 'common_quran_head',
        title: 'وضع القرآن على الرأس',
        description: 'يضع المصحف على رأسه ويقول الدعاء',
        arabicText:
            'اللّهُمَّ بِحَقِّ هذَا الْقُرْآنِ، وَبِحَقِّ مَنْ أَرْسَلْتَهُ بِهِ، وَبِحَقِّ كُلِّ مُؤْمِن مَدَحْتَهُ فِيهِ، وَبِحَقِّكَ عَلَيْهِمْ، فَلا أَحَدَ أَعْرَفُ بِحَقِّكَ مِنْكَ',
        type: ActionType.quran,
        order: 4,
      ),
      const LaylatalQadrAction(
        id: 'common_istighfar',
        title: 'الاستغفار',
        description: 'أستغفر الله ربي وأتوب إليه - 100 مرة',
        arabicText: 'أَسْتَغْفِرُ اللهَ رَبّي وَأَتُوبُ إِلَيْهِ',
        type: ActionType.dhikr,
        repeatCount: 100,
        order: 5,
      ),
      const LaylatalQadrAction(
        id: 'common_allahumma',
        title: 'اللهم العن قتلة أمير المؤمنين',
        description: 'يقال 100 مرة',
        arabicText: 'اللّهُمَّ الْعَنْ قَتَلَةَ أَمِيرِ الْمُؤْمِنِينَ',
        type: ActionType.dhikr,
        repeatCount: 100,
        order: 6,
      ),
      const LaylatalQadrAction(
        id: 'common_dua_jawshan',
        title: 'دعاء الجوشن الكبير',
        description: 'من أفضل الأدعية في ليالي القدر',
        type: ActionType.dua,
        order: 7,
      ),
      const LaylatalQadrAction(
        id: 'common_ziyarat_imam_hussain',
        title: 'زيارة الإمام الحسين (ع)',
        description: 'يستحب زيارة الإمام الحسين عليه السلام في ليالي القدر',
        type: ActionType.ziyarat,
        order: 8,
      ),
      const LaylatalQadrAction(
        id: 'common_quran_surahs',
        title: 'قراءة سور من القرآن',
        description: 'يستحب قراءة سورة العنكبوت والروم والدخان',
        type: ActionType.quran,
        order: 9,
      ),
      const LaylatalQadrAction(
        id: 'common_dua_makarim',
        title: 'دعاء مكارم الأخلاق',
        description: 'من أدعية الصحيفة السجادية',
        type: ActionType.dua,
        order: 10,
      ),
    ];
  }

  /// أعمال ليلة 19
  List<LaylatalQadrAction> getNight19SpecificActions() {
    return [
      const LaylatalQadrAction(
        id: 'night19_dua_iftitah',
        title: 'دعاء الافتتاح',
        description: 'يستحب قراءة دعاء الافتتاح في هذه الليلة',
        type: ActionType.dua,
        order: 11,
      ),
      const LaylatalQadrAction(
        id: 'night19_prayer_special',
        title: 'صلاة ليلة 19',
        description: 'صلاة مخصوصة لهذه الليلة',
        type: ActionType.prayer,
        order: 12,
      ),
    ];
  }

  /// أعمال ليلة 21 (ليلة شهادة أمير المؤمنين)
  List<LaylatalQadrAction> getNight21SpecificActions() {
    return [
      const LaylatalQadrAction(
        id: 'night21_martyrdom',
        title: 'ذكرى شهادة أمير المؤمنين',
        description: 'هذه الليلة ليلة شهادة الإمام علي عليه السلام',
        type: ActionType.other,
        order: 11,
      ),
      const LaylatalQadrAction(
        id: 'night21_ziyarat_ali',
        title: 'زيارة أمير المؤمنين (ع)',
        description: 'يستحب زيارة الإمام علي عليه السلام خاصة في هذه الليلة',
        type: ActionType.ziyarat,
        order: 12,
      ),
      const LaylatalQadrAction(
        id: 'night21_dua_ali',
        title: 'الدعاء لأمير المؤمنين',
        description: 'الصلاة على أمير المؤمنين والدعاء له',
        type: ActionType.dua,
        order: 13,
      ),
    ];
  }

  /// أعمال ليلة 23 (أرجح ليالي القدر)
  List<LaylatalQadrAction> getNight23SpecificActions() {
    return [
      const LaylatalQadrAction(
        id: 'night23_most_likely',
        title: 'أرجح ليالي القدر',
        description: 'هذه الليلة أرجح ليالي القدر، فأكثروا من العبادة',
        type: ActionType.other,
        order: 11,
      ),
      const LaylatalQadrAction(
        id: 'night23_ihya',
        title: 'إحياء الليل كاملاً',
        description: 'يستحب إحياء هذه الليلة بالكامل بالعبادة والدعاء',
        type: ActionType.prayer,
        order: 12,
      ),
      const LaylatalQadrAction(
        id: 'night23_100_rakaat',
        title: 'صلاة 100 ركعة',
        description: 'يستحب صلاة 100 ركعة في هذه الليلة',
        type: ActionType.prayer,
        repeatCount: 100,
        order: 13,
      ),
      const LaylatalQadrAction(
        id: 'night23_dua_sahar',
        title: 'دعاء السحر',
        description: 'قراءة دعاء السحر في آخر الليل',
        type: ActionType.dua,
        order: 14,
      ),
    ];
  }

  /// الحصول على جميع أعمال ليلة معينة
  List<LaylatalQadrAction> getActionsForNight(int nightNumber) {
    final commonActions = getCommonActions();
    List<LaylatalQadrAction> specificActions;

    switch (nightNumber) {
      case 19:
        specificActions = getNight19SpecificActions();
        break;
      case 21:
        specificActions = getNight21SpecificActions();
        break;
      case 23:
        specificActions = getNight23SpecificActions();
        break;
      default:
        specificActions = [];
    }

    return [...commonActions, ...specificActions];
  }
}
