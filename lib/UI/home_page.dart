import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../logic/music_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController searchController = TextEditingController();

    return Scaffold(
      // --- APP BAR: THANH TÌM KIẾM ---
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
                hintText: "Tìm bài hát, ca sĩ...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                contentPadding: const EdgeInsets.only(top: 5),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    if(searchController.text.isNotEmpty) {
                      context.read<MusicProvider>().fetchMusic(searchController.text);
                      FocusScope.of(context).unfocus(); // Ẩn bàn phím
                    }
                  },
                )
            ),
            onSubmitted: (val) {
              if(val.isNotEmpty) context.read<MusicProvider>().fetchMusic(val);
            },
          ),
        ),
      ),

      // --- BODY CHÍNH ---
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          // 1. Đang tải danh sách
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          // 2. Không có dữ liệu
          if (provider.songs.isEmpty) {
            return const Center(
                child: Text("Hãy tìm kiếm bài hát bạn thích!",
                    style: TextStyle(color: Colors.grey))
            );
          }

          // 3. Hiển thị danh sách
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: provider.songs.length,
                  itemBuilder: (context, index) {
                    final song = provider.songs[index];
                    final isSelected = provider.currentSong?.id == song.id;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: song.artUri,
                          width: 50, height: 50, fit: BoxFit.cover,
                          placeholder: (c, u) => Container(color: Colors.grey[900]),
                          errorWidget: (c, u, e) => const Icon(Icons.music_note),
                        ),
                      ),
                      title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isSelected ? Colors.green : Colors.white,
                              fontWeight: FontWeight.bold
                          )
                      ),
                      subtitle: Text(song.artist, style: const TextStyle(color: Colors.grey)),
                      onTap: () => provider.playSong(song),
                      // Hiển thị trạng thái đang phát hoặc đang load nhạc
                      trailing: _buildTrailingIcon(isSelected, provider),
                    );
                  },
                ),
              ),

              // 4. MINI PLAYER (Thanh phát nhạc dưới đáy)
              if (provider.currentSong != null) _buildMiniPlayer(context, provider),
            ],
          );
        },
      ),
    );
  }

  // Icon trạng thái ở mỗi dòng bài hát
  Widget? _buildTrailingIcon(bool isSelected, MusicProvider provider) {
    if (!isSelected) return null;

    if (provider.isBuffering) {
      return const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green));
    }

    if (provider.isPlaying) {
      return const Icon(Icons.graphic_eq, color: Colors.green);
    }

    return null;
  }

  // Widget Mini Player
  Widget _buildMiniPlayer(BuildContext context, MusicProvider provider) {
    return Container(
      color: const Color(0xFF282828),
      padding: const EdgeInsets.all(8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Ảnh bìa
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: provider.currentSong!.artUri,
                width: 50, height: 50, fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            // Tên bài
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.currentSong!.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(provider.currentSong!.artist,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Nút điều khiển
            if (provider.isBuffering)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              )
            else
              IconButton(
                icon: Icon(
                  provider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: Colors.white, size: 40,
                ),
                onPressed: () {
                  if(provider.isPlaying) provider.pause();
                  else provider.resume();
                },
              ),
          ],
        ),
      ),
    );
  }
}