import 'package:flutter/material.dart';
import 'package:vitrinx/screens/public_vitrin_screen.dart';
import 'package:vitrinx/services/booking_service.dart';
import 'package:vitrinx/theme/app_colors.dart';

class AppointmentTrackerScreen extends StatefulWidget {
  final String token;
  final String storeSlug;

  const AppointmentTrackerScreen({super.key, required this.token, required this.storeSlug});

  @override
  State<AppointmentTrackerScreen> createState() => _AppointmentTrackerScreenState();
}

class _AppointmentTrackerScreenState extends State<AppointmentTrackerScreen> {
  bool _isLoading = true;
  dynamic _appointment;
  String? _errorMsg;

  // Reschedule state
  bool _isRescheduling = false;
  DateTime? _newDate;
  String? _newSlotTime;
  List<dynamic> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isSubmittingReschedule = false;

  @override
  void initState() {
    super.initState();
    _fetchAppointment();
  }

  Future<void> _fetchAppointment() async {
    try {
      final res = await const BookingService().getAppointmentByToken(widget.token);

      if (mounted) {
        if (res == null) {
          setState(() {
            _isLoading = false;
            _errorMsg = 'Randevu bulunamadı veya geçersiz takip kodu.';
          });
        } else {
          setState(() {
            _appointment = res;
            _isLoading = false;
            _errorMsg = null;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = 'Randevu detayları yüklenirken bir hata oluştu.';
        });
      }
    }
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

    setState(() => _isLoading = true);
    try {
      await const BookingService().cancelAppointmentByToken(widget.token);
      await _fetchAppointment();
      _showSnackBar('Randevunuz iptal edildi.');
    } catch (_) {
      setState(() => _isLoading = false);
      _showSnackBar('İşlem gerçekleştirilemedi.');
    }
  }

  Future<void> _fetchSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _availableSlots = [];
    });

    try {
      final res = await const BookingService().getAvailableSlots(
        storeSlug: widget.storeSlug,
        date: date,
      );

      if (mounted) {
        setState(() {
          _availableSlots = res;
          _isLoadingSlots = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        });
      }
    }
  }

  Future<void> _submitReschedule() async {
    if (_newDate == null || _newSlotTime == null) return;
    setState(() => _isSubmittingReschedule = true);

    try {
      final datePart = '${_newDate!.year}-${_newDate!.month.toString().padLeft(2, '0')}-${_newDate!.day.toString().padLeft(2, '0')}';
      final newTime = DateTime.parse('$datePart $_newSlotTime:00');

      await const BookingService().requestReschedule(
        token: widget.token,
        newTime: newTime,
      );

      await _fetchAppointment();
      if (mounted) {
        setState(() {
          _isRescheduling = false;
          _isSubmittingReschedule = false;
          _newDate = null;
          _newSlotTime = null;
        });
      }
      _showSnackBar('Tarih değişikliği talebiniz iletildi.');
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmittingReschedule = false);
      }
      _showSnackBar('Talep gönderilemedi. Seçilen saat dolu olabilir.');
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMsg != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMsg!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final status = _appointment['status'] as String;
    final reschedule = _appointment['reschedule_request'];

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
                      _appointment['store_name'] ?? 'İşletme Vitrini',
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
                _buildInfoRow(Icons.calendar_month_rounded, 'Tarih & Saat', _formatDateTime(_appointment['appointment_time'])),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.content_cut_rounded, 'Hizmet', _appointment['service_title']),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.timer_rounded, 'Süre', '${_appointment['service_duration']} dakika'),
                if (_appointment['service_price'] != null && _appointment['service_price'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildInfoRow(Icons.payments_rounded, 'Ücret', _appointment['service_price']),
                ],
                const SizedBox(height: 10),
                _buildInfoRow(Icons.person_rounded, 'Müşteri', _appointment['customer_name']),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.phone_android_rounded, 'Telefon', _appointment['customer_phone']),
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
                      setState(() => _isRescheduling = !_isRescheduling);
                    },
                    icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                    label: Text(_isRescheduling ? 'Kapat' : 'Tarih Değiştir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (_isRescheduling) ...[
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
                final isSelected = _newDate?.year == date.year && _newDate?.month == date.month && _newDate?.day == date.day;
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
                        setState(() {
                          _newDate = date;
                          _newSlotTime = null;
                        });
                        _fetchSlots(date);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          if (_newDate != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Yeni Saat Seçin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkText),
            ),
            const SizedBox(height: 10),
            _isLoadingSlots
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _availableSlots.isEmpty
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
                        itemCount: _availableSlots.length,
                        itemBuilder: (context, index) {
                          final slot = _availableSlots[index];
                          final timeStr = slot['time'] as String;
                          final slotsLeft = slot['slots_left'] as int;
                          final isFull = slotsLeft == 0;
                          final isSelected = _newSlotTime == timeStr;

                          return ChoiceChip(
                            label: Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                            selected: isSelected,
                            onSelected: isFull
                                ? null
                                : (selected) {
                                    if (selected) {
                                      setState(() => _newSlotTime = timeStr);
                                    }
                                  },
                            selectedColor: AppColors.primary,
                            disabledColor: AppColors.bgEditor,
                          );
                        },
                      ),
          ],
          if (_newSlotTime != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmittingReschedule ? null : _submitReschedule,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
              child: _isSubmittingReschedule
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
