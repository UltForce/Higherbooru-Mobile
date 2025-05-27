import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'artist_profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowListPage extends StatelessWidget {
  final String userId;
  final bool isFollowers;

  const FollowListPage({super.key, required this.userId, required this.isFollowers});

  @override
  Widget build(BuildContext context) {
    final collection = FirebaseFirestore.instance.collection('tbl_followers');
    final query = isFollowers
        ? collection.where('artist_id', isEqualTo: userId)
        : collection.where('follower_id', isEqualTo: userId);

    return Scaffold(
      appBar: AppBar(title: Text(isFollowers ? 'Followers' : 'Following')),
      body: FutureBuilder<QuerySnapshot>(
        future: query.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(child: Text(isFollowers ? 'No followers yet.' : 'Not following anyone.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final otherUserId = isFollowers ? data['follower_id'] : data['artist_id'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('tbl_artists').doc(otherUserId).get(),
                builder: (context, artistSnapshot) {
                  if (!artistSnapshot.hasData) return const SizedBox.shrink();

                  final artistData = artistSnapshot.data!.data() as Map<String, dynamic>?;

                  if (artistData == null) return const SizedBox.shrink();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: artistData['profilePicture'] != null
                          ? NetworkImage(artistData['profilePicture'])
                          : null,
                      child: artistData['profilePicture'] == null ? const Icon(Icons.person) : null,
                    ),
                    title: Text(artistData['name'] ?? 'Unnamed'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArtistProfilePage(
                            userId: otherUserId,
                            currentUserId: FirebaseAuth.instance.currentUser!.uid,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
