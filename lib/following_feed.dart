import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'post_details_page.dart';
import 'artist_profile_page.dart';

class FollowingFeedPage extends StatefulWidget {
  const FollowingFeedPage({super.key});

  @override
  State<FollowingFeedPage> createState() => _FollowingFeedPageState();
}

class _FollowingFeedPageState extends State<FollowingFeedPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  List<DocumentSnapshot> posts = [];
  String _searchQuery = '';
  String _sortOption = 'timestamp';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadFollowedPosts();
  }

  Future<void> loadFollowedPosts() async {
    setState(() => isLoading = true);

    final followedSnapshot = await FirebaseFirestore.instance
        .collection('tbl_followers')
        .where('follower_id', isEqualTo: currentUser?.uid ?? '')
        .get();

    final followedIds = followedSnapshot.docs.map((doc) => doc['artist_id'] as String).toList();

    if (followedIds.isEmpty) {
      setState(() {
        posts = [];
        isLoading = false;
      });
      return;
    }

    Query query = FirebaseFirestore.instance
        .collection('tbl_posts')
        .where('user_id', whereIn: followedIds);

    switch (_sortOption) {
      case 'oldest':
        query = query.orderBy('timestamp', descending: false);
        break;
      case 'likes_count':
      case 'comments_count':
        query = query.orderBy(_sortOption, descending: true);
        break;
      default:
        query = query.orderBy('timestamp', descending: true);
    }

    final postsSnapshot = await query.get();

    setState(() {
      posts = postsSnapshot.docs;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Following Feed'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
          ? const Center(child: Text('No posts from followed artists yet.'))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by artist or content...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _sortOption,
                  borderRadius: BorderRadius.circular(10),
                  onChanged: (String? newValue) {
                    setState(() {
                      _sortOption = newValue!;
                      isLoading = true;
                    });
                    loadFollowedPosts();
                  },
                  items: const [
                    DropdownMenuItem(value: 'timestamp', child: Text('Newest')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                    DropdownMenuItem(value: 'likes_count', child: Text('Most Liked')),
                    DropdownMenuItem(value: 'comments_count', child: Text('Most Commented')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final postData = posts[index].data() as Map<String, dynamic>;
                final imageUrls = List<String>.from(postData['image_url'] ?? []);
                final timestamp = postData['timestamp'] as Timestamp?;
                final formattedDate = timestamp != null
                    ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                    : 'Unknown date';
                final userId = postData['user_id'];
                final postId = postData['post_id'];
                final content = postData['content'] ?? '';
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('tbl_artists').doc(userId).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                    final artistName = userData?['name'] ?? 'Unknown Artist';
                    final artistPic = userData?['profilePicture'];

                    // Filter by search
                    final matchesQuery = artistName.toLowerCase().contains(_searchQuery) ||
                        content.toLowerCase().contains(_searchQuery);
                    if (_searchQuery.isNotEmpty && !matchesQuery) {
                      return const SizedBox.shrink();
                    }

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailsPage(
                              postId: postId,
                              content: content,
                              imageUrls: imageUrls,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ArtistProfilePage(
                                        userId: userId,
                                        currentUserId: currentUserId!,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage: artistPic != null ? NetworkImage(artistPic) : null,
                                      backgroundColor: Colors.grey[300],
                                      child: artistPic == null
                                          ? const Icon(Icons.person, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      artistName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(content, style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 10),
                              if (imageUrls.isNotEmpty)
                                SizedBox(
                                  height: 200,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: imageUrls.length,
                                    itemBuilder: (context, i) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            imageUrls[i],
                                            fit: BoxFit.cover,
                                            width: 200,
                                            height: 200,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('❤️ ${postData['likes_count'] ?? 0}  💬 ${postData['comments_count'] ?? 0}'),
                                  Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
