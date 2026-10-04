import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../data/models/app_config.dart';
import '../../data/providers.dart';
import 'link_opener.dart';

/// Embedded browser with progress indicator, navigation toolbar, sharing and
/// "open in browser". Supports inline and full-screen video for live streams.
class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key, required this.args});

  final BrowserArgs args;

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  late final WebViewController _controller;
  double _progress = 0;
  String _title = '';
  String _currentUrl = '';
  bool _canGoBack = false;
  bool _canGoForward = false;
  WebResourceError? _error;

  @override
  void initState() {
    super.initState();
    _title = widget.args.title;
    _currentUrl = widget.args.url;

    final PlatformWebViewControllerCreationParams params = WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const {},
          )
        : const PlatformWebViewControllerCreationParams();

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => mounted ? setState(() => _progress = p / 100) : null,
          onPageStarted: (url) => mounted
              ? setState(() {
                  _currentUrl = url;
                  _error = null;
                })
              : null,
          onPageFinished: (_) => _syncState(),
          onUrlChange: (change) {
            if (change.url != null && mounted) setState(() => _currentUrl = change.url!);
            _syncState();
          },
          onWebResourceError: (error) {
            if ((error.isForMainFrame ?? true) && mounted) setState(() => _error = error);
          },
          onNavigationRequest: _onNavigationRequest,
        ),
      );

    final platform = _controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setMediaPlaybackRequiresUserGesture(false);
      AndroidWebViewController.enableDebugging(kDebugMode);
    }
    if (platform is WebKitWebViewController) {
      platform.setAllowsBackForwardNavigationGestures(true);
      platform.setInspectable(kDebugMode);
    }
    _controller.loadRequest(Uri.parse(widget.args.url));
  }

  /// Web pages may link to phone numbers, e-mail, app stores or other apps.
  /// Those are handed to the operating system instead of the WebView.
  Future<NavigationDecision> _onNavigationRequest(NavigationRequest request) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    if (uri.isScheme('https') || uri.isScheme('about') || uri.isScheme('data') || uri.isScheme('blob')) {
      return NavigationDecision.navigate;
    }
    if (uri.isScheme('http')) {
      // Clear-text pages are blocked in the WebView; open in the browser.
      await LinkOpener.openExternal(uri);
      return NavigationDecision.prevent;
    }
    if (request.isMainFrame) await LinkOpener.openExternal(uri);
    return NavigationDecision.prevent;
  }

  Future<void> _syncState() async {
    final back = await _controller.canGoBack();
    final forward = await _controller.canGoForward();
    final title = await _controller.getTitle();
    if (!mounted) return;
    setState(() {
      _canGoBack = back;
      _canGoForward = forward;
      if (title != null && title.trim().isNotEmpty) _title = title.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final browser = ref.watch(appConfigProvider)?.settings.browser ?? const BrowserSettings();
    final siteId = widget.args.siteId;
    final isFav = siteId != null && ref.watch(favoritesProvider).contains(siteId);
    final host = Uri.tryParse(_currentUrl)?.host ?? '';

    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _controller.canGoBack()) await _controller.goBack();
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title.isEmpty ? host : _title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              Row(
                children: [
                  Icon(
                    _currentUrl.startsWith('https') ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      host,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            if (siteId != null)
              IconButton(
                tooltip: isFav ? 'Remove from favourites' : 'Add to favourites',
                icon: Icon(isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                onPressed: () => ref.read(favoritesProvider.notifier).toggle(siteId),
              ),
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (v) async {
                switch (v) {
                  case 'reload':
                    _controller.reload();
                  case 'share':
                    SharePlus.instance.share(ShareParams(uri: Uri.parse(_currentUrl), subject: _title));
                  case 'external':
                    LinkOpener.openExternal(Uri.parse(_currentUrl));
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'reload',
                  child: ListTile(leading: Icon(Icons.refresh_rounded), title: Text('Reload')),
                ),
                if (browser.allowShare)
                  const PopupMenuItem(
                    value: 'share',
                    child: ListTile(leading: Icon(Icons.ios_share_rounded), title: Text('Share link')),
                  ),
                if (browser.allowOpenInExternalBrowser)
                  const PopupMenuItem(
                    value: 'external',
                    child: ListTile(leading: Icon(Icons.open_in_browser_rounded), title: Text('Open in browser')),
                  ),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: AnimatedOpacity(
              opacity: _progress < 1 ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: LinearProgressIndicator(
                value: _progress == 0 ? null : _progress,
                minHeight: 2,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: _error != null
              ? _ErrorPage(
                  error: _error!,
                  onRetry: () {
                    setState(() => _error = null);
                    _controller.reload();
                  },
                )
              : WebViewWidget(controller: _controller),
        ),
        bottomNavigationBar: browser.showToolbar
            ? SafeArea(
                child: SizedBox(
                  height: 52,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: _canGoBack ? () => _controller.goBack() : null,
                      ),
                      IconButton(
                        tooltip: 'Forward',
                        icon: const Icon(Icons.arrow_forward_ios_rounded),
                        onPressed: _canGoForward ? () => _controller.goForward() : null,
                      ),
                      IconButton(
                        tooltip: 'Reload',
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () => _controller.reload(),
                      ),
                      IconButton(
                        tooltip: 'Start page',
                        icon: const Icon(Icons.home_rounded),
                        onPressed: () => _controller.loadRequest(Uri.parse(widget.args.url)),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({required this.error, required this.onRetry});

  final WebResourceError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final offline =
        error.errorType == WebResourceErrorType.hostLookup || error.errorType == WebResourceErrorType.connect;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded, size: 56),
            const SizedBox(height: 16),
            Text(
              offline ? 'You appear to be offline' : 'This page could not be loaded',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(error.description, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
