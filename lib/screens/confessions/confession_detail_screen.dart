import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../models/confession.dart';
import '../../services/confession_service.dart';
import '../../widgets/common/avatar_widget.dart';

class ConfessionDetailScreen extends StatefulWidget {
  final int confessionId;

  const ConfessionDetailScreen({super.key, required this.confessionId});

  @override
  State<ConfessionDetailScreen> createState() => _ConfessionDetailScreenState();
}

class _ConfessionDetailScreenState extends State<ConfessionDetailScreen> {
  final ConfessionService _confessionService = ConfessionService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Confession? _confession;
  List<ConfessionComment> _comments = [];
  bool _isLoading = true;
  bool _isLoadingComments = false;
  bool _isSendingComment = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConfession();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConfession() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final confession = await _confessionService.getConfession(widget.confessionId);

      setState(() {
        _confession = confession;
        _isLoading = false;
      });

      _loadComments();
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadComments() async {
    try {
      setState(() => _isLoadingComments = true);

      final comments = await _confessionService.getComments(widget.confessionId);

      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      setState(() => _isSendingComment = true);

      final comment = await _confessionService.addComment(
        widget.confessionId,
        content,
      );

      _commentController.clear();

      setState(() {
        _comments.insert(0, comment);
        _isSendingComment = false;
        if (_confession != null) {
          _confession = _confession!.copyWith(
            commentsCount: _confession!.commentsCount + 1,
          );
        }
      });

      // Scroll to top to show new comment
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      setState(() => _isSendingComment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_confession == null) return;

    try {
      if (_confession!.isLiked) {
        final updated = await _confessionService.unlikeConfession(widget.confessionId);
        setState(() => _confession = updated);
      } else {
        final updated = await _confessionService.likeConfession(widget.confessionId);
        setState(() => _confession = updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _shareConfession() {
    if (_confession == null) return;

    final shareUrl = 'https://weylo.app/post/${_confession!.id}';
    Share.share(
      'Decouvre cette publication sur Weylo! $shareUrl',
      subject: 'Publication Weylo',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publication'),
        actions: [
          // Bouton pour révéler l'identité si la publication est anonyme
          if (_confession != null &&
              !_confession!.isIdentityRevealed &&
              _confession!.isAnonymous)
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: _showRevealIdentityDialog,
              tooltip: 'Découvrir l\'identité',
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareConfession,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConfession,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }

    if (_confession == null) {
      return const Center(child: Text('Publication non trouvee'));
    }

    return RefreshIndicator(
      onRefresh: _loadConfession,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfessionCard(),
            const Divider(height: 1),
            _buildCommentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfessionCard() {
    final confession = _confession!;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with author info
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (confession.isIdentityRevealed && confession.author != null) {
                    context.push('/u/${confession.author!.username}');
                  }
                },
                child: _buildAvatar(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (confession.isIdentityRevealed && confession.author != null) {
                          context.push('/u/${confession.author!.username}');
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            confession.isIdentityRevealed && confession.author != null
                                ? confession.author!.fullName
                                : 'Anonyme',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (confession.author?.isPremium == true) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: const Color(0xFF1877F2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Helpers.getTimeAgo(confession.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showOptions(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          if (confession.content.isNotEmpty)
            Text(
              confession.content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),

          // Image
          if (confession.hasImage) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: confession.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.error_outline, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Icon(Icons.visibility_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${Helpers.formatNumber(confession.viewsCount)} vues',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.favorite, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${Helpers.formatNumber(confession.likesCount)} j\'aime',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${Helpers.formatNumber(confession.commentsCount)} commentaires',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Actions row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon: confession.isLiked ? Icons.favorite : Icons.favorite_outline,
                label: 'J\'aime',
                color: confession.isLiked ? AppColors.error : null,
                onTap: _toggleLike,
              ),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Commenter',
                onTap: () {
                  // Focus on comment input
                  FocusScope.of(context).requestFocus(FocusNode());
                },
              ),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: 'Partager',
                onTap: _shareConfession,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (_confession!.isIdentityRevealed && _confession!.author != null) {
      return AvatarWidget(
        imageUrl: _confession!.author!.avatar,
        name: _confession!.author!.fullName,
        size: 48,
      );
    }
    // Avatar anonyme avec possibilité de révéler l'identité
    return GestureDetector(
      onTap: _confession!.isAnonymous ? _showRevealIdentityDialog : null,
      child: Stack(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.person_off,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          if (_confession!.isAnonymous)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1877F2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Commentaires (${_confession?.commentsCount ?? 0})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        if (_isLoadingComments)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun commentaire',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Soyez le premier a commenter!',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _buildCommentItem(_comments[index]);
            },
          ),

        // Add some padding at the bottom
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCommentItem(ConfessionComment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              if (comment.user != null) {
                context.push('/u/${comment.user!.username}');
              }
            },
            child: AvatarWidget(
              imageUrl: comment.user?.avatar,
              name: comment.user?.fullName ?? 'Utilisateur',
              size: 36,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (comment.user != null) {
                          context.push('/u/${comment.user!.username}');
                        }
                      },
                      child: Text(
                        comment.user?.fullName ?? 'Utilisateur',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (comment.user?.isPremium == true) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: const Color(0xFF1877F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      Helpers.getTimeAgo(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Ajouter un commentaire...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          _isSendingComment
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendComment,
                  ),
                ),
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Option pour révéler l'identité si anonyme
            if (_confession != null &&
                !_confession!.isIdentityRevealed &&
                _confession!.isAnonymous)
              ListTile(
                leading: const Icon(Icons.visibility, color: Colors.amber),
                title: const Text('Découvrir l\'identité'),
                subtitle: const Text('450 FCFA'),
                onTap: () {
                  Navigator.pop(context);
                  _showRevealIdentityDialog();
                },
              ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Partager'),
              onTap: () {
                Navigator.pop(context);
                _shareConfession();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Signaler'),
              onTap: () {
                Navigator.pop(context);
                _reportConfession();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRevealIdentityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.visibility, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Découvrir l\'identité'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voulez-vous payer pour découvrir l\'identité de l\'auteur de cette publication ?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: Colors.amber),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coût',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '450 FCFA',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _revealIdentity();
              },
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Découvrir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _revealIdentity() async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final updatedConfession = await _confessionService.revealIdentity(widget.confessionId);

      if (mounted) {
        Navigator.pop(context); // Fermer le loading
        setState(() {
          _confession = updatedConfession;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    updatedConfession.author != null
                        ? 'Identité révélée : ${updatedConfession.author!.fullName}'
                        : 'Identité révélée !',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _reportConfession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler la publication'),
        content: const Text(
          'Voulez-vous signaler cette publication pour contenu inapproprie?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _confessionService.reportConfession(widget.confessionId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Publication signalee')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Signaler'),
          ),
        ],
      ),
    );
  }
}
