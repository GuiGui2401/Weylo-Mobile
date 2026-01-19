import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../services/promotion_service.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final PromotionService _promotionService = PromotionService();
  final Map<String, Future<Uint8List?>> _videoThumbCache = {};
  bool _isLoading = true;
  List<Map<String, dynamic>> _promotions = [];

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    try {
      final response = await _promotionService.getMyPromotions();
      final data = response['data'];
      final items = data is Map<String, dynamic> ? data['data'] : data;
      setState(() {
        _promotions = List<Map<String, dynamic>>.from(items ?? []);
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openStats(int promotionId) async {
    try {
      final response = await _promotionService.getPromotionStats(promotionId);
      final stats = response['data'] ?? {};
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statistiques en temps réel',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _statRow('Impressions', '${stats['impressions'] ?? 0}'),
                  _statRow('Clics', '${stats['clicks'] ?? 0}'),
                  _statRow('CTR', '${stats['ctr'] ?? 0}%'),
                  _statRow('Budget dépensé', '${stats['budget_spent'] ?? 0}'),
                  _statRow('Reach estimé', '${stats['estimated_reach'] ?? '-'}'),
                  _statRow('Vues estimées', '${stats['estimated_views'] ?? '-'}'),
                  _statRow('Temps restant', '${stats['time_remaining'] ?? '-'}'),
                ],
              ),
            ),
          );
        },
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotions'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPromotions,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _promotions.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Aucune promotion en cours')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _promotions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final promo = _promotions[index];
                      final status = promo['status'] ?? 'active';
                      final amount = promo['amount'] ?? 0;
                      final goal = promo['goal'] ?? 'video_views';
                      final duration = promo['duration_hours'] ?? 0;
                      final confession = promo['confession'] as Map<String, dynamic>?;
                      final mediaUrl = _resolveMediaUrl(
                        confession?['video_url'] ?? confession?['image_url'],
                      );
                      final hasVideo = (confession?['video_url'] ?? '').toString().isNotEmpty;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (confession != null)
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 72,
                                      height: 90,
                                      child: hasVideo
                                          ? _buildVideoThumb(mediaUrl)
                                          : CachedNetworkImage(
                                              imageUrl: mediaUrl,
                                              fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => Container(
                                                color: Colors.grey[300],
                                                child: const Icon(Icons.broken_image_outlined),
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (confession['content'] ?? '').toString().isEmpty
                                              ? 'Publication sans texte'
                                              : confession['content'].toString(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'ID: ${confession['id'] ?? '-'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            if (confession != null) const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'active'
                                        ? AppColors.success.withOpacity(0.12)
                                        : Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status.toString().toUpperCase(),
                                    style: TextStyle(
                                      color: status == 'active'
                                          ? AppColors.success
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$amount FCFA',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _goalLabel(goal.toString()),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Durée: $duration h',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _openStats(promo['id'] ?? 0),
                                    child: const Text('Voir stats'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _goalLabel(String key) {
    switch (key) {
      case 'profile_views':
        return 'Vues profil';
      case 'followers':
        return 'Abonnés';
      case 'messages':
        return 'Messages';
      case 'website':
        return 'Visites site';
      case 'conversions':
        return 'Conversions';
      default:
        return 'Vues vidéo';
    }
  }

  Widget _buildVideoThumb(String url) {
    if (url.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.videocam),
      );
    }
    final future = _videoThumbCache.putIfAbsent(
      url,
      () => VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: ImageFormat.JPEG,
        quality: 70,
        maxWidth: 360,
      ),
    );
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.videocam),
        );
      },
    );
  }

  String _resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    final cleaned = url.replaceAll('\\', '/');
    final base = ApiConstants.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    final baseUri = Uri.parse(base);

    if (cleaned.startsWith('http')) {
      final mediaUri = Uri.parse(cleaned);
      if (mediaUri.host != baseUri.host || mediaUri.port != baseUri.port) {
        final rewritten = mediaUri.replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.hasPort ? baseUri.port : null,
        );
        return Uri.encodeFull(rewritten.toString());
      }
      return Uri.encodeFull(cleaned);
    }
    if (cleaned.startsWith('//')) return Uri.encodeFull('https:$cleaned');
    if (cleaned.startsWith('/storage/')) return Uri.encodeFull('$base$cleaned');
    if (cleaned.startsWith('storage/')) return Uri.encodeFull('$base/$cleaned');
    return Uri.encodeFull('$base/storage/$cleaned');
  }
}
