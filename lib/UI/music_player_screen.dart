import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marquee/marquee.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tunify/logic/music_provider.dart';

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  String _formatDuration(Duration? duration) {
    if (duration == null) return "--:--";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Consumer<MusicProvider>(
      builder: (context, provider, child) {
        final song = provider.currentSong;
        if (song == null) {
          Navigator.pop(context);
          return const SizedBox();
        }

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Đang phát", style: TextStyle(color: Colors.white, fontSize: 16)),
            centerTitle: true,
            actions: [
              // Nút Thả tim (Yêu thích)
              IconButton(
                icon: Icon(
                  song.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: song.isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () {
                  provider.toggleFavorite(song);
                },
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                SizedBox(height: height * 0.05),
                // Ảnh bìa
                Hero(
                  tag: 'album_art',
                  child: Container(
                    height: height * 0.4,
                    width: height * 0.4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: song.artUri,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => Container(color: Colors.grey[800], child: const Icon(Icons.music_note, size: 80, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.08),

                // Tên bài hát
                SizedBox(
                  height: 40,
                  child: Marquee(
                    text: song.title,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    scrollAxis: Axis.horizontal, crossAxisAlignment: CrossAxisAlignment.start,
                    blankSpace: 20.0, velocity: 30.0, pauseAfterRound: const Duration(seconds: 3),
                  ),
                ),
                Text(song.artist, style: const TextStyle(color: Colors.grey, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                const Spacer(),

                // Slider
                StreamBuilder<Duration>(
                  stream: provider.audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = provider.audioPlayer.duration ?? Duration.zero;
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            trackHeight: 2, activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.grey[800], thumbColor: Colors.white,
                          ),
                          child: Slider(
                            min: 0, max: duration.inSeconds.toDouble(),
                            value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                            onChanged: (value) => provider.seek(Duration(seconds: value.toInt())),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(_formatDuration(duration), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: height * 0.02),

                // --- BẢNG ĐIỀU KHIỂN (Controls) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nút Shuffle (Xáo trộn)
                    IconButton(
                      icon: Icon(Icons.shuffle,
                          color: provider.isShuffle ? const Color(0xFF1DB954) : Colors.grey),
                      onPressed: () => provider.toggleShuffle(),
                    ),

                    // Nút Previous (Lùi bài)
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
                      onPressed: () => provider.playPrevious(),
                    ),

                    // Nút Play/Pause
                    Container(
                      height: 70, width: 70,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: IconButton(
                        icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 36),
                        onPressed: () {
                          if (provider.isPlaying) provider.pause(); else provider.resume();
                        },
                      ),
                    ),

                    // Nút Next (Qua bài)
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
                      onPressed: () => provider.playNext(),
                    ),

                    // Nút Repeat (Lặp lại)
                    IconButton(
                      icon: Icon(
                          provider.loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                          color: provider.loopMode != LoopMode.off ? const Color(0xFF1DB954) : Colors.grey
                      ),
                      onPressed: () => provider.toggleRepeat(),
                    ),
                  ],
                ),
                SizedBox(height: height * 0.05),
              ],
            ),
          ),
        );
      },
    );
  }
}