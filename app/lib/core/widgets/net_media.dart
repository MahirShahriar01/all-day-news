import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../utils/text_utils.dart';

/// Shows a remote image (PNG/JPG/WebP, animated GIF/WebP) or a short looping,
/// muted video (MP4/WebM). Falls back to [fallback] while loading or on error.
class NetMedia extends StatelessWidget {
  const NetMedia({super.key, required this.url, this.fit = BoxFit.cover, this.fallback, this.playVideo = true});

  final String url;
  final BoxFit fit;
  final Widget? fallback;
  final bool playVideo;

  @override
  Widget build(BuildContext context) {
    final placeholder = fallback ?? const SizedBox.shrink();
    if (url.isEmpty) return placeholder;
    if (isVideoUrl(url)) {
      return playVideo ? LoopingVideo(url: url, fit: fit, placeholder: placeholder) : placeholder;
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

/// Muted looping video used for animated featured cards and backgrounds.
class LoopingVideo extends StatefulWidget {
  const LoopingVideo({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder = const SizedBox.shrink(),
  });

  final String url;
  final BoxFit fit;
  final Widget placeholder;

  @override
  State<LoopingVideo> createState() => _LoopingVideoState();
}

class _LoopingVideoState extends State<LoopingVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;
    final controller = VideoPlayerController.networkUrl(
      uri,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;
    controller.setLooping(true);
    controller.setVolume(0);
    controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() => _ready = true);
          if (!MediaQuery.disableAnimationsOf(context)) controller.play();
        })
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !_ready) return widget.placeholder;
    return ExcludeSemantics(
      child: FittedBox(
        fit: widget.fit,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c)),
      ),
    );
  }
}
