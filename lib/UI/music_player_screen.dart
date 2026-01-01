import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marquee/marquee.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tunify/logic/music_provider.dart';

class MusicPlayerScreen extends StatelessWidget {
  const MusicPlayerScreen({super.key});

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
        if (song == null) { Navigator.pop(context); return const SizedBox(); }

        final isDownloaded = song.localPath != null;

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: Colors.transparent, elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Now Playing", style: TextStyle(color: Colors.white)),
            centerTitle: true,
            actions: [
              // NÚT TIM (Yêu thích)
              IconButton(
                icon: Icon(song.isFavorite ? Icons.favorite : Icons.favorite_border, color: song.isFavorite ? Colors.green : Colors.white),
                onPressed: () => provider.toggleFavorite(song),
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
                    height: height * 0.4, width: height * 0.4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: song.artUri, fit: BoxFit.cover,
                        memCacheWidth: 600, // Tối ưu RAM cho ảnh to
                        errorWidget: (c,u,e) => Container(color: Colors.grey[800], child: const Icon(Icons.music_note, color: Colors.white)),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: height * 0.05),
                // Tên bài hát chạy chữ
                SizedBox(
                  height: 40,
                  child: Marquee(
                    text: song.title,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    scrollAxis: Axis.horizontal, blankSpace: 20.0, velocity: 30.0, pauseAfterRound: const Duration(seconds: 3),
                  ),
                ),
                Text(song.artist, style: const TextStyle(color: Colors.grey, fontSize: 18), maxLines: 1),

                // NÚT DOWNLOAD / DELETE
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (provider.isDownloading(song.id))
                      const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2))
                    else
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDownloaded ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                          foregroundColor: isDownloaded ? Colors.red : Colors.white,
                        ),
                        // Logic: Nếu đã tải -> Hiện nút Xóa. Nếu chưa -> Hiện nút Tải
                        icon: Icon(isDownloaded ? Icons.delete : Icons.download),
                        label: Text(isDownloaded ? "Xóa bản tải" : "Tải xuống"),
                        onPressed: () {
                          if (isDownloaded) {
                            provider.deleteDownloadedSong(song);
                          } else {
                            provider.downloadSong(song);
                          }
                        },
                      ),
                  ],
                ),

                const Spacer(),
                // Slider
                StreamBuilder<Duration>(
                  stream: provider.audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = provider.audioPlayer.duration ?? Duration.zero;
                    return Column(
                      children: [
                        Slider(
                          activeColor: Colors.green, inactiveColor: Colors.grey[800],
                          min: 0, max: duration.inSeconds.toDouble(),
                          value: position.inSeconds.toDouble().clamp(0, duration.inSeconds.toDouble()),
                          onChanged: (value) => provider.seek(Duration(seconds: value.toInt())),
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
                        )
                      ],
                    );
                  },
                ),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: Icon(Icons.shuffle, color: provider.isShuffle ? Colors.green : Colors.grey), onPressed: provider.toggleShuffle),
                    IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36), onPressed: provider.playPrevious),
                    Container(
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: IconButton(icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black, size: 36), onPressed: () => provider.isPlaying ? provider.pause() : provider.resume()),
                    ),
                    IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 36), onPressed: provider.playNext),
                    IconButton(icon: Icon(provider.loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat, color: provider.loopMode != LoopMode.off ? Colors.green : Colors.grey), onPressed: provider.toggleRepeat),
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