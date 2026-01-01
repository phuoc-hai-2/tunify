import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tunify/logic/music_provider.dart';
import 'package:tunify/UI/music_player_screen.dart';
import 'package:tunify/UI/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; // 0: Home, 1: Favorites, 2: Downloads
  final TextEditingController _searchCtrl = TextEditingController();

  void _onTabTapped(int index) {
    final provider = context.read<MusicProvider>();

    if (index == 3) { // Nút Logout
      provider.logout();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LocalLoginPage()));
      return;
    }

    setState(() => _currentIndex = index);

    // Load dữ liệu tương ứng với Tab
    if (index == 0) {
      if (_searchCtrl.text.isEmpty) provider.fetchMusic("V-Pop Hits");
      // Nếu có text tìm kiếm thì giữ nguyên kết quả tìm kiếm
    } else if (index == 1) {
      provider.showFavorites();
    } else if (index == 2) {
      provider.showDownloads();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),

      // 1. THANH TÌM KIẾM Ở TRÊN
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Tìm bài hát, nghệ sĩ...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              contentPadding: const EdgeInsets.only(top: 5),
            ),
            onSubmitted: (val) {
              if (val.isNotEmpty) {
                setState(() => _currentIndex = 0); // Về tab Home để hiện kết quả
                context.read<MusicProvider>().fetchMusic(val);
              }
            },
          ),
        ),
      ),

      //BODY (Danh sách nhạc)
      body: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator(color: Colors.green));
          if (provider.songs.isEmpty) return const Center(child: Text("Không có bài hát nào.", style: TextStyle(color: Colors.grey)));

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  cacheExtent: 100, // Tối ưu cuộn
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
                          memCacheWidth: 100, // Giảm RAM
                          placeholder: (c, u) => Container(color: Colors.grey[900]),
                          errorWidget: (c, u, e) => const Icon(Icons.music_note, color: Colors.white),
                        ),
                      ),
                      title: Text(
                          song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: isSelected ? Colors.green : Colors.white, fontWeight: FontWeight.bold)
                      ),
                      subtitle: Text(song.artist, style: const TextStyle(color: Colors.grey)),
                      trailing: song.localPath != null
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
                          : null,
                      onTap: () => provider.playSong(song),
                    );
                  },
                ),
              ),
              // Mini Player
              if (provider.currentSong != null) _buildMiniPlayer(context, provider),
            ],
          );
        },
      ),

      // THANH ĐIỀU HƯỚNG Ở DƯỚI
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: const Color(0xFF282828),
        selectedItemColor: const Color(0xFF1DB954),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorites"),
          BottomNavigationBarItem(icon: Icon(Icons.download_done), label: "Downloads"),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Logout"),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context, MusicProvider provider) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => const MusicPlayerScreen(),
      ),
      child: Container(
        color: const Color(0xFF282828),
        padding: const EdgeInsets.all(8),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: provider.currentSong!.artUri,
                  width: 50, height: 50, fit: BoxFit.cover,
                  memCacheWidth: 100,
                  errorWidget: (c,u,e) => const Icon(Icons.music_note, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(provider.currentSong!.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1),
                    Text(provider.currentSong!.artist, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                onPressed: () => provider.isPlaying ? provider.pause() : provider.resume(),
              )
            ],
          ),
        ),
      ),
    );
  }
}