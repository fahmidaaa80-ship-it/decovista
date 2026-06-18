import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _faqs = [
    ('How do I place an order?', 'Browse our shop, add items to your cart, and proceed to checkout. You can pay via the available payment methods.'),
    ('Can I customize a design package?', 'Yes! Most design packages are customizable. Select a package and use the "Customize" option to personalize it.'),
    ('How do I book a consultation?', 'Navigate to the Consultations section and choose an available slot. You\'ll receive a confirmation after booking.'),
    ('What is the return policy?', 'We offer a 30-day return policy for most products. Please contact our support team to initiate a return.'),
    ('How can I track my order?', 'Go to My Orders in your profile to view the current status of all your orders.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return _FaqTile(question: _faqs[index].$1, answer: _faqs[index].$2);
        },
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(widget.question, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.grey),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(widget.answer, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
      ],
    );
  }
}
