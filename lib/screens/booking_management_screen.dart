import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vixrex/config/public_site_config.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/utils/whatsapp_link_helper.dart';

import 'package:vixrex/controllers/booking_management_controller.dart';

class BookingManagementScreen extends StatefulWidget {
  final String storeSlug;

  const BookingManagementScreen({super.key, required this.storeSlug});

  @override
  State<BookingManagementScreen> createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final BookingManagementController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = BookingManagementController(storeSlug: widget.storeSlug);
    _controller.addListener(_onControllerChanged);
    _controller.fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _respond(String apptId, {String? action, String? rescheduleAction}) async {
    final success = await _controller.respondToAppointment(
      apptId,
      action: action,
      rescheduleAction: rescheduleAction,
    );
    if (success) {
      _showSnackBar('Randevu güncellendi.');
    } else {
      _showSnackBar(_controller.errorMessage ?? 'İşlem gerçekleştirilemedi.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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

  void _sendWhatsApp(dynamic appt, String messageTemplate) {
    final dt = DateTime.parse(appt['appointment_time']).toLocal();
    final dateStr = '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final publicLink = PublicSiteConfig.buildPublicLink('/v/${widget.storeSlug}');

    final urlStr = WhatsAppLinkHelper.buildAppointmentMessageUrl(
      number: appt['customer_phone'] ?? '',
      template: messageTemplate,
      customerName: appt['customer_name'] ?? '',
      dateStr: dateStr,
      timeStr: timeStr,
      serviceTitle: appt['service_title'] ?? '',
      link: publicLink,
    );

    if (urlStr != null) {
      final url = Uri.parse(urlStr);
      launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Geçersiz WhatsApp numarası.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgEditor,
      appBar: AppBar(
        title: const Text(
          'Randevuları Yönet',
          style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryDark,
          unselectedLabelColor: AppColors.mutedText,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Bekleyen (${_controller.pendingList.length})'),
            Tab(text: 'Bugün (${_controller.todayList.length})'),
            Tab(text: 'Yaklaşan (${_controller.upcomingList.length})'),
          ],
        ),
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _controller.errorMessage != null
              ? Center(
                child: Text(
                  _controller.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAppointmentList(_controller.pendingList, isPendingTab: true),
                    _buildAppointmentList(_controller.todayList),
                    _buildAppointmentList(_controller.upcomingList),
                  ],
                ),
    );
  }

  Widget _buildAppointmentList(List<dynamic> list, {bool isPendingTab = false}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.mutedText),
            const SizedBox(height: 12),
            Text(
              isPendingTab ? 'Bekleyen randevu talebi bulunmuyor.' : 'Gösterilecek randevu bulunamadı.',
              style: const TextStyle(color: AppColors.mutedText, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final appt = list[index];
        return _buildAppointmentCard(appt);
      },
    );
  }

  Widget _buildAppointmentCard(dynamic appt) {
    final status = appt['status'] as String? ?? 'pending';
    final reschedules = appt['appointment_reschedule_requests'] as List?;
    final pendingReschedule = reschedules?.firstWhere(
      (r) => r['status'] == 'pending',
      orElse: () => null,
    );

    Color statusColor;
    String statusText;

    if (status == 'confirmed') {
      statusColor = AppColors.success;
      statusText = 'Onaylandı';
    } else if (status == 'rejected') {
      statusColor = AppColors.error;
      statusText = 'Reddedildi';
    } else if (status == 'cancelled_by_customer') {
      statusColor = AppColors.mutedText;
      statusText = 'Müşteri İptal Etti';
    } else if (status == 'cancelled_by_store') {
      statusColor = AppColors.mutedText;
      statusText = 'İşletme İptal Etti';
    } else if (status == 'expired') {
      statusColor = AppColors.mutedText;
      statusText = 'Süresi Doldu';
    } else {
      statusColor = Colors.orange;
      statusText = 'Onay Bekliyor';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _formatDateTime(appt['appointment_time']),
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            appt['service_title'] ?? '',
            style: const TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          if (appt['service_price'] != null && appt['service_price'].toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${appt['service_price']} · ${appt['service_duration']} dk',
              style: const TextStyle(color: AppColors.primaryDark, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              '${appt['service_duration']} dk',
              style: const TextStyle(color: AppColors.mutedText, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
          const Divider(height: 24, color: AppColors.border),
          Row(
            children: [
              const Icon(Icons.person_rounded, size: 16, color: AppColors.mutedText),
              const SizedBox(width: 6),
              Text(
                appt['customer_name'] ?? '',
                style: const TextStyle(color: AppColors.softText, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.phone_android_rounded, size: 16, color: AppColors.mutedText),
              const SizedBox(width: 6),
              Text(
                appt['customer_phone'] ?? '',
                style: const TextStyle(color: AppColors.softText, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
          if (appt['customer_notes'] != null && appt['customer_notes'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Not: ${appt['customer_notes']}',
                style: const TextStyle(color: AppColors.softText, fontSize: 12, height: 1.4),
              ),
            ),
          ],
          if (pendingReschedule != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Müşteri Tarih Değişikliği İstedi',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Yeni Önerilen Saat: ${_formatDateTime(pendingReschedule['requested_time'])}',
                    style: const TextStyle(color: AppColors.softText, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _respond(appt['id'], rescheduleAction: 'reject'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Talebi Reddet', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _respond(appt['id'], rescheduleAction: 'approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: const Text('Onayla & Güncelle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (status == 'pending' && pendingReschedule == null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(appt['id'], action: 'reject'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Reddet', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respond(appt['id'], action: 'confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('Onayla', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: () => _showNotificationMenu(appt),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
              label: const Text('WhatsApp ile Bilgilendir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationMenu(dynamic appt) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'WhatsApp Bildirim Şablonları',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: AppColors.success),
                title: const Text('Randevu Onay Mesajı'),
                subtitle: const Text('Randevunun onaylandığını müşteriye bildir.'),
                onTap: () {
                  Navigator.pop(context);
                  _sendWhatsApp(appt, WhatsAppLinkHelper.appointmentConfirmTemplate);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                title: const Text('Randevu Ret Mesajı'),
                subtitle: const Text('Randevunun onaylanamadığını müşteriye bildir.'),
                onTap: () {
                  Navigator.pop(context);
                  _sendWhatsApp(appt, WhatsAppLinkHelper.appointmentRejectTemplate);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit_calendar_outlined, color: Colors.orange),
                title: const Text('Tarih/Saat Güncelleme Önerisi'),
                subtitle: const Text('Yeni bir saat belirlemek üzere iletişime geçin.'),
                onTap: () {
                  Navigator.pop(context);
                  _sendWhatsApp(appt, WhatsAppLinkHelper.appointmentRescheduleTemplate);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
