import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../logic/music_provider.dart';
import 'music_player_screen.dart';

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
                hintText: "Tìm trên SoundCloud...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.cloud_queue, color: Colors.orange), // Logo cam đặc trưng
                contentPadding: const EdgeInsets.only(top: 5),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    if(searchController.text.isNotEmpty) {
                      context.read<MusicProvider>().fetchMusic(searchController.text);
                      FocusScope.of(context).unfocus();
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

      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (provider.songs.isEmpty) {
            return const Center(
                child: Text("Hãy thử tìm kiếm bài hát!",
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
                      trailing: _buildTrailingIcon(isSelected, provider),
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

  Widget? _buildTrailingIcon(bool isSelected, MusicProvider provider) {
    if (!isSelected) return null;

    if (provider.isBuffering) {
      return const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange));
    }

    if (provider.isPlaying) {
      return const Icon(Icons.graphic_eq, color: Colors.orange);
    }
    return null;
  }

  Widget _buildMiniPlayer(BuildContext context, MusicProvider provider) {
    // Bọc trong GestureDetector để bắt sự kiện nhấn
    return GestureDetector(
      onTap: () {
        // Mở màn hình Full Player theo kiểu trượt từ dưới lên (ModalBottomSheet)
        showModalBottomSheet(
          context: context,
          isScrollControlled: true, // Cho phép full màn hình
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
              // Ảnh bìa nhỏ (Có Hero tag để tạo hiệu ứng phóng to)
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

              // Tên bài hát
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

              // Nút Play/Pause nhỏ
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
                    // Cần xử lý sự kiện onPressed để nó KHÔNG kích hoạt onTap của GestureDetector cha
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