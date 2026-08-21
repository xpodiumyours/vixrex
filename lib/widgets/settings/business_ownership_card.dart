import 'package:flutter/material.dart';
import 'package:vixrex/repositories/business_ownership_repository.dart';
import 'package:vixrex/services/business_ownership_service.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/theme/app_text_styles.dart';
import 'package:vixrex/widgets/common/app_card.dart';

/// İsteğe bağlı güven doğrulaması; yayınlama için bir kapı değildir.
class BusinessOwnershipCard extends StatefulWidget {
  const BusinessOwnershipCard({super.key});

  @override
  State<BusinessOwnershipCard> createState() => _BusinessOwnershipCardState();
}

class _BusinessOwnershipCardState extends State<BusinessOwnershipCard> {
  final _service = BusinessOwnershipService();
  BusinessOwnershipStatus? _status;
  String? _error;
  bool _loading = true;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _service.getStatus();
    if (!mounted) return;
    result.when(
      success: (status) => setState(() => _status = status),
      failure: (failure) => setState(() => _error = failure.message),
    );
    setState(() => _loading = false);
  }

  Future<void> _verify() async {
    final status = _status;
    if (status == null || _verifying) return;
    setState(() => _verifying = true);
    final result = await _service.verify(status);
    if (!mounted) return;
    setState(() => _verifying = false);
    result.when(
      success: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşletme sahipliği doğrulandı.')),
        );
        _load();
      },
      failure: (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child:
          _loading
              ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        _status?.isVerified == true
                            ? Icons.verified_rounded
                            : Icons.storefront_rounded,
                        color:
                            _status?.isVerified == true
                                ? AppColors.success
                                : AppColors.secondary,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'İşletme sahipliği',
                          style: AppTextStyles.formLabel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_description, style: AppTextStyles.caption),
                  const SizedBox(height: 12),
                  if (_error != null)
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text('Tekrar dene'),
                    )
                  else if (_status?.hasPublishedStore == true &&
                      _status?.isVerified != true)
                    FilledButton.icon(
                      onPressed: _verifying ? null : _verify,
                      icon:
                          _verifying
                              ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.verified_user_rounded),
                      label: const Text('Google ile isteğe bağlı doğrula'),
                    ),
                ],
              ),
    );
  }

  String get _description {
    if (_error != null) return _error!;
    if (_status?.isVerified == true) {
      return 'Google Business Profile ile doğrulandı. Vitrininizde güven rozeti gösterilir.';
    }
    if (_status?.hasPublishedStore != true) {
      return 'Önce vitrininizi yayınlayın. Doğrulama yayınlamak için zorunlu değildir.';
    }
    return 'Ücretsiz ve isteğe bağlıdır. Doğrulamadan da vitrininizi yayınlamaya devam edebilirsiniz.';
  }
}
