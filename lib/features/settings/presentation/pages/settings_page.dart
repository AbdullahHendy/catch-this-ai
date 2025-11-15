import 'package:catch_this_ai/features/settings/presentation/view_model/settings_view_model.dart';
import 'package:catch_this_ai/features/settings/widgets/settings_service_selector_card.dart';
import 'package:catch_this_ai/features/settings/widgets/settings_group_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Main Settings Page
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final speechServiceType = viewModel.currentServiceType;
    final isKwsMode = speechServiceType == 'kws';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        animateColor: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 10),
          _buildSectionHeader(theme, 'Speech Recognition Mode'),
          const SizedBox(height: 8),

          // Service Selection Widget
          SettingsServiceSelectorCard(
            selectedType: speechServiceType,
            onTypeSelected: (newType) {
              viewModel.updateServiceType(newType);
            },
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'Display Preferences'),
          const SizedBox(height: 8),

          // Display Preferences
          SettingsGroupCard(
            children: [
              SwitchListTile(
                title: const Text('Keywords Only Mode'),
                subtitle: const Text(
                  'Hide full sentences in the history view',
                  style: TextStyle(fontSize: 12),
                ),
                value: isKwsMode ? true : viewModel.keywordsOnlyMode,
                // Grey out the switch if in KWS mode
                onChanged: isKwsMode
                    ? null
                    : (val) => viewModel.updateKeywordsOnlyMode(val),
                activeThumbColor: theme.primaryColor,
              ),

              SwitchListTile(
                title: const Text('Pad Empty Days'),
                subtitle: const Text(
                  'Show days with zero activity in stats charts',
                  style: TextStyle(fontSize: 12),
                ),
                value: viewModel.padEmptyDaysInCharts,
                onChanged: (val) => viewModel.updatePadEmptyDaysInCharts(val),
                activeThumbColor: theme.primaryColor,
              ),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'Data Management'),
          const SizedBox(height: 8),

          // Data Management Card, clear tracking data only for now
          SettingsGroupCard(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Clear Tracked Data',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('Deletes all tracking history and stats'),
                onTap: () => _showDeleteConfirmation(context, viewModel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to build section headers
  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Helper to show delete confirmation dialog
  Future<void> _showDeleteConfirmation(
    BuildContext context,
    SettingsViewModel viewModel,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Everything?'),
        content: const Text(
          'This will permanently remove all your tracking history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.clearTrackingData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
