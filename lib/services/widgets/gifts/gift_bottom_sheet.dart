import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/gift.dart';
import '../../gift_service.dart';
import 'package:lottie/lottie.dart';

class GiftBottomSheet extends StatefulWidget {
  final int recipientId;
  final String recipientUsername;
  final int? conversationId;
  final Function(Gift gift, bool isAnonymous)? onGiftSent;

  const GiftBottomSheet({
    super.key,
    required this.recipientId,
    required this.recipientUsername,
    this.conversationId,
    this.onGiftSent,
  });

  static Future<void> show(
    BuildContext context, {
    required int recipientId,
    required String recipientUsername,
    int? conversationId,
    Function(Gift gift, bool isAnonymous)? onGiftSent,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GiftBottomSheet(
        recipientId: recipientId,
        recipientUsername: recipientUsername,
        conversationId: conversationId,
        onGiftSent: onGiftSent,
      ),
    );
  }

  @override
  State<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<GiftBottomSheet> {
  final GiftService _giftService = GiftService();

  List<GiftCategory> _categories = [];
  List<Gift> _gifts = [];
  int? _selectedCategoryId;
  Gift? _selectedGift;
  bool _isAnonymous = true;
  bool _isLoading = true;
  bool _isSending = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _giftService.getCategories();
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
          _loadGifts(categories.first.id);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGifts(int categoryId) async {
    try {
      final gifts = await _giftService.getGiftsByCategory(categoryId);
      setState(() {
        _gifts = gifts;
        _selectedGift = null;
      });
    } catch (e) {
      debugPrint('Error loading gifts: $e');
    }
  }

  Future<void> _sendGift() async {
    if (_selectedGift == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      if (widget.conversationId != null) {
        await _giftService.sendGiftInConversation(
          conversationId: widget.conversationId!,
          giftId: _selectedGift!.id,
          isAnonymous: _isAnonymous,
        );
      } else {
        await _giftService.sendGift(
          recipientUsername: widget.recipientUsername,
          giftId: _selectedGift!.id,
          isAnonymous: _isAnonymous,
        );
      }

      setState(() {
        _showSuccess = true;
      });

      widget.onGiftSent?.call(_selectedGift!, _isAnonymous);

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _showSuccess ? _buildSuccessView() : _buildGiftSelector(),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/gift_sent.json',
            width: 200,
            height: 200,
            repeat: false,
          ),
          const SizedBox(height: 16),
          const Text(
            'Cadeau envoyé !',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Votre ${_selectedGift?.name} a été envoyé à ${widget.recipientUsername}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftSelector() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  'Envoyer un cadeau à ${widget.recipientUsername}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // Category tabs
        if (_categories.isNotEmpty)
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategoryId == category.id;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id;
                    });
                    _loadGifts(category.id);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: isSelected ? null : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 16),

        // Gifts grid
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _gifts.length,
                  itemBuilder: (context, index) {
                    final gift = _gifts[index];
                    final isSelected = _selectedGift?.id == gift.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGift = gift;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (gift.imageUrl != null)
                              CachedNetworkImage(
                                imageUrl: gift.imageUrl!,
                                width: 48,
                                height: 48,
                              )
                            else
                              ShaderMask(
                                shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                                child: const Icon(
                                  Icons.card_giftcard,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              gift.name,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${gift.price.toInt()} FCFA',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Bottom section
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Anonymous toggle
              Row(
                children: [
                  Checkbox(
                    value: _isAnonymous,
                    onChanged: (value) {
                      setState(() {
                        _isAnonymous = value ?? true;
                      });
                    },
                    activeColor: AppColors.secondary,
                  ),
                  const Text('Envoyer anonymement'),
                  const Spacer(),
                  if (_selectedGift != null)
                    Text(
                      '${_selectedGift!.price.toInt()} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Send button avec dégradé
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: _selectedGift != null && !_isSending ? AppColors.primaryGradient : null,
                  color: _selectedGift != null && !_isSending ? null : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _selectedGift != null && !_isSending
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _selectedGift != null && !_isSending ? _sendGift : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _selectedGift != null
                                  ? 'Envoyer ${_selectedGift!.name}'
                                  : 'Sélectionnez un cadeau',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _selectedGift != null ? Colors.white : Colors.grey,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
