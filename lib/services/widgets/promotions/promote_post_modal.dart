import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../promotion_service.dart';

enum PromotionObjective {
  boostAccount,
  getSales,
  getProspects,
}

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
  final PromotionService _promotionService = PromotionService();
  final currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _currentStep = 0;
  PromotionObjective? _selectedObjective;
  String? _selectedSubObjective;
  int? _selectedPackIndex;
  bool _acceptTerms = false;
  bool _isLoading = false;
  bool _isPromoting = false;

  List<Map<String, dynamic>> _pricingOptions = [];

  // Objectifs et sous-objectifs
  final Map<PromotionObjective, Map<String, dynamic>> _objectives = {
    PromotionObjective.boostAccount: {
      'title': 'Booster mon compte',
      'icon': Icons.trending_up,
      'color': Colors.blue,
      'description': 'Augmentez votre visibilité et gagnez des abonnés',
      'subObjectives': [
        {'id': 'followers', 'label': 'Gagner des abonnés', 'icon': Icons.people},
        {'id': 'visibility', 'label': 'Plus de visibilité', 'icon': Icons.visibility},
        {'id': 'engagement', 'label': 'Plus d\'engagement', 'icon': Icons.favorite},
      ],
    },
    PromotionObjective.getSales: {
      'title': 'Obtenir des ventes',
      'icon': Icons.shopping_cart,
      'color': Colors.green,
      'description': 'Convertissez vos visiteurs en clients',
      'subObjectives': [
        {'id': 'products', 'label': 'Vendre des produits', 'icon': Icons.inventory_2},
        {'id': 'services', 'label': 'Vendre des services', 'icon': Icons.design_services},
        {'id': 'events', 'label': 'Promouvoir un événement', 'icon': Icons.event},
      ],
    },
    PromotionObjective.getProspects: {
      'title': 'Obtenir des prospects',
      'icon': Icons.contact_mail,
      'color': Colors.orange,
      'description': 'Générez des leads qualifiés pour votre activité',
      'subObjectives': [
        {'id': 'contacts', 'label': 'Collecter des contacts', 'icon': Icons.contacts},
        {'id': 'messages', 'label': 'Recevoir des messages', 'icon': Icons.message},
        {'id': 'website', 'label': 'Visites sur mon site', 'icon': Icons.language},
      ],
    },
  };

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
    _loadPricing();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPricing() async {
    setState(() => _isLoading = true);
    try {
      final pricing = await _promotionService.getPricing();
      setState(() {
        _pricingOptions = pricing;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _animationController.reverse().then((_) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
        setState(() => _currentStep++);
        _animationController.forward();
      });
    } else {
      _promotePost();
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
        return _selectedObjective != null;
      case 1:
        return _selectedSubObjective != null;
      case 2:
        return _selectedPackIndex != null;
      case 3:
        return _acceptTerms;
      default:
        return false;
    }
  }

  Future<void> _promotePost() async {
    if (_selectedPackIndex == null || !_acceptTerms) return;

    setState(() => _isPromoting = true);

    try {
      final selectedPack = _pricingOptions[_selectedPackIndex!];
      final result = await _promotionService.promotePost(
        widget.confessionId,
        selectedPack['duration_hours'],
      );

      if (result['success'] == true) {
        widget.onPromoted?.call();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Publication promue avec succès!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Erreur');
      }
    } catch (e) {
      setState(() => _isPromoting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        ),
        title: Text(_getStepTitle()),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildObjectiveSelectionPage(),
                _buildSubObjectivePage(),
                _buildPackSelectionPage(),
                _buildConfirmationPage(),
              ],
            ),
          ),

          // Bottom action button
          _buildBottomButton(),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Choisissez votre objectif';
      case 1:
        return 'Précisez votre objectif';
      case 2:
        return 'Choisissez votre pack';
      case 3:
        return 'Confirmation';
      default:
        return 'Promouvoir';
    }
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isActive
                          ? AppColors.primary
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isActive ? AppColors.primaryGradient : null,
                    color: isActive ? null : Colors.grey.withOpacity(0.3),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: index < _currentStep
                          ? AppColors.primary
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildObjectiveSelectionPage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quel est votre objectif ?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez l\'objectif principal de votre promotion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ..._objectives.entries.map((entry) {
              final objective = entry.key;
              final data = entry.value;
              final isSelected = _selectedObjective == objective;

              return GestureDetector(
                onTap: () => setState(() => _selectedObjective = objective),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (data['color'] as Color).withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? data['color'] as Color
                          : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (data['color'] as Color).withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: (data['color'] as Color).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          data['icon'] as IconData,
                          color: data['color'] as Color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['description'] as String,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: data['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubObjectivePage() {
    if (_selectedObjective == null) {
      return const Center(child: Text('Veuillez d\'abord sélectionner un objectif'));
    }

    final data = _objectives[_selectedObjective]!;
    final subObjectives = data['subObjectives'] as List<Map<String, dynamic>>;
    final color = data['color'] as Color;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Précisez votre objectif',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez ce que vous souhaitez accomplir',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ...subObjectives.map((subObj) {
              final isSelected = _selectedSubObjective == subObj['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedSubObjective = subObj['id']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        subObj['icon'] as IconData,
                        color: isSelected ? color : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          subObj['label'] as String,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: color),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPackSelectionPage() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisissez votre pack',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez la durée et le budget de votre promotion',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ..._pricingOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final pack = entry.value;
              final isSelected = _selectedPackIndex == index;
              final isPopular = index == 1; // Le deuxième pack est populaire

              return GestureDetector(
                onTap: () => setState(() => _selectedPackIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.1),
                              AppColors.secondary.withOpacity(0.1),
                            ],
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  pack['label'] ?? '${pack['duration_hours']}h',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  currencyFormat.format(pack['price']),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: isSelected ? AppColors.primary : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildPackFeature(
                                  Icons.trending_up,
                                  '+${pack['reach_boost']}% portée',
                                ),
                                const SizedBox(width: 16),
                                _buildPackFeature(
                                  Icons.schedule,
                                  '${pack['duration_hours']}h de boost',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildPackFeature(
                                  Icons.people_outline,
                                  'Non-abonnés inclus',
                                ),
                                const SizedBox(width: 16),
                                _buildPackFeature(
                                  Icons.insights,
                                  'Stats détaillées',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isPopular)
                        Positioned(
                          top: 0,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'POPULAIRE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (isSelected)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPackFeature(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationPage() {
    final selectedPack = _selectedPackIndex != null
        ? _pricingOptions[_selectedPackIndex!]
        : null;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Récapitulatif',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Summary card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Objectif',
                    _selectedObjective != null
                        ? _objectives[_selectedObjective]!['title'] as String
                        : '-',
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Pack',
                    selectedPack?['label'] ?? '-',
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Durée',
                    selectedPack != null
                        ? '${selectedPack['duration_hours']} heures'
                        : '-',
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Boost portée',
                    selectedPack != null
                        ? '+${selectedPack['reach_boost']}%'
                        : '-',
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    'Total',
                    selectedPack != null
                        ? currencyFormat.format(selectedPack['price'])
                        : '-',
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Legal section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Informations importantes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Le boost démarrera immédiatement après le paiement\n'
                    '• La durée du boost est garantie\n'
                    '• Les statistiques seront disponibles en temps réel\n'
                    '• Aucun remboursement possible après activation',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange[900],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Terms acceptance
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _acceptTerms,
                  onChanged: (value) {
                    setState(() => _acceptTerms = value ?? false);
                  },
                  activeColor: AppColors.primary,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            const TextSpan(
                              text: 'J\'accepte les ',
                            ),
                            TextSpan(
                              text: 'conditions générales de promotion',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(
                              text: ' et je confirme que ma publication respecte les ',
                            ),
                            TextSpan(
                              text: 'règles de la communauté',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.black : AppColors.textSecondary,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 20 : 14,
            color: isTotal ? AppColors.primary : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final selectedPack = _selectedPackIndex != null && _currentStep >= 2
        ? _pricingOptions[_selectedPackIndex!]
        : null;

    String buttonText;
    if (_currentStep == 3) {
      buttonText = _isPromoting
          ? 'Traitement...'
          : selectedPack != null
              ? 'Payer ${currencyFormat.format(selectedPack['price'])}'
              : 'Payer';
    } else {
      buttonText = 'Continuer';
    }

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
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
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: _canContinue() && !_isPromoting ? AppColors.primaryGradient : null,
          color: _canContinue() && !_isPromoting ? null : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          boxShadow: _canContinue() && !_isPromoting
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
            onTap: _canContinue() && !_isPromoting ? _nextStep : null,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: _isPromoting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          buttonText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _canContinue() ? Colors.white : Colors.grey,
                          ),
                        ),
                        if (_currentStep < 3) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: 20,
                            color: _canContinue() ? Colors.white : Colors.grey,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
