import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'post_details_page.dart';

class ArtistProfilePage extends StatefulWidget {
  final String userId; // artist ID
  final String currentUserId; // logged-in user ID

  const ArtistProfilePage({super.key, required this.userId, required this.currentUserId});

  @override
  State<ArtistProfilePage> createState() => _ArtistProfilePageState();
}

class _ArtistProfilePageState extends State<ArtistProfilePage> {
  bool isFollowing = false;
  int followersCount = 0;

  @override
  void initState() {
    super.initState();
    _checkFollowingStatus();
    _getFollowersCount();
  }

  Future<void> _checkFollowingStatus() async {
    final doc = await FirebaseFirestore.instance
        .collection('tbl_followers')
        .doc('${widget.currentUserId}_${widget.userId}')
        .get();

    setState(() {
      isFollowing = doc.exists;
    });
  }

  Future<void> _getFollowersCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tbl_followers')
        .where('artist_id', isEqualTo: widget.userId)
        .get();

    setState(() {
      followersCount = snapshot.docs.length;
    });
  }

  Future<void> _toggleFollow() async {
    final docRef = FirebaseFirestore.instance
        .collection('tbl_followers')
        .doc('${widget.currentUserId}_${widget.userId}');

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (isFollowing) {
      await docRef.delete();
      setState(() {
        isFollowing = false;
        followersCount--;
      });

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('You unfollowed this artist.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      await docRef.set({
        'follower_id': widget.currentUserId,
        'artist_id': widget.userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        isFollowing = true;
        followersCount++;
      });

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('You followed this artist!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artist Profile')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('tbl_artists').doc(widget.userId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData == null) {
            return const Center(child: Text('User not found'));
          }

          final profilePic = userData['profilePicture'];
          final name = userData['name'] ?? 'Unnamed Artist';
          final bio = userData['bio'] ?? '';

          return Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                child: profilePic == null ? const Icon(Icons.person, size: 50) : null,
              ),
              const SizedBox(height: 10),
              Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(bio, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text('$followersCount followers', style: const TextStyle(color: Colors.grey)),
              if (widget.userId != widget.currentUserId)
                ElevatedButton(
                  onPressed: _toggleFollow,
                  child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                ),
              const Divider(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('tbl_posts')
                      .where('user_id', isEqualTo: widget.userId)
                      .orderBy('timestamp', descending: true)
                      .get(),
                  builder: (context, postSnapshot) {
                    if (!postSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final posts = postSnapshot.data!.docs;

                    if (posts.isEmpty) {
                      return const Center(child: Text('No posts yet.'));
                    }

                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index].data() as Map<String, dynamic>;
                        final content = post['content'] ?? '';
                        final timestamp = post['timestamp'] as Timestamp?;
                        final imageUrls = List<String>.from(post['image_url'] ?? []);
                        final postId = post['post_id'];
                        final formattedDate = timestamp != null
                            ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                            : 'Unknown date';

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
                            margin: const EdgeInsets.all(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(content),
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
                                                width: 200,
                                                height: 200,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(color: Colors.grey),
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
          );
        },
      ),
    );
  }
}
