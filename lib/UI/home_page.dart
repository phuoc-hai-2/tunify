import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../logic/music_provider.dart';
import 'music_player_screen.dart'; // Đảm bảo import màn hình player

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController searchController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 10, // Giảm khoảng cách mặc định để vừa vặn hơn
        title: Row(
          children: [
            // 1. Ô TÌM KIẾM
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Tìm trên SoundCloud...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    contentPadding: const EdgeInsets.only(top: 5),
                  ),
                  onSubmitted: (val) {
                    if (val.isNotEmpty) {
                      context.read<MusicProvider>().fetchMusic(val);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(width: 5),

            // 2. NÚT HOME (Quay về trang chủ/Gợi ý)
            IconButton(
              icon: const Icon(Icons.home_filled, color: Colors.white),
              tooltip: "Trang chủ",
              onPressed: () {
                // Xóa ô tìm kiếm
                searchController.clear();
                // Ẩn bàn phím nếu đang hiện
                FocusScope.of(context).unfocus();
                // Tải lại nhạc gợi ý ban đầu (Ví dụ: Lofi Chill, Trending...)
                context.read<MusicProvider>().fetchMusic("Lofi Chill");
              },
            ),

            // 3. NÚT YÊU THÍCH (Mở Playlist tim)
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.redAccent),
              tooltip: "Danh sách yêu thích",
              onPressed: () {
                context.read<MusicProvider>().showFavorites();
              },
            )
          ],
        ),
      ),

      // --- PHẦN BODY GIỮ NGUYÊN ---
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (provider.songs.isEmpty) {
            return const Center(
                child: Text("Danh sách trống.",
                    style: TextStyle(color: Colors.grey))
            );
          }

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
                          errorWidget: (c, u, e) => const Icon(Icons.music_note, color: Colors.white),
                        ),
                      ),
                      title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: isSelected ? Colors.orange : Colors.white,
                              fontWeight: FontWeight.bold
                          )
                      ),
                      subtitle: Text(song.artist, style: const TextStyle(color: Colors.grey)),
                      onTap: () => provider.playSong(song),

                      // Hiển thị trạng thái đang phát hoặc trái tim bên phải
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (song.isFavorite)
                            const Icon(Icons.favorite, color: Colors.red, size: 16),
                          const SizedBox(width: 10),
                          if (isSelected && provider.isPlaying)
                            const Icon(Icons.graphic_eq, color: Colors.orange),
                        ],
                      ),
                    );
                  },
                ),
              ),

              if (provider.currentSong != null) _buildMiniPlayer(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context, MusicProvider provider) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const MusicPlayerScreen(),
        );
      },
      child: Container(
        color: const Color(0xFF282828),
        padding: const EdgeInsets.all(8),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Hero(
                tag: 'album_art',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: provider.currentSong!.artUri,
                    width: 50, height: 50, fit: BoxFit.cover,
                    errorWidget: (c,u,e) => const Icon(Icons.music_note, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
      ),
    );
  }
}