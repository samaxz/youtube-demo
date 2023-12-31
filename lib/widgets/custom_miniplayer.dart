import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_demo/data/models/video/video_model.dart';
import 'package:youtube_demo/screens/miniplayer_screen.dart';
import 'package:youtube_demo/services/common/providers.dart';
import 'package:youtube_demo/widgets/my_miniplayer.dart';

final playerExpandProgress = ValueNotifier<double>(60);

class CustomMiniplayer extends ConsumerStatefulWidget {
  final Video? video;

  const CustomMiniplayer({
    super.key,
    required this.video,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CustomMiniplayerState();
}

class _CustomMiniplayerState extends ConsumerState<CustomMiniplayer> {
  static const double playerMinHeight = 60;
  late double playerMaxHeight;

  @override
  void initState() {
    super.initState();
    if (widget.video != null) {
      ref.read(ratingSNP.notifier).getVideoRating(videoId: widget.video!.id);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    playerMaxHeight = MediaQuery.of(context).size.height;
  }

  @override
  Widget build(BuildContext context) {
    final miniplayerController = ref.watch(miniPlayerControllerP);

    return Miniplayer(
      valueNotifier: playerExpandProgress,
      onDismissed: () {
        // * without this, the mp doesn't dismiss
        ref
            .read(miniPlayerControllerP)
            .animateToHeight(state: PanelState.dismiss);
        Future.delayed(
          const Duration(seconds: 1),
          () => ref.read(selectedVideoSP.notifier).update((state) => null),
        );
      },
      controller: miniplayerController,
      minHeight: playerMinHeight,
      maxHeight: playerMaxHeight,
      builder: (height, percentage) {
        if (widget.video == null) return const SizedBox();

        return MiniplayerScreen(
          height: height,
          percentage: percentage,
          video: widget.video!,
        );
      },
    );
  }
}
