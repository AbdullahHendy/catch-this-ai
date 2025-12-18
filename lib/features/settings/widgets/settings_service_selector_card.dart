import 'package:catch_this_ai/core/utils/sherpa_model_utils.dart';
import 'package:flutter/material.dart';

/// A card-based selector for ASR vs KWS service types.
class SettingsServiceSelectorCard extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeSelected;

  const SettingsServiceSelectorCard({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildOption(
          context,
          title: 'Transcription (ASR)',
          description:
              'Continuous speech recognition. Captures full sentences.',
          value: SherpaModel.asr.type,
          icon: Icons.record_voice_over_rounded,
        ),
        const SizedBox(height: 12),
        _buildOption(
          context,
          title: 'Keyword Spotting (KWS)',
          description: 'Efficiently listens for specific keywords only.',
          value: SherpaModel.kws.type,
          icon: Icons.manage_search_rounded,
        ),
      ],
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required String description,
    required String value,
    required IconData icon,
  }) {
    final isSelected = selectedType == value;
    final theme = Theme.of(context);

    return Card(
      elevation: isSelected ? 4 : 1,
      shadowColor: isSelected
          ? theme.primaryColor.withValues(alpha: 0.4)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTypeSelected(value),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.primaryColor.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? theme.primaryColor : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? theme.primaryColor : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: theme.primaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
