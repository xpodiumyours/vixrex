import 'package:flutter/material.dart';
import 'package:vixrex/models/chat_message.dart';
import 'package:vixrex/widgets/chat/chat_pill.dart';

/// İlk sohbet paneli gibi: ortada küçük hap(lar), tam genişlik şerit yok.
class VixRexQuickReplies extends StatelessWidget {
  final List<QuickReply> replies;
  final ValueChanged<QuickReply> onTap;

  const VixRexQuickReplies({
    super.key,
    required this.replies,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChatPillRow(
      caption: 'Devam',
      children: [
        for (var i = 0; i < replies.length; i++)
          ChatPill(
            label: replies[i].label,
            primary: i == 0,
            onTap: () => onTap(replies[i]),
          ),
      ],
    );
  }
}
