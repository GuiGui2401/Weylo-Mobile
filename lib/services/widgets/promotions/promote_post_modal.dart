import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/media_utils.dart';
import '../../../models/confession.dart';
import '../../../providers/auth_provider.dart';
import '../../confession_service.dart';
import '../../promotion_service.dart';

enum PromotionGoal {
  videoViews,
  profileViews,
  followers,
  messages,
  website,
  conversions,
}

enum AudienceMode { auto, custom }

enum BudgetMode { daily, total }

enum PaymentMethod { wallet, card }

class PromotePostModal extends StatefulWidget {
  final int confessionId;
  final VoidCallback? onPromoted;

  const PromotePostModal({
    super.key,
    required this.confessionId,
    this.onPromoted,
  });

  static Future<void> show(
    BuildContext context, {
    required int confessionId,
    VoidCallback? onPromoted,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromotePostModal(
          confessionId: confessionId,
          onPromoted: onPromoted,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<PromotePostModal> createState() => _PromotePostModalState();
}

class _PromotePostModalState extends State<PromotePostModal>
    with SingleTickerProviderStateMixin {
  final ConfessionService _confessionService = ConfessionService();
  final PromotionService _promotionService = PromotionService();
  final Map<String, Future<Uint8List?>> _videoThumbCache = {};
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final List<String> _websiteCtaOptions = const [
    'Consulter le site',
    'Acheter maintenant',
    'Inscription',
    'Contacte-nous',
    'Postuler maintenant',
    'Réserver maintenant',
    'Faire un don',
    'Télécharger',
    'Heure de la demande',
    'Voir le menu',
    'Regarder plus',
    'Appeler',
    'Appel à l\'action',
    'En savoir plus',
  ];
  String? _selectedWebsiteCta;

  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _currentStep = 0;
  bool _isLoadingVideos = false;
  bool _isPromoting = false;
  bool _isLoadingBalance = false;

  List<Confession> _myVideos = [];
  final List<Confession> _selectedVideos = [];

  PromotionGoal? _selectedGoal;
  AudienceMode _audienceMode = AudienceMode.auto;
  BudgetMode _budgetMode = BudgetMode.daily;
  PaymentMethod _paymentMethod = PaymentMethod.wallet;

  String _selectedGender = 'Tous';
  String _selectedAgeRange = '18-24';
  String _selectedDevice = 'Tous';
  final List<String> _selectedInterests = [];

  int _durationDays = 3;
  double _dailyBudget = 1500;
  double _totalBudget = 4500;
  bool _brandedContent = false;
  double _walletBalance = 0;

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  final NumberFormat _compact = NumberFormat.compact(locale: 'fr_FR');

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _syncBudgetText();
    _loadMyVideos();
    _loadBalance();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    _languageController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadMyVideos() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    setState(() => _isLoadingVideos = true);
    try {
      final result = await _confessionService.getUserConfessionsByUsername(
        user.username,
      );
      final videos = result.confessions
          .where((c) => c.hasVideo && c.isPublic && c.isApproved)
          .toList();
      final preselected = videos.firstWhere(
        (c) => c.id == widget.confessionId,
        orElse: () => videos.isNotEmpty
            ? videos.first
            : Confession(
                id: widget.confessionId,
                authorId: user.id,
                content: '',
                createdAt: DateTime.now(),
              ),
      );
      setState(() {
        _myVideos = videos;
        if (preselected.hasVideo) {
          _selectedVideos.add(preselected);
        }
        _isLoadingVideos = false;
      });
    } catch (_) {
      setState(() => _isLoadingVideos = false);
    }
  }

  Future<void> _loadBalance() async {
    setState(() => _isLoadingBalance = true);
    try {
      final response = await _promotionService.getPromotionBalance();
      final data = response['data'] ?? {};
      setState(() {
        _walletBalance = _parseAmount(data['wallet_balance']);
        _isLoadingBalance = false;
      });
    } catch (_) {
      setState(() => _isLoadingBalance = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
      _animationController.reverse().then((_) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
        setState(() => _currentStep++);
        _animationController.forward();
      });
    } else {
      _launchPromotion();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reverse().then((_) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
        setState(() => _currentStep--);
        _animationController.forward();
      });
    } else {
      Navigator.pop(context);
    }
  }

  bool _canContinue() {
    switch (_currentStep) {
      case 0:
        return _selectedVideos.isNotEmpty;
      case 1:
        return _selectedGoal != null;
      case 2:
        return _audienceMode == AudienceMode.auto ||
            _selectedInterests.isNotEmpty ||
            _locationController.text.trim().isNotEmpty;
      case 3:
        return _durationDays >= 1 && _computedTotalBudget() >= 1000;
      case 4:
        if (_selectedGoal == PromotionGoal.website &&
            _websiteController.text.trim().isEmpty) {
          return false;
        }
        if (_selectedGoal == PromotionGoal.website &&
            (_selectedWebsiteCta == null || _selectedWebsiteCta!.trim().isEmpty)) {
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  Future<void> _launchPromotion() async {
    if (_selectedVideos.isEmpty) return;
    setState(() => _isPromoting = true);
    try {
      final durationHours = _durationDays * 24;
      final estimates = _estimateMetrics();
      final locations = _locationController.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      final payload = <String, dynamic>{
        'goal': _goalKey(_selectedGoal),
        'audience_mode': _audienceMode == AudienceMode.auto ? 'auto' : 'custom',
        'gender': _selectedGender,
        'age_range': _selectedAgeRange,
        'locations': locations.isNotEmpty ? locations : null,
        'interests': _selectedInterests,
        'language': _languageController.text.trim().isEmpty
            ? null
            : _languageController.text.trim(),
        'device_type': _selectedDevice,
        'budget_mode': _budgetMode == BudgetMode.daily ? 'daily' : 'total',
        'daily_budget': _budgetMode == BudgetMode.daily ? _dailyBudget : null,
        'total_budget': _budgetMode == BudgetMode.total
            ? _totalBudget
            : _computedTotalBudget(),
        'duration_days': _durationDays,
        'cta_label': _ctaLabel(),
        'website_url': _selectedGoal == PromotionGoal.website
            ? _websiteController.text.trim()
            : null,
        'branded_content': _brandedContent,
        'payment_method': _paymentMethod == PaymentMethod.card
            ? 'card'
            : 'wallet',
        'estimated_views': estimates['views'],
        'estimated_reach': estimates['reach'],
        'estimated_cpv': estimates['cpv'],
        'confession_ids': _selectedVideos
            .map((confession) => confession.id)
            .toList(),
      };
      await _promotionService.promotePost(
        _selectedVideos.first.id,
        durationHours,
        data: payload,
      );
      widget.onPromoted?.call();
      if (mounted) {
        Navigator.pop(context);
        Helpers.showSuccessSnackBar(context, 'Boost lancé avec succès.');
      }
    } catch (e) {
      setState(() => _isPromoting = false);
      if (mounted) {
        Helpers.showErrorSnackBar(context, 'Erreur: ${e.toString()}');
      }
    }
  }

  double _computedDailyBudget() {
    if (_budgetMode == BudgetMode.daily) return _dailyBudget;
    return _durationDays == 0 ? 0.0 : (_totalBudget / _durationDays);
  }

  double _computedTotalBudget() {
    if (_budgetMode == BudgetMode.total) return _totalBudget;
    return _dailyBudget * _durationDays;
  }

  void _syncBudgetText() {
    final amount = _budgetMode == BudgetMode.daily
        ? _dailyBudget
        : _totalBudget;
    _budgetController.text = amount.toStringAsFixed(0);
  }

  Map<String, double> _estimateMetrics() {
    final budget = _computedTotalBudget();
    final audienceFactor = _audienceMode == AudienceMode.auto ? 1.1 : 0.9;
    final goalFactor = _selectedGoal == PromotionGoal.followers ? 0.8 : 1.0;
    final views = budget * 3.2 * audienceFactor * goalFactor;
    final reach = views * 0.7;
    final cpv = budget == 0 ? 0.0 : budget / views;
    return {'views': views, 'reach': reach, 'cpv': cpv};
  }

  String _ctaLabel() {
    switch (_selectedGoal) {
      case PromotionGoal.profileViews:
        return 'Voir le profil';
      case PromotionGoal.followers:
        return 'Suivre';
      case PromotionGoal.messages:
        return 'Envoyer un message';
      case PromotionGoal.website:
        return _selectedWebsiteCta ?? 'Consulter le site';
      case PromotionGoal.conversions:
        return 'Acheter';
      case PromotionGoal.videoViews:
      default:
        return 'Voir plus';
    }
  }

  Widget _buildVideoThumb(String url) {
    final future = _videoThumbCache.putIfAbsent(
      url,
      () => VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
        maxWidth: 512,
      ),
    );
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(
          color: Colors.black12,
          child: const Center(
            child: Icon(Icons.videocam, color: Colors.white70),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
        title: const Text('Booster une publication'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSelectVideoPage(),
                _buildObjectivePage(),
                _buildAudiencePage(),
                _buildBudgetPage(),
                _buildSummaryPage(),
              ],
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isActive ? AppColors.primaryGradient : null,
                color: isActive ? null : Colors.grey.withOpacity(0.2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectVideoPage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sélectionnez vos vidéos à booster',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Choisissez jusqu\'à 5 vidéos publiques pour faire un A/B testing.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (_isLoadingVideos)
              const Center(child: CircularProgressIndicator())
            else if (_myVideos.isEmpty)
              const Text('Aucune vidéo publique disponible.')
            else
              Expanded(
                child: GridView.builder(
                  itemCount: _myVideos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.7,
                  ),
                  itemBuilder: (context, index) {
                    final confession = _myVideos[index];
                    final videoUrl = resolveMediaUrl(confession.videoUrl);
                    final isSelected = _selectedVideos.any(
                      (c) => c.id == confession.id,
                    );
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedVideos.removeWhere(
                              (c) => c.id == confession.id,
                            );
                          } else {
                            if (_selectedVideos.length >= 5) {
                              Helpers.showSnackBar(context, 'Maximum 5 vidéos.');
                              return;
                            }
                            _selectedVideos.add(confession);
                          }
                        });
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildVideoThumb(videoUrl),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white70,
                              ),
                              child: Icon(
                                isSelected ? Icons.check : Icons.add,
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectivePage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final objectives = [
      _objectiveTile(
        PromotionGoal.videoViews,
        'Plus de vues vidéo',
        Icons.play_circle,
      ),
      _objectiveTile(
        PromotionGoal.profileViews,
        'Plus de vues sur le profil',
        Icons.person,
      ),
      _objectiveTile(PromotionGoal.followers, 'Plus d\'abonnés', Icons.people),
      _objectiveTile(
        PromotionGoal.messages,
        'Plus de messages directs',
        Icons.message,
      ),
      _objectiveTile(
        PromotionGoal.website,
        'Plus de visites sur un site',
        Icons.language,
      ),
      _objectiveTile(
        PromotionGoal.conversions,
        'Plus de conversions',
        Icons.shopping_cart,
      ),
    ];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Choisissez l\'objectif de la campagne',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'On adapte automatiquement le CTA à l\'objectif.',
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ...objectives,
        ],
      ),
    );
  }

  Widget _objectiveTile(PromotionGoal goal, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedGoal == goal;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoal = goal;
          if (goal == PromotionGoal.website) {
            _selectedWebsiteCta ??= _websiteCtaOptions.first;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildAudiencePage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Définissez votre audience',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'L\'audience automatique est recommandée pour de meilleurs résultats.',
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _audienceModeButton(
                  label: 'Automatique',
                  selected: _audienceMode == AudienceMode.auto,
                  onTap: () =>
                      setState(() => _audienceMode = AudienceMode.auto),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _audienceModeButton(
                  label: 'Personnalisée',
                  selected: _audienceMode == AudienceMode.custom,
                  onTap: () =>
                      setState(() => _audienceMode = AudienceMode.custom),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_audienceMode == AudienceMode.custom) ...[
            _buildDropdown(
              label: 'Genre',
              value: _selectedGender,
              items: const ['Tous', 'Homme', 'Femme'],
              onChanged: (value) => setState(() => _selectedGender = value),
            ),
            _buildDropdown(
              label: 'Tranche d\'âge',
              value: _selectedAgeRange,
              items: const ['18-24', '25-34', '35-44', '45-54', '55+'],
              onChanged: (value) => setState(() => _selectedAgeRange = value),
            ),
            _buildTextField(
              controller: _locationController,
              label: 'Localisation',
              hint: 'Pays, région, ville',
            ),
            _buildInterestChips(),
            _buildTextField(
              controller: _languageController,
              label: 'Langue',
              hint: 'Ex: français',
            ),
            _buildDropdown(
              label: 'Type d\'appareil',
              value: _selectedDevice,
              items: const ['Tous', 'Android', 'iOS'],
              onChanged: (value) => setState(() => _selectedDevice = value),
            ),
          ],
          const SizedBox(height: 16),
          _buildEstimateCard(),
        ],
      ),
    );
  }

  Widget _audienceModeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final estimates = _estimateMetrics();
    final daily = _computedDailyBudget();
    final total = _computedTotalBudget();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Budget et durée',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Définissez le budget et la durée de votre campagne (1 à 7 jours).',
            style: TextStyle(
              color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _budgetModeButton(
                  label: 'Budget / jour',
                  selected: _budgetMode == BudgetMode.daily,
                  onTap: () => setState(() {
                    _budgetMode = BudgetMode.daily;
                    _syncBudgetText();
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _budgetModeButton(
                  label: 'Budget total',
                  selected: _budgetMode == BudgetMode.total,
                  onTap: () => setState(() {
                    _budgetMode = BudgetMode.total;
                    _syncBudgetText();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Montant',
              prefixIcon: const Icon(Icons.payments),
              prefixText: 'FCFA ',
              prefixStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
              final amount = double.tryParse(normalized) ?? 0;
              setState(() {
                if (_budgetMode == BudgetMode.daily) {
                  _dailyBudget = amount;
                } else {
                  _totalBudget = amount;
                }
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Durée: $_durationDays jours',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _durationDays.toDouble(),
            min: 1,
            max: 7,
            divisions: 6,
            onChanged: (value) => setState(() => _durationDays = value.toInt()),
          ),
          const SizedBox(height: 16),
          _buildEstimateCard(
            views: estimates['views'],
            reach: estimates['reach'],
            cpv: estimates['cpv'],
          ),
        ],
      ),
    );
  }

  Widget _budgetModeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final estimates = _estimateMetrics();
    final totalBudget = _computedTotalBudget();
    final selectedPreview = _selectedVideos.isNotEmpty
        ? _selectedVideos.first
        : null;
    final previewUrl = resolveMediaUrl(selectedPreview?.videoUrl);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Récapitulatif',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (selectedPreview != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(height: 200, child: _buildVideoThumb(previewUrl)),
            ),
          const SizedBox(height: 16),
          _summaryRow('Objectif', _goalLabel(_selectedGoal)),
          _summaryRow(
            'Audience',
            _audienceMode == AudienceMode.auto
                ? 'Automatique'
                : 'Personnalisée',
          ),
          _summaryRow('Durée', '$_durationDays jours'),
          _summaryRow('Budget total', _currency.format(totalBudget)),
          _summaryRow('CTA', _ctaLabel()),
          const SizedBox(height: 12),
          _buildEstimateCard(
            views: estimates['views'],
            reach: estimates['reach'],
            cpv: estimates['cpv'],
          ),
          const SizedBox(height: 12),
          const Text(
            'Aperçu dans le feed',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildAdPreviewCard(previewUrl),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _brandedContent,
            onChanged: (value) => setState(() => _brandedContent = value),
            title: const Text('Contenu de marque'),
            subtitle: const Text('Obligatoire si contenu sponsorisé'),
          ),
          if (_selectedGoal == PromotionGoal.website)
            DropdownButtonFormField<String>(
              value: _selectedWebsiteCta ?? _websiteCtaOptions.first,
              decoration: const InputDecoration(
                labelText: 'Texte du bouton',
                border: OutlineInputBorder(),
              ),
              items: _websiteCtaOptions
                  .map(
                    (option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _selectedWebsiteCta = value;
              }),
            ),
          if (_selectedGoal == PromotionGoal.website)
            const SizedBox(height: 12),
          if (_selectedGoal == PromotionGoal.website)
            TextField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Lien du site web',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Paiement',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildBalanceCard(),
          const SizedBox(height: 12),
          _paymentTile(
            label: 'Portefeuille',
            selected: _paymentMethod == PaymentMethod.wallet,
            onTap: () => setState(() => _paymentMethod = PaymentMethod.wallet),
          ),
          _paymentTile(
            label: 'Carte bancaire',
            selected: _paymentMethod == PaymentMethod.card,
            onTap: () => setState(() => _paymentMethod = PaymentMethod.card),
          ),
        ],
      ),
    );
  }

  Widget _buildAdPreviewCard(String previewUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctaLabel = _ctaLabel();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: _buildVideoThumb(previewUrl),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Sponsorisé',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (ctaLabel.isNotEmpty)
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(ctaLabel),
                ),
            ],
          ),
          if (_selectedGoal == PromotionGoal.website &&
              _websiteController.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _websiteController.text.trim(),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: _isLoadingBalance
                ? const Text('Chargement du solde...')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Solde portefeuille: ${_currency.format(_walletBalance)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Portefeuille: ${_currency.format(_walletBalance)}',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
          TextButton(
            onPressed: () => context.push('/wallet'),
            child: const Text('Portefeuille'),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateCard({double? views, double? reach, double? cpv}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metrics = _estimateMetrics();
    final viewsValue = views ?? metrics['views'] ?? 0;
    final reachValue = reach ?? metrics['reach'] ?? 0;
    final cpvValue = cpv ?? metrics['cpv'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.dividerDark
              : AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _metricTile('Vues estimées', _compact.format(viewsValue)),
          _metricTile('Reach estimé', _compact.format(reachValue)),
          _metricTile('CPV estimé', _currency.format(cpvValue)),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
          labelStyle: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          labelStyle: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          onChanged(value);
        },
      ),
    );
  }

  Widget _buildInterestChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const interestOptions = [
      'Musique',
      'Sport',
      'Beauté',
      'Gaming',
      'Cuisine',
      'Business',
      'Voyage',
      'Tech',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: interestOptions.map((interest) {
          final selected = _selectedInterests.contains(interest);
          return FilterChip(
            selected: selected,
            label: Text(interest),
            labelStyle: TextStyle(
              color: isDark
                  ? (selected ? Colors.white : AppColors.textPrimaryDark)
                  : (selected ? Colors.white : AppColors.textPrimary),
              fontWeight: FontWeight.w600,
            ),
            selectedColor: AppColors.primary,
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            onSelected: (value) {
              setState(() {
                if (value) {
                  _selectedInterests.add(interest);
                } else {
                  _selectedInterests.remove(interest);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _canContinue() && !_isPromoting ? _nextStep : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isPromoting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_currentStep == 4 ? 'Payer et lancer' : 'Continuer'),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _paymentTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(label),
    );
  }

  // Solde promo = portefeuille (recharge via écran portefeuille)

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _goalLabel(PromotionGoal? goal) {
    switch (goal) {
      case PromotionGoal.videoViews:
        return 'Vues vidéo';
      case PromotionGoal.profileViews:
        return 'Vues profil';
      case PromotionGoal.followers:
        return 'Abonnés';
      case PromotionGoal.messages:
        return 'Messages';
      case PromotionGoal.website:
        return 'Visites site';
      case PromotionGoal.conversions:
        return 'Conversions';
      default:
        return '-';
    }
  }

  String? _goalKey(PromotionGoal? goal) {
    switch (goal) {
      case PromotionGoal.videoViews:
        return 'video_views';
      case PromotionGoal.profileViews:
        return 'profile_views';
      case PromotionGoal.followers:
        return 'followers';
      case PromotionGoal.messages:
        return 'messages';
      case PromotionGoal.website:
        return 'website';
      case PromotionGoal.conversions:
        return 'conversions';
      default:
        return null;
    }
  }
}
