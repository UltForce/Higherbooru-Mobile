import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_post_page.dart';
import 'profile_page.dart';
import 'login_form.dart';
import 'my_posts_page.dart';
import 'post_details_page.dart';
import 'artist_profile_page.dart';
import 'liked_posts_page.dart';
import 'following_feed.dart';

class GalleryFeed extends StatefulWidget {
  const GalleryFeed({super.key});

  @override
  State<GalleryFeed> createState() => _GalleryFeedState();
}

class _GalleryFeedState extends State<GalleryFeed> {
  List<DocumentSnapshot> posts = [];
  bool isLoading = true;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'timestamp';

  @override
  void initState() {
    super.initState();
    loadPosts();
  }

  Future<void> loadPosts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    Query query = FirebaseFirestore.instance.collection('tbl_posts');

    if (_sortOption == 'likes_count' || _sortOption == 'comments_count') {
      query = query.orderBy(_sortOption, descending: true);
    } else if (_sortOption == 'oldest') {
      query = query.orderBy('timestamp', descending: false);
    } else {
      query = query.orderBy('timestamp', descending: true);
    }


    final snapshot = await query.get();

    final filteredPosts = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['user_id'] != currentUser.uid;
    }).toList();

    setState(() {
      posts = filteredPosts;
      isLoading = false;
    });
  }


  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginForm()),
              (route) => false,
        );
      }
    }
  }

  void _navigateTo(Widget page) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('tbl_artists')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const DrawerHeader(
                        decoration: BoxDecoration(color: Colors.blue),
                        child: Center(child: CircularProgressIndicator(color: Colors.white)),
                      );
                    }

                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    final profilePicture = userData['profilePicture'] ?? '';
                    final userName = userData['name'] ?? 'User';

                    return InkWell(
                      onTap: () => _navigateTo(const ProfilePage()),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(color: Colors.blue),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage:
                              profilePicture.isNotEmpty ? NetworkImage(profilePicture) : null,
                              child: profilePicture.isEmpty
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              userName,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.home),
                        title: const Text('Gallery Feed'),
                        onTap: () => Navigator.pop(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.people),
                        title: const Text('Following Feed'),
                        onTap: () => _navigateTo(const FollowingFeedPage()),
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('My Posts'),
                        onTap: () => _navigateTo(const MyPostsPage()),
                      ),
                      ListTile(
                        leading: const Icon(Icons.favorite),
                        title: const Text('Liked Posts'),
                        onTap: () => _navigateTo(const LikedPostsPage()),
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: _confirmLogout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

      appBar: AppBar(
        title: const Text('Gallery Feed'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
          ? const Center(child: Text('No posts available.'))
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
                    loadPosts();
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'timestamp',
                      child: Text('Newest'),
                    ),
                    DropdownMenuItem(
                      value: 'oldest',
                      child: Text('Oldest'),
                    ),
                    DropdownMenuItem(
                      value: 'likes_count',
                      child: Text('Most Liked'),
                    ),
                    DropdownMenuItem(
                      value: 'comments_count',
                      child: Text('Most Commented'),
                    ),
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

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('tbl_artists').doc(userId).get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                    final artistName = userData?['name'] ?? 'Unknown Artist';
                    final artistPic = userData?['profilePicture'];
                    final artistId = userData?['user_id'];
                    final postId = postData['post_id'];
                    final content = postData['content'] ?? '';
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                    // Apply search filter
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
                            builder: (context) => PostDetailsPage(
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
                                      builder: (context) => ArtistProfilePage(userId: postData['user_id'], currentUserId: currentUserId!),
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
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                content,
                                style: const TextStyle(fontSize: 16),
                              ),
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
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostPage()),
          ).then((_) => loadPosts());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
