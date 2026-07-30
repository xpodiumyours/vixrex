import 'package:flutter/material.dart';
import 'package:vixrex/models/store_data.dart';
import 'package:vixrex/theme/app_colors.dart';
import 'package:vixrex/widgets/editor/common_form_fields.dart';

class FaqEditorSheet extends StatefulWidget {
  final List<StoreFaqItem> items;

  const FaqEditorSheet({super.key, required this.items});

  @override
  State<FaqEditorSheet> createState() => _FaqEditorSheetState();
}

class _FaqEditorSheetState extends State<FaqEditorSheet> {
  late List<_FaqDraft> _drafts;

  @override
  void initState() {
    super.initState();
    _drafts =
        widget.items
            .map(
              (item) => _FaqDraft(
                id: item.id,
                question: TextEditingController(text: item.question),
                answer: TextEditingController(text: item.answer),
              ),
            )
            .toList();
    if (_drafts.isEmpty) _addEmpty();
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addEmpty() {
    setState(() {
      _drafts.add(
        _FaqDraft(
          id: 'faq-${DateTime.now().microsecondsSinceEpoch}',
          question: TextEditingController(),
          answer: TextEditingController(),
        ),
      );
    });
  }

  void _removeAt(int index) {
    setState(() {
      _drafts.removeAt(index).dispose();
      if (_drafts.isEmpty) _addEmpty();
    });
  }

  void _save() {
    final items =
        _drafts
            .map(
              (draft) => StoreFaqItem(
                id: draft.id,
                question: draft.question.text.trim(),
                answer: draft.answer.text.trim(),
              ),
            )
            .where(
              (item) =>
                  item.question.isNotEmpty && item.answer.isNotEmpty,
            )
            .toList();
    Navigator.of(context).pop(items);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sık Sorulan Sorular',
                style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Boş soru/cevaplar kaydedilmez.',
                style: TextStyle(color: AppColors.mutedText, fontSize: 12),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _drafts.length; i++) ...[
                Row(
                  children: [
                    Text(
                      'Soru ${i + 1}',
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _removeAt(i),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: AppColors.mutedText,
                    ),
                  ],
                ),
                EditorTextField(
                  label: 'Soru',
                  controller: _drafts[i].question,
                  hint: 'Örn: Ürünleri mağazada deneyebilir miyim?',
                  icon: Icons.help_outline_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                EditorTextField(
                  label: 'Cevap',
                  controller: _drafts[i].answer,
                  hint: 'Kısa ve net cevap yaz',
                  icon: Icons.chat_bubble_outline_rounded,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
              ],
              OutlinedButton.icon(
                onPressed: _drafts.length >= 20 ? null : _addEmpty,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Soru ekle'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqDraft {
  final String id;
  final TextEditingController question;
  final TextEditingController answer;

  _FaqDraft({
    required this.id,
    required this.question,
    required this.answer,
  });

  void dispose() {
    question.dispose();
    answer.dispose();
  }
}
