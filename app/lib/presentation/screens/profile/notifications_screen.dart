import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = false;

  // Bildirim ayarları
  bool _morningEnabled = true;
  TimeOfDay _morningTime = const TimeOfDay(hour: 8, minute: 0);

  bool _eveningEnabled = true;
  TimeOfDay _eveningTime = const TimeOfDay(hour: 21, minute: 0);

  bool _productApprovalEnabled = true;
  bool _expiryWarningEnabled = true;
  bool _lowStockEnabled = true;
  int _expiryWarningDays = 30; // kaç gün önce uyarsın

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime(bool isMorning) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isMorning ? _morningTime : _eveningTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isMorning)
          _morningTime = picked;
        else
          _eveningTime = picked;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      // Gerçek uygulamada flutter_local_notifications:
      //
      // final plugin = FlutterLocalNotificationsPlugin();
      //
      // Sabah bildirimi:
      // if (_morningEnabled) {
      //   await plugin.zonedSchedule(
      //     0, // id
      //     'Sabah Rutini 🌅',
      //     'Sabah cilt bakım rutininizi yapmayı unutmayın!',
      //     _nextInstanceOf(_morningTime),
      //     const NotificationDetails(
      //       android: AndroidNotificationDetails('routine', 'Rutin Hatırlatıcı'),
      //       iOS: DarwinNotificationDetails(),
      //     ),
      //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      //     uiLocalNotificationDateInterpretation:
      //       UILocalNotificationDateInterpretation.absoluteTime,
      //     matchDateTimeComponents: DateTimeComponents.time,
      //   );
      // } else {
      //   await plugin.cancel(0);
      // }
      //
      // Akşam bildirimi benzer şekilde id:1

      // Firebase'e kaydet:
      // await FirebaseFirestore.instance
      //   .collection('users')
      //   .doc(FirebaseAuth.instance.currentUser!.uid)
      //   .update({
      //     'notifications': {
      //       'morningEnabled': _morningEnabled,
      //       'morningTime': _formatTime(_morningTime),
      //       'eveningEnabled': _eveningEnabled,
      //       'eveningTime': _formatTime(_eveningTime),
      //       'productApproval': _productApprovalEnabled,
      //       'expiryWarning': _expiryWarningEnabled,
      //       'expiryWarningDays': _expiryWarningDays,
      //       'lowStock': _lowStockEnabled,
      //     }
      //   });

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _showSuccess('Bildirim ayarları kaydedildi');
      Navigator.pop(context);
    } catch (e) {
      _showError('Kaydetme sırasında hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      ));

  void _showSuccess(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(msg),
        ]),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _routineCard(),
                const SizedBox(height: 12),
                _systemCard(),
                const SizedBox(height: 12),
                _infoCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          _buildBottomBar(),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
        child: Row(children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          ),
          const Expanded(
              child: Text('Bildirimler',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark))),
          const SizedBox(width: 48),
        ]),
      );

  Widget _routineCard() => _card(
        title: 'Rutin Hatırlatıcıları',
        icon: Icons.alarm_outlined,
        child: Column(children: [
          // Sabah
          _routineRow(
            emoji: '🌅',
            label: 'Sabah Rutini',
            enabled: _morningEnabled,
            time: _morningTime,
            isMorning: true,
            onToggle: (v) => setState(() => _morningEnabled = v),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.softGreen),
          const SizedBox(height: 8),
          // Akşam
          _routineRow(
            emoji: '🌙',
            label: 'Akşam Rutini',
            enabled: _eveningEnabled,
            time: _eveningTime,
            isMorning: false,
            onToggle: (v) => setState(() => _eveningEnabled = v),
          ),
        ]),
      );

  Widget _routineRow({
    required String emoji,
    required String label,
    required bool enabled,
    required TimeOfDay time,
    required bool isMorning,
    required ValueChanged<bool> onToggle,
  }) =>
      Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: isMorning ? AppGradients.morning : AppGradients.evening,
            shape: BoxShape.circle,
          ),
          child:
              Center(child: Text(emoji, style: const TextStyle(fontSize: 16))),
        ),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark)),
          GestureDetector(
            onTap: enabled ? () => _pickTime(isMorning) : null,
            child: Row(children: [
              Icon(Icons.access_time,
                  size: 12,
                  color: enabled ? AppColors.primary : AppColors.textLight),
              const SizedBox(width: 4),
              Text(_formatTime(time),
                  style: TextStyle(
                      fontSize: 11,
                      color: enabled ? AppColors.primary : AppColors.textLight,
                      fontWeight: FontWeight.w500)),
              if (enabled) ...[
                const SizedBox(width: 4),
                const Icon(Icons.edit, size: 10, color: AppColors.primary),
              ],
            ]),
          ),
        ])),
        Switch(
          value: enabled,
          onChanged: onToggle,
          activeColor: AppColors.primary,
          activeTrackColor: AppColors.lightGreen,
        ),
      ]);

  Widget _systemCard() => _card(
        title: 'Sistem Bildirimleri',
        icon: Icons.notifications_outlined,
        child: Column(children: [
          _switchRow(
            icon: Icons.check_circle_outline,
            iconColor: AppColors.primary,
            title: 'Ürün Onaylandı',
            subtitle: 'Eklediğiniz ürün onaylandığında',
            value: _productApprovalEnabled,
            onChanged: (v) => setState(() => _productApprovalEnabled = v),
          ),
          const Divider(height: 16, color: AppColors.softGreen),
          _switchRow(
            icon: Icons.event_busy_outlined,
            iconColor: AppColors.accent,
            title: 'Son Kullanma Tarihi',
            subtitle: 'SKT dolmadan $_expiryWarningDays gün önce uyar',
            value: _expiryWarningEnabled,
            onChanged: (v) => setState(() => _expiryWarningEnabled = v),
            trailing: _expiryWarningEnabled ? _daysSelector() : null,
          ),
          const Divider(height: 16, color: AppColors.softGreen),
          _switchRow(
            icon: Icons.water_drop_outlined,
            iconColor: AppColors.peach,
            title: 'Ürün Azalıyor',
            subtitle: '%20\'nin altına düştüğünde',
            value: _lowStockEnabled,
            onChanged: (v) => setState(() => _lowStockEnabled = v),
          ),
        ]),
      );

  Widget _switchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Widget? trailing,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textGrey)),
              ])),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.lightGreen,
          ),
        ]),
        if (trailing != null) ...[
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.only(left: 44), child: trailing),
        ],
      ]);

  Widget _daysSelector() => Row(children: [
        const Text('Kaç gün önce:',
            style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
        const SizedBox(width: 8),
        ...([7, 14, 30, 60].map((d) {
          final selected = _expiryWarningDays == d;
          return GestureDetector(
            onTap: () => setState(() => _expiryWarningDays = d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? AppColors.lightGreen : AppColors.cream,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.softGreen,
                  width: selected ? 2 : 1.5,
                ),
              ),
              child: Text('$d gün',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: selected ? AppColors.primary : AppColors.textGrey,
                  )),
            ),
          );
        })),
      ]);

  Widget _infoCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(16)),
        child:
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 16),
          SizedBox(width: 8),
          Expanded(
              child: Text(
            'Bildirimlerin çalışması için cihaz bildirim izinlerinin açık olması gerekir. '
            'Ayarlar > Uygulamalar > SkinSavvy > Bildirimler yolundan kontrol edebilirsiniz.',
            style:
                TextStyle(fontSize: 11, color: AppColors.primary, height: 1.5),
          )),
        ]),
      );

  Widget _buildBottomBar() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(children: [
          Expanded(
              child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.softGreen, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('İptal',
                style: TextStyle(
                    color: AppColors.textDark, fontWeight: FontWeight.w500)),
          )),
          const SizedBox(width: 12),
          Expanded(
              flex: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: AppGradients.primary,
                    borderRadius: BorderRadius.circular(14)),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                              Icon(Icons.check, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('Kaydet',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ]),
                ),
              )),
        ]),
      );

  Widget _card(
          {required String title,
          required IconData icon,
          required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 17),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark)),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.softGreen),
          const SizedBox(height: 12),
          child,
        ]),
      );
}
