import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class HelpGuidePage extends StatelessWidget {
  const HelpGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${l.appTitle} - ${l.help}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l.helpGuideTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(l.helpGuidePurpose),
          const SizedBox(height: 12),
          Text(l.helpGuideFeatures),
          const SizedBox(height: 12),
          Text(l.helpGuideScreens),
          const SizedBox(height: 12),
          Text(l.helpGuideFAQ),
          const SizedBox(height: 12),
          Text(l.helpGuideContact),
        ],
      ),
    );
  }
}
