/// Randevu bildirim metin şablonları (TR).
class NotificationTemplates {
  const NotificationTemplates._();

  static ({String title, String body}) forBookingAction({
    required String action,
    required String customerName,
    required String storeSlug,
  }) {
    final name = customerName.trim().isEmpty ? 'Müşteri' : customerName.trim();
    switch (action) {
      case 'confirm':
      case 'approve':
        return (
          title: 'Randevu onaylandı',
          body: '$name için randevu onaylandı. Vitrin: $storeSlug',
        );
      case 'reject':
        return (
          title: 'Randevu reddedildi',
          body: '$name için randevu reddedildi. Vitrin: $storeSlug',
        );
      case 'reminder':
        return (
          title: 'Randevu hatırlatması',
          body: '$name için yaklaşan randevu hatırlatması. Vitrin: $storeSlug',
        );
      case 'pending':
        return (
          title: 'Yeni randevu talebi',
          body: '$name yeni bir randevu talebi gönderdi. Vitrin: $storeSlug',
        );
      default:
        return (
          title: 'Randevu güncellendi',
          body: '$name için randevu durumu güncellendi. Vitrin: $storeSlug',
        );
    }
  }
}
