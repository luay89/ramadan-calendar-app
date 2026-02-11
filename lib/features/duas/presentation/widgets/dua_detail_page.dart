import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/dua_entity.dart';

/// صفحة تفاصيل الدعاء - تصميم بخلفية سوداء
class DuaDetailPage extends StatefulWidget {
  final DuaEntity dua;

  const DuaDetailPage({super.key, required this.dua});

  @override
  State<DuaDetailPage> createState() => _DuaDetailPageState();
}

class _DuaDetailPageState extends State<DuaDetailPage> {
  double _fontSize = 22.0;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.dua.isFavorite;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.dua.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  _isFavorite = !_isFavorite;
                });
              },
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white,
              ),
            ),
            IconButton(
              onPressed: () => _copyToClipboard(context),
              icon: const Icon(Icons.copy, color: Colors.white),
            ),
            IconButton(
              onPressed: () => _shareText(context),
              icon: const Icon(Icons.share, color: Colors.white),
            ),
          ],
        ),
        body: Column(
          children: [
            // شريط التحكم بحجم الخط
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade900,
              child: Row(
                children: [
                  const Icon(
                    Icons.text_fields,
                    size: 20,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'حجم الخط',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: Colors.amber,
                        inactiveTrackColor: Colors.grey.shade700,
                        thumbColor: Colors.amber,
                        overlayColor: Colors.amber.withValues(alpha: 0.3),
                      ),
                      child: Slider(
                        value: _fontSize,
                        min: 16,
                        max: 36,
                        divisions: 10,
                        onChanged: (value) {
                          setState(() {
                            _fontSize = value;
                          });
                        },
                      ),
                    ),
                  ),
                  Text(
                    '${_fontSize.toInt()}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // محتوى الدعاء
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات الدعاء
                    _buildInfoCard(),
                    const SizedBox(height: 20),

                    // النص العربي - الجزء الرئيسي
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: SelectableText(
                        widget.dua.arabicText,
                        style: TextStyle(
                          fontSize: _fontSize,
                          height: 2.2,
                          color: Colors.white,
                          fontFamily: 'Amiri',
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ),

                    // الترجمة (إن وجدت)
                    if (widget.dua.translation != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'الترجمة',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.dua.translation!,
                          style: const TextStyle(
                            height: 1.8,
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 100), // مساحة للفلوتينغ باتن
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton:
            widget.dua.audioUrl != null
                ? FloatingActionButton.extended(
                  onPressed: () {
                    // تشغيل الصوت
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('استماع'),
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                )
                : null,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.dua.category.icon,
                style: const TextStyle(fontSize: 36),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.dua.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.dua.category.arabicName,
                      style: const TextStyle(color: Colors.amber),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.dua.source != null) ...[
            Divider(height: 24, color: Colors.grey.shade700),
            Row(
              children: [
                const Icon(Icons.menu_book, size: 18, color: Colors.white54),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'المصدر: ${widget.dua.source}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ],
          if (widget.dua.occasions != null &&
              widget.dua.occasions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  widget.dua.occasions!
                      .map(
                        (occasion) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            occasion,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.dua.arabicText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ الدعاء'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.grey.shade800,
      ),
    );
  }

  void _shareText(BuildContext context) {
    // استخدام share_plus package
    // ignore: unused_local_variable
    final text = '''${widget.dua.title}

${widget.dua.arabicText}

المصدر: ${widget.dua.source ?? 'غير معروف'}
''';
    // TODO: Share.share(text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('جاري المشاركة...'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.grey.shade800,
      ),
    );
  }
}
