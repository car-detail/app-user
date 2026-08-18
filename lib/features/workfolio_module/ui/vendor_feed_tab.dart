import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data_manager/workfolio_data_manager.dart';
import '../model/workfolio_post.dart';

/// Compact grid of a single vendor's Workfolio posts — used as the "Feed"
/// tab on the vendor detail page. Unlike the main app-wide Feed (a single
/// scrolling column), a per-vendor view reads better as an Instagram
/// profile-style photo grid.
class VendorFeedTab extends StatefulWidget {
  final String vendorId;

  const VendorFeedTab({required this.vendorId, super.key});

  @override
  State<VendorFeedTab> createState() => _VendorFeedTabState();
}

class _VendorFeedTabState extends State<VendorFeedTab> {
  List<WorkfolioPost>? _posts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataManager = WorkfolioDataManager(prefs);
      final response = await dataManager.getFeed(context, vendorId: widget.vendorId, page: 1, limit: 30);
      if (!mounted) return;
      final body = jsonDecode(response.body);
      final records = (body['data']?['records'] as List?) ?? [];
      setState(() {
        _posts = records.map((r) => WorkfolioPost.fromJson(r)).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openPost(WorkfolioPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    child: Image.network(post.image, fit: BoxFit.contain, width: double.infinity),
                  ),
                ),
                if (post.caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        post.caption,
                        style: const TextStyle(color: Colors.white70, fontFamily: "Pop400", fontSize: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final posts = _posts ?? [];
    if (posts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_camera_back_outlined, color: Colors.grey[400], size: 56),
            const SizedBox(height: 16),
            Text(
              "No posts yet from this vendor",
              style: TextStyle(fontSize: 15, fontFamily: "Pop500", color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final post = posts[index];
        return GestureDetector(
          onTap: () => _openPost(post),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              post.image,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(color: Colors.grey[200]);
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 18),
              ),
            ),
          ),
        );
      },
    );
  }
}
