import 'package:flutter/material.dart';
import 'package:vixrex/screens/public_vitrin_screen.dart';
import 'package:vixrex/theme/app_colors.dart';

import 'package:vixrex/controllers/appointment_tracker_controller.dart';

class AppointmentTrackerScreen extends StatefulWidget {
  final String token;
  final String storeSlug;

  const AppointmentTrackerScreen({super.key, required this.token, required this.storeSlug});

  @override
  State<AppointmentTrackerScreen> createState() => _AppointmentTrackerScreenState();
}

class _AppointmentTrackerScreenState extends State<AppointmentTrackerScreen> {
  late final AppointmentTrackerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppointmentTrackerController(
      token: widget.token,
      storeSlug: widget.storeSlug,
    );
    _controller.addListener(_onControllerChanged);
    _controller.fetchAppointment();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _cancelAppointment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Randevuyu İptal Et', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bu randevu talebini iptal etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _controller.cancelAppointment();
    if (success) {
      _showSnackBar('Randevunuz iptal edildi.');
    } else {
      _showSnackBar(_controller.errorMsg ?? 'İşlem gerçekleştirilemedi.');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDateTime(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day.$month.$year · $hour:$minute';
    } catch (_) {
      return isoStr;
    }
  }

  List<DateTime> get _availableDates {
    final list = <DateTime>[];
    final today = DateTime.now();
    // Default 30 days active logic (fallback if capacity details are missing)
    for (int i = 0; i < 30; i++) {
      final date = today.add(Duration(days: i));
      if (date.weekday != 7) { // Skip Sundays as default closed check
        list.add(date);
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgEditor,
      appBar: AppBar(
        title: const Text('Randevu Takip', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.storefront_rounded, color: AppColors.primaryDark),
          onPressed: () {
            // Navigate back to public vitrin clearing fragment
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => PublicVitrinScreen(slug: widget.storeSlug)),
            );
          },
        ),
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _controller.errorMsg != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_controller.errorMsg!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => PublicVitrinScreen(slug: widget.storeSlug)),
                            );
                          },
                          child: const Text('Vitrine Dön'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    final status = _controller.appointment['status'] as String? ?? 'pending';
    final reschedule = _controller.appointment['reschedule_request'];

    Color statusColor;
    String statusText;

    if (status == 'confirmed') {
      statusColor = AppColors.success;
      statusText = 'Onaylandı';
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = 'Onaylanmadı';
    } else if (status == 'cancelled_by_customer') {
      statusColor = Colors.grey;
      statusText = 'İptal Ettiniz';
    } else if (status == 'cancelled_by_store') {
      statusColor = Colors.grey;
      statusText = 'İşletme İptal Etti';
    } else if (status == 'expired') {
      statusColor = Colors.grey;
      statusText = 'Zaman Aşımı';
    } else {
      statusColor = Colors.orange;
      statusText = 'Onay Bekliyor';
    }

    final canAction = status == 'pending' || status == 'confirmed';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _controller.appointment['store_name'] ?? 'İşletme Vitrini',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.darkText),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: AppColors.border),
                _buildInfoRow(Icons.calendar_month_rounded, 'Tarih & Saat', _formatDateTime(_controller.appointment['appointment_time'] ?? '')),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.content_cut_rounded, 'Hizmet', _controller.appointment['service_title'] ?? ''),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.timer_rounded, 'Süre', '${_controller.appointment['service_duration'] ?? ''} dakika'),
                if (_controller.appointment['service_price'] != null && _controller.appointment['service_price'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.payments_rounded, 'Ücret', _controller.appointment['service_price'].toString()),
                ],
                const SizedBox(height: 10),
                _buildInfoRow(Icons.person_rounded, 'Müşteri', _controller.appointment['customer_name'] ?? ''),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.phone_android_rounded, 'Telefon', _controller.appointment['customer_phone'] ?? ''),
              ],
            ),
          ),
          if (reschedule != null && reschedule['status'] == 'pending') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tarih Değişikliği Talebiniz İletildi (${_formatDateTime(reschedule['requested_time'])}). İşletme onaylayana kadar eski randevunuz geçerlidir.',
                      style: const TextStyle(color: Colors.orange, fontSize: 12, height: 1.4, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (canAction) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _cancelAppointment,
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Randevuyu İptal Et'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _controller.isRescheduling = !_controller.isRescheduling;
                    },
                    icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                    label: Text(_controller.isRescheduling ? 'Kapat' : 'Tarih Değiştir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (_controller.isRescheduling) ...[
              const SizedBox(height: 16),
              _buildReschedulingSection(),
            ],
          ],
          const SizedBox(height: 30),
          OutlinedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => PublicVitrinScreen(slug: widget.storeSlug)),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              side: const BorderSide(color: AppColors.border),
            ),
            child: const Text('Vitrini Görüntüle'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.mutedText),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.mutedText, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildReschedulingSection() {
    final dates = _availableDates;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Yeni Tarih Seçin',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final isSelected = _controller.newDate?.year == date.year && _controller.newDate?.month == date.month && _controller.newDate?.day == date.day;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${date.day}/${date.month}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(_formatDayName(date), style: const TextStyle(fontSize: 9)),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.turquoiseSurface,
                    backgroundColor: AppColors.inputBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onSelected: (selected) {
                      if (selected) {
                        _controller.newDate = date;
                        _controller.newSlotTime = null;
                        _controller.fetchSlots(date);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          if (_controller.newDate != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Yeni Saat Seçin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText),
            ),
            const SizedBox(height: 10),
            _controller.isLoadingSlots
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _controller.availableSlots.isEmpty
                    ? const Text('Bu tarihte müsait saat bulunmuyor.', style: TextStyle(color: AppColors.mutedText))
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 2,
                        ),
                        itemCount: _controller.availableSlots.length,
                        itemBuilder: (context, index) {
                          final slot = _controller.availableSlots[index];
                          final timeStr = slot['time'] as String;
                          final slotsLeft = slot['slots_left'] as int;
                          final isFull = slotsLeft == 0;
                          final isSelected = _controller.newSlotTime == timeStr;

                          return ChoiceChip(
                            label: Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                            selected: isSelected,
                            onSelected: isFull
                                ? null
                                : (selected) {
                                    if (selected) {
                                      _controller.newSlotTime = timeStr;
                                    }
                                  },
                            selectedColor: AppColors.primary,
                            disabledColor: AppColors.bgEditor,
                          );
                        },
                      ),
          ],
          if (_controller.newSlotTime != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _controller.isSubmittingReschedule ? null : () async {
                final ok = await _controller.submitReschedule();
                if (ok) {
                  _showSnackBar('Tarih değişikliği talebiniz iletildi.');
                } else {
                  _showSnackBar('Talep gönderilemedi. Seçilen saat dolu olabilir.');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
              child: _controller.isSubmittingReschedule
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Değişiklik Talebi Gönder', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDayName(DateTime date) {
    final dayNames = {
      1: 'Pzt',
      2: 'Sal',
      3: 'Çar',
      4: 'Per',
      5: 'Cum',
      6: 'Cmt',
      7: 'Paz',
    };
    return dayNames[date.weekday]!;
  }
}
