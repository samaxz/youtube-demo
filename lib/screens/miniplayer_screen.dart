// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pod_player/pod_player.dart';
import 'package:youtube_demo/data/info/youtube_failure.dart';

import 'package:youtube_demo/data/models/video/video_model.dart';
import 'package:youtube_demo/services/common/helper_class.dart';
import 'package:youtube_demo/services/common/providers.dart';
import 'package:youtube_demo/services/notifiers/rating_notifier.dart';
import 'package:youtube_demo/services/notifiers/video_details_notifier.dart';
import 'package:youtube_demo/widgets/failure_tile.dart';
import 'package:youtube_demo/widgets/my_miniplayer.dart';
import 'package:youtube_demo/widgets/shimmers/loading_video_screen.dart';
import 'package:youtube_demo/widgets/video_card.dart';
import 'package:youtube_demo/widgets/video_info_tile.dart';

class MiniplayerScreen extends ConsumerStatefulWidget {
  final double height;
  final double percentage;
  final Video video;

  const MiniplayerScreen({
    super.key,
    required this.height,
    required this.percentage,
    required this.video,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MiniplayerScreenState();
}

class _MiniplayerScreenState extends ConsumerState<MiniplayerScreen> {
  static const double playerMinHeight = 60;
  late double playerMaxHeight;
  late final ScrollController scrollController;
  late final PodPlayerController playerController;

  Future<void> getDetails() async {
    await ref.read(ratingSNP.notifier).getVideoRating(videoId: widget.video.id);
    await ref
        .read(ratingNotifierProvider.notifier)
        .getVideoRating(videoId: widget.video.id);

    final videoDetails = ref.read(videoDetailsNotifierProvider.notifier);
    await videoDetails.getDetails(
      videoId: widget.video.id,
      channelId: widget.video.snippet.channelId,
    );
  }

  Future<void> reloadData() async {
    if (!await Helper.hasInternet()) return;

    await playerController.changeVideo(
      playVideoFrom: PlayVideoFrom.youtube(
        'https://youtu.be/${widget.video.id}',
      ),
    );
    playerController.play();
    ref.invalidate(videoDetailsNotifierProvider);
    final videoDetails = ref.read(videoDetailsNotifierProvider.notifier);
    await videoDetails.getDetails(
      videoId: widget.video.id,
      channelId: widget.video.snippet.channelId,
    );

    ref
        .read(ratingNotifierProvider.notifier)
        .getVideoRating(videoId: widget.video.id);
  }

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    playerController = PodPlayerController(
      playVideoFrom: PlayVideoFrom.youtube(
        'https://youtu.be/${widget.video.id}',
      ),
    )..initialise();
    // * without this, the details are stuck in the loading state
    Future.microtask(getDetails);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    playerMaxHeight = MediaQuery.of(context).size.height;
  }

  @override
  void didUpdateWidget(covariant MiniplayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.video.id != oldWidget.video.id) {
      playerController.changeVideo(
        playVideoFrom: PlayVideoFrom.youtube(
          'https://youtu.be/${widget.video.id}',
        ),
      );
      Future.microtask(getDetails);
    }
  }

  @override
  void dispose() {
    playerController.dispose();
    scrollController.dispose();
    ref.invalidate(videoDetailsNotifierProvider);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoDetails = ref.watch(videoDetailsNotifierProvider);
    final selectedVideo = ref.watch(selectedVideoSP)!;

    final value = Helper.percentageFromValueInRange(
      min: playerMinHeight,
      max: playerMaxHeight,
      value: widget.height,
    );

    return value > 2
        ? Container()
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: Helper.valueFromPercentageInRange(
                            min: 106,
                            max: MediaQuery.of(context).size.width,
                            percentage: widget.percentage,
                          ),
                          child: GestureDetector(
                            onTap: () => ref
                                .read(miniPlayerControllerP)
                                .animateToHeight(state: PanelState.max),
                            child: PodVideoPlayer(
                              controller: playerController,
                              matchVideoAspectRatioToFrame: true,
                              alwaysShowProgressBar: true,
                              overlayBuilder: value < 0.96
                                  ? (options) => const SizedBox.shrink()
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      value > 0.96
                          ? IconButton(
                              onPressed: () => ref
                                  .read(miniPlayerControllerP)
                                  .animateToHeight(state: PanelState.min),
                              icon: const Icon(Icons.keyboard_arrow_down_sharp),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                  Expanded(
                    child: Opacity(
                      opacity:
                          widget.percentage <= 1 ? 1 - widget.percentage : 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.video.snippet.title,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    widget.video.snippet.channelTitle,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (playerController.isVideoPlaying)
                            Expanded(
                              child: IconButton(
                                onPressed: () => setState(
                                  () => playerController.pause(),
                                ),
                                icon: const Icon(Icons.pause_sharp),
                              ),
                            )
                          else if (!playerController.isVideoPlaying)
                            Expanded(
                              child: IconButton(
                                onPressed: () => setState(
                                  () => playerController.play(),
                                ),
                                icon: const Icon(Icons.play_arrow_sharp),
                              ),
                            )
                          else if (playerController.currentVideoPosition ==
                              playerController.totalVideoLength)
                            Expanded(
                              child: IconButton(
                                onPressed: () => setState(
                                  () => playerController.play(),
                                ),
                                icon: const Icon(Icons.replay_sharp),
                              ),
                            ),
                          Expanded(
                            child: IconButton(
                              onPressed: () {
                                ref
                                    .read(miniPlayerControllerP)
                                    .animateToHeight(state: PanelState.dismiss);
                              },
                              icon: const Icon(Icons.close_sharp),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Opacity(
                  opacity: widget.percentage <= 1 ? widget.percentage : 0,
                  child: ListView.builder(
                    controller: scrollController,
                    shrinkWrap: true,
                    itemCount: videoDetails.when(
                      loading: () => 1,
                      data: (videoInfo) {
                        final videos = videoInfo.videoInfo.data
                            .where((video) => video.id != selectedVideo.id)
                            .toList();

                        return videos.length + 1;
                      },
                      error: (failure, stackTrace) => 1,
                    ),
                    itemBuilder: (context, index) => videoDetails.when(
                      loading: () => const LoadingVideoScreen(),
                      data: (videoInfo) {
                        final videos = videoInfo.videoInfo.data
                            .where((video) => video.id != selectedVideo.id)
                            .toList();

                        if (index == 0) {
                          return VideoInfoTile(
                            video: selectedVideo,
                            channel: videoInfo.channel,
                            commentsInfo: videoInfo.comments,
                          );
                        }

                        // * if the selected video is the same as a video
                        // on the list of liked videos under the VIT, then
                        // just hide that video
                        if (videos[index - 1].id == selectedVideo.id) {
                          return const SizedBox.shrink();
                        }

                        return VideoCard(
                          video: videos[index - 1],
                          isInView: false,
                          maximize: false,
                          onTap: () {
                            playerController.changeVideo(
                              playVideoFrom: PlayVideoFrom.youtube(
                                'https://youtu.be/${videos[index - 1].id}',
                              ),
                            );

                            scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeIn,
                            );
                          },
                        );
                      },
                      error: (failure, stackTrace) => FailureTile(
                        failure: failure as YoutubeFailure,
                        onTap: reloadData,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}
