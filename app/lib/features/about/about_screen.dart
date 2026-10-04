import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/env.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/net_media.dart';
import '../../data/models/app_config.dart';
import '../../data/providers.dart';
import '../../data/repositories/config_repository.dart';
import '../browser/link_opener.dart';

final packageInfoProvider = FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final snapshotValue = ref.watch(configProvider);
    final snapshot = snapshotValue.hasValue ? snapshotValue.requireValue : null;
    final settings = snapshot?.config.settings ?? const AppSettings();
    final legal = settings.legal;
    final info = ref.watch(packageInfoProvider);
    final version = info.hasValue ? '${info.requireValue.version} (${info.requireValue.buildNumber})' : '';
    final visuals = context.visuals;

    Widget tile(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(gradient: visuals.gradient, borderRadius: BorderRadius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: settings.branding.logoUrl.isEmpty
                  ? const Icon(Icons.blur_on_rounded, color: Colors.white, size: 48)
                  : NetMedia(url: settings.branding.logoUrl),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            settings.branding.appName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (version.isNotEmpty)
            Text('Version $version', textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          if (legal.aboutText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(legal.aboutText, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 20),
          _Group(
            children: [
              if (legal.privacyPolicyUrl.startsWith('http'))
                tile(
                  Icons.privacy_tip_outlined,
                  'Privacy policy',
                  onTap: () => LinkOpener.openUrl(context, legal.privacyPolicyUrl, title: 'Privacy policy'),
                ),
              if (legal.termsUrl.startsWith('http'))
                tile(
                  Icons.description_outlined,
                  'Terms of use',
                  onTap: () => LinkOpener.openUrl(context, legal.termsUrl, title: 'Terms of use'),
                ),
              if (legal.contactEmail.isNotEmpty)
                tile(
                  Icons.mail_outline_rounded,
                  'Contact us',
                  subtitle: legal.contactEmail,
                  onTap: () => LinkOpener.openExternal(
                    Uri(
                      scheme: 'mailto',
                      path: legal.contactEmail,
                      query: 'subject=${Uri.encodeComponent(settings.branding.appName)}',
                    ),
                  ),
                ),
              tile(
                Icons.article_outlined,
                'Open-source licences',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: settings.branding.appName,
                  applicationVersion: version,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Group(
            children: [
              tile(
                Icons.sync_rounded,
                'Check for updated content',
                subtitle: switch (snapshot?.source) {
                  ConfigSource.network => 'Up to date',
                  ConfigSource.cache => snapshot?.error == null ? 'Saved content' : 'Offline: showing saved content',
                  ConfigSource.bundled =>
                    Env.hasBackend ? 'Built-in content (not yet updated)' : 'Built-in demo content',
                  null => null,
                },
                onTap: () async {
                  await ref.read(configProvider.notifier).refresh(force: true);
                  if (!context.mounted) return;
                  final err = ref.read(configProvider).hasValue ? ref.read(configProvider).requireValue.error : null;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Content is up to date')));
                },
              ),
              tile(
                Icons.history_toggle_off_rounded,
                'Clear recently opened',
                onTap: () {
                  ref.read(recentsProvider.notifier).clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('History cleared')));
                },
              ),
            ],
          ),
          if (legal.publisherName.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              '© ${DateTime.now().year} ${legal.publisherName}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Websites shown in this app belong to their respective owners and open with their own terms and privacy policies.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final visuals = context.visuals;
    return Material(
      color: visuals.glassFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(visuals.radius),
        side: BorderSide(color: visuals.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
