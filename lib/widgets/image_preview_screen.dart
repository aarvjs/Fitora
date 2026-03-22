import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String heroTag;
  final String imageUrl;

  const ImagePreviewScreen({
    super.key,
    required this.heroTag,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Center(
                child: Text('Image not found',
                    style: GoogleFonts.inter(color: Colors.white54)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
