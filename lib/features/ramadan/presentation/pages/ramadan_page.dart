import 'package:flutter/material.dart';
import '../widgets/imsakiya_widget.dart';
import '../widgets/laylatal_qadr_widget.dart';
import '../widgets/today_ramadan_widget.dart';

/// صفحة رمضان الرئيسية
class RamadanPage extends StatefulWidget {
  const RamadanPage({super.key});

  @override
  State<RamadanPage> createState() => _RamadanPageState();
}

class _RamadanPageState extends State<RamadanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رمضان المبارك'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'اليوم', icon: Icon(Icons.today)),
            Tab(text: 'الإمساكية', icon: Icon(Icons.calendar_month)),
            Tab(text: 'ليالي القدر', icon: Icon(Icons.star)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // تبويب اليوم
          const TodayRamadanWidget(),

          // تبويب الإمساكية
          const ImsakiyaWidget(),

          // تبويب ليالي القدر
          const LaylatalQadrWidget(),
        ],
      ),
    );
  }
}
