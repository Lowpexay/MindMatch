import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final double radius;
  final String? fallbackAsset;
  final bool useAuthPhoto;

  const UserAvatar({
    Key? key,
    this.imageUrl,
    this.imageBytes,
    this.radius = 24.0,
  this.fallbackAsset,
    this.useAuthPhoto = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authPhoto = useAuthPhoto ? FirebaseAuth.instance.currentUser?.photoURL : null;
    final effectiveUrl = imageUrl ?? authPhoto;
    
    // Debug logs
    print('🖼️ UserAvatar build:');
    print('   - imageUrl: $imageUrl');
    print('   - imageBytes: ${imageBytes != null ? 'Present (${imageBytes!.length} bytes)' : 'null'}');
    print('   - effectiveUrl: $effectiveUrl');
    print('   - authPhoto: $authPhoto');
    print('   - useAuthPhoto: $useAuthPhoto');
    
    ImageProvider? bg;
    if (imageBytes != null && imageBytes!.isNotEmpty) {
      bg = MemoryImage(imageBytes!);
      print('   - Using MemoryImage (base64)');
    } else if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
      bg = CachedNetworkImageProvider(effectiveUrl) as ImageProvider;
      print('   - Using CachedNetworkImageProvider: $effectiveUrl');
    } else if (fallbackAsset != null) {
      bg = AssetImage(fallbackAsset!);
      print('   - Using AssetImage: $fallbackAsset');
    } else {
      print('   - Using default icon');
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: bg,
      child: bg == null ? Icon(Icons.person, size: radius) : null,
    );
  }
}
