import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final migration = File(
    '${Directory.current.path}/supabase/migrations/'
    '20260729100925_rental_storefront_foundation.sql',
  );

  test('kiralık vitrin temeli kapalı özellik bayraklarıyla kurulur', () {
    final sql = migration.readAsStringSync();

    for (final flag in <String>[
      'rental_marketplace',
      'rental_trial',
      'product_origin',
      'assistant_rental_flow',
      'paytr_checkout',
    ]) {
      expect(sql, contains("('$flag', false"));
    }
  });

  test('şablon, kullanıcı kopyası ve tek deneme kuralları atomiktir', () {
    final sql = migration.readAsStringSync();

    expect(sql, contains('CREATE TABLE public.rental_templates'));
    expect(sql, contains('CREATE TABLE public.rental_subscriptions'));
    expect(sql, contains('UNIQUE (user_id)'));
    expect(sql, contains('CREATE OR REPLACE FUNCTION public.start_rental_trial'));
    expect(sql, contains('email_confirmed_at IS NULL'));
    expect(sql, contains('is_anonymous'));
    expect(sql, contains('source_template_store_id'));
    expect(sql, contains('rental_access_until'));
    expect(sql, contains('trial_days * INTERVAL \'1 day\''));
    expect(sql, contains('FOR UPDATE'));
  });

  test('ürün teslim noktası aynı vitrinde kalır ve adres varsayılan gizlidir', () {
    final sql = migration.readAsStringSync();

    expect(sql, contains('CREATE TABLE public.fulfillment_locations'));
    expect(sql, contains('fulfillment_location_id'));
    expect(sql, contains('validate_product_fulfillment_location'));
    expect(sql, contains('public_address_text'));
    expect(sql, contains('is_exact_address_public'));
    expect(sql, contains('REVOKE SELECT ON TABLE public.fulfillment_locations'));
  });

  test('süresi dolan kiralık vitrin herkese açık kalamaz', () {
    final sql = migration.readAsStringSync();

    expect(sql, contains('rental_access_until > now()'));
    expect(sql, contains('DROP POLICY IF EXISTS "Allow public read stores"'));
    expect(sql, contains('CREATE POLICY "Allow public read stores"'));
    expect(sql, contains('rental_tenant'));
  });

  test('istemci ödeme taklidiyle ücretli hak veremez', () {
    final sql = migration.readAsStringSync();

    expect(
      RegExp(
        r'REVOKE INSERT, UPDATE, DELETE ON TABLE public\.rental_subscriptions\s+FROM anon, authenticated',
      ).hasMatch(sql),
      isTrue,
    );
    expect(sql, contains('REVOKE ALL ON FUNCTION public.start_rental_trial'));
    expect(sql, contains('GRANT EXECUTE ON FUNCTION public.start_rental_trial'));
  });
}
