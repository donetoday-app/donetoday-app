import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:done_today/services/update_service.dart';

class MajorUpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const MajorUpdateDialog({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Prevent dismissing the dialog via back button or clicking outside
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.system_update_rounded, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Critical Update Required',
                style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${updateInfo.latestVersion} is now available. This is a major update that brings critical new features and improvements.',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8), height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Don\'t worry! Updating the app via the new installer will preserve all of your existing logs and challenges.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _launchDownload(updateInfo.downloadUrl),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Download Update Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _launchDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class MinorUpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const MinorUpdateDialog({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.new_releases_rounded, color: theme.colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            'Update Available',
            style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Version ${updateInfo.latestVersion} is available to download.',
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
          ),
          const SizedBox(height: 12),
          Text(
            'Updating will not remove your user data.',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Not Now', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
        ),
        FilledButton(
          onPressed: () {
            _launchDownload(updateInfo.downloadUrl);
            Navigator.of(context).pop();
          },
          child: const Text('View Update'),
        ),
      ],
    );
  }

  void _launchDownload(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
