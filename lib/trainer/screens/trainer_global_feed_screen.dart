import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trainer_post_model.dart';
import '../widgets/trainer_post_card.dart';

class TrainerGlobalFeedScreen extends StatelessWidget {
  const TrainerGlobalFeedScreen({super.key});

  Widget _buildFeaturedCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
        ],
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1470&auto=format&fit=crop'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Colors.black54, Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.bottomLeft,
        child: Text(
          'Featured: Fitora Pro Arena',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 16,
        centerTitle: false,
        title: GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/trainer-search'),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text('Search network...', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "It's quiet here. Inspiring posts will appear soon!",
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          final posts = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return TrainerPostModel.fromMap(data, doc.id);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => await Future.delayed(const Duration(seconds: 1)),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: posts.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildFeaturedCard();
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TrainerPostCard(post: posts[index - 1]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
