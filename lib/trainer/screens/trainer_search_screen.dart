import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trainer_model.dart';
import '../screens/trainer_profile_screen.dart';

class TrainerSearchScreen extends StatefulWidget {
  const TrainerSearchScreen({super.key});

  @override
  State<TrainerSearchScreen> createState() => _TrainerSearchScreenState();
}

class _TrainerSearchScreenState extends State<TrainerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = "";
  List<TrainerModel> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.trim().toLowerCase();
        });
        _performSearch();
      }
    });
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('trainers')
          .where('username', isGreaterThanOrEqualTo: _searchQuery)
          .where('username', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          .limit(20)
          .get();
          
      final results = snapshot.docs.map((doc) => TrainerModel.fromMap(doc.data(), doc.id)).toList();
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch(e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          autofocus: true,
          style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Search trainers by username...',
            hintStyle: GoogleFonts.inter(color: Colors.grey[500]),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchQuery.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Search for trainers',
                        style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_search, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            'No trainers found',
                            style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Try a different username',
                            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final trainer = _searchResults[index];
                        return _SearchResultCard(
                          trainer: trainer,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TrainerProfileScreen(trainerId: trainer.id)),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final TrainerModel trainer;
  final VoidCallback onTap;


  const _SearchResultCard({required this.trainer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Profile image on the LEFT
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[200],
              backgroundImage: trainer.profileImage.isNotEmpty
                  ? CachedNetworkImageProvider(trainer.profileImage)
                  : null,
              child: trainer.profileImage.isEmpty
                  ? const Icon(Icons.person, color: Colors.grey, size: 28)
                  : null,
            ),
            const SizedBox(width: 14),
            // Name (bold, top) and Username (below, smaller)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trainer.name,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${trainer.username}',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                  if (trainer.bio != null && trainer.bio!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      trainer.bio!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ]
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
