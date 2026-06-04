import 'dart:async';
import 'package:flutter/material.dart';
import '../store_editor_controller.dart';

class StoreScoreBadge extends StatelessWidget {
  final StoreEditorController controller;
  final VoidCallback onTap;

  const StoreScoreBadge({
    super.key,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final score = controller.calculateScore();
    final tone = getScoreTone(score);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 38,
            padding: const EdgeInsets.only(left: 8, right: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tone.withAlpha((0.14 * 255).round()),
                  tone.withAlpha((0.05 * 255).round()),
                ],
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: tone.withAlpha((0.22 * 255).round())),
              boxShadow: [
                BoxShadow(
                  color: tone.withAlpha((0.08 * 255).round()),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.84 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: tone,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$score/100',
                  style: TextStyle(
                    color: tone,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color getScoreTone(int score) {
  if (score < 40) return const Color(0xFFEA580C);
  if (score < 80) return const Color(0xFFD97706);
  return const Color(0xFF059669);
}

String getScoreStatusText(int score) {
  if (score < 40) return 'Mağazanız henüz hazır değil.';
  if (score < 70) return 'Mağazanız gelişiyor.';
  if (score < 90) return 'Mağazanız iyi durumda.';
  return 'Mağazanız güçlü görünüyor.';
}

class VisibilityBoostIcon extends StatelessWidget {
  const VisibilityBoostIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.84 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF4D00).withAlpha((0.14 * 255).round())),
      ),
      child: const Icon(
        Icons.travel_explore_rounded,
        color: Color(0xFFFF4D00),
        size: 18,
      ),
    );
  }
}

class GoogleVisibilityCta extends StatelessWidget {
  final VoidCallback onTap;

  const GoogleVisibilityCta({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF4D00);
    const secondaryColor = Color(0xFFB200FF);
    const darkText = Color(0xFF111827);
    const softText = Color(0xFF334155);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 430;

        final textContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daha çok kişi görsün mü?',
              style: TextStyle(
                color: darkText,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'SEO anahtar kelimeleri ve içerik fikirleriyle mağazanızı güçlendirin.',
              style: TextStyle(
                color: softText.withAlpha((0.78 * 255).round()),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        );

        final action = TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.auto_awesome_rounded, size: 15),
          label: const Text('Görünürlüğü artır'),
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(44, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withAlpha((0.08 * 255).round()),
                secondaryColor.withAlpha((0.06 * 255).round()),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withAlpha((0.18 * 255).round())),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const VisibilityBoostIcon(),
                        const SizedBox(width: 10),
                        Expanded(child: textContent),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: action),
                  ],
                )
              : Row(
                  children: [
                    const VisibilityBoostIcon(),
                    const SizedBox(width: 12),
                    Expanded(child: textContent),
                    const SizedBox(width: 12),
                    action,
                  ],
                ),
        );
      },
    );
  }
}

Future<void> showStoreScoreSheet({
  required BuildContext context,
  required StoreEditorController controller,
  required Function(StoreScoreTarget) onTaskTap,
}) async {
  final score = controller.calculateScore();
  final tone = getScoreTone(score);
  final tasks = controller.scoreActionTasks();
  const cardBorder = Color.fromRGBO(15, 23, 42, 0.10);
  const darkText = Color(0xFF111827);
  const softText = Color(0xFF334155);
  const inputBg = Color(0xFFF1F5F9);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 14,
            bottom: 18 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.14 * 255).round()),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            tone.withAlpha((0.16 * 255).round()),
                            tone.withAlpha((0.06 * 255).round()),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: tone.withAlpha((0.2 * 255).round()),
                        ),
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: tone,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mağaza Skoru',
                            style: TextStyle(
                              color: darkText,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Mağazanızı güçlendirmek için eksik adımları tamamlayın.',
                            style: TextStyle(
                              color: softText.withAlpha((0.75 * 255).round()),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$score/100',
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 5,
                    backgroundColor: Colors.black12,
                    valueColor: AlwaysStoppedAnimation<Color>(tone),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  getScoreStatusText(score),
                  style: TextStyle(
                    color: tone,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  tasks.isEmpty ? 'Her şey hazır' : 'Eksik adımlar',
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                if (tasks.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Text(
                      'Mağazanız güçlü görünüyor. Yayınla sekmesinden public linkini hazırlayabilirsin.',
                      style: TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  )
                else
                  ...tasks.map(
                    (task) => InkWell(
                      onTap: () => onTaskTap(task.target),
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: inputBg,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: tone.withAlpha((0.1 * 255).round()),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Icon(Icons.checklist_rounded, color: tone, size: 15),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                task.suggestion,
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: Color(0xFF64748B),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (score >= 60) ...[
                  const SizedBox(height: 12),
                  GoogleVisibilityCta(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      controller.showPremiumVisibilityInfo(context);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
