import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/app_colors.dart';

class WorkingHoursServiceRow extends StatefulWidget {
  final StoreOffering offering;
  final VoidCallback onDelete;
  final VoidCallback onStateChanged;

  const WorkingHoursServiceRow({
    super.key,
    required this.offering,
    required this.onDelete,
    required this.onStateChanged,
  });

  @override
  State<WorkingHoursServiceRow> createState() => _WorkingHoursServiceRowState();
}

class _WorkingHoursServiceRowState extends State<WorkingHoursServiceRow> {
  static const Color primaryColor = AppColors.primary;
  static const Color darkText = AppColors.darkText;
  static const Color mutedText = AppColors.mutedText;
  static const Color softText = AppColors.softText;
  static const Color cardBorder = AppColors.cardBorderDark;
  static const Color inputBg = AppColors.inputBg;
  static const Color dangerColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  key: ValueKey('${widget.offering.id}-title'),
                  initialValue: widget.offering.title,
                  onChanged: (val) {
                    widget.offering.title = val;
                    widget.onStateChanged();
                  },
                  maxLength: 60,
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  style: const TextStyle(
                    fontSize: 13,
                    color: darkText,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Randevu hizmeti (örn: Saç Kesimi)',
                    hintStyle: TextStyle(
                      color: mutedText.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  key: ValueKey('${widget.offering.id}-price'),
                  initialValue: widget.offering.price,
                  onChanged: (val) {
                    widget.offering.price = val;
                    widget.onStateChanged();
                  },
                  maxLength: 30,
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
                  style: const TextStyle(
                    fontSize: 13,
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Fiyat (örn: 150 TL)',
                    hintStyle: TextStyle(
                      color: mutedText.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: dangerColor,
                ),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(28, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: cardBorder),
          TextFormField(
            key: ValueKey('${widget.offering.id}-desc'),
            initialValue: widget.offering.description,
            onChanged: (val) {
              widget.offering.description = val;
              widget.onStateChanged();
            },
            maxLength: 120,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 12,
              color: softText,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Kısa açıklama (örn: Yıkama ve fön dahil hizmet)',
              hintStyle: TextStyle(
                color: mutedText.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              border: InputBorder.none,
            ),
          ),
          const Divider(height: 1, color: cardBorder),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.timer_rounded, size: 14, color: mutedText),
              const SizedBox(width: 4),
              const Text(
                'Süre',
                style: TextStyle(
                  fontSize: 12,
                  color: softText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              DropdownButton<int>(
                value: widget.offering.durationMinutes,
                items: [15, 30, 45, 60, 90, 120, 180, 240].map((int val) {
                  return DropdownMenuItem<int>(
                    value: val,
                    child: Text(
                      '$val dk',
                      style: const TextStyle(
                        fontSize: 12,
                        color: darkText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    if (val != null) {
                      widget.offering.durationMinutes = val;
                    }
                    widget.offering.isBookable = true;
                  });
                  widget.onStateChanged();
                },
                underline: const SizedBox(),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}
