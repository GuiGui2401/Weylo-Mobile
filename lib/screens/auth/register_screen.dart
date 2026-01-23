import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../services/widgets/common/custom_text_field.dart';
import '../../services/widgets/common/custom_button.dart';
import '../../services/widgets/common/loading_overlay.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  final _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentPage = 0;

  // Controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _phoneFullNumber = '';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_formKeys[_currentPage].currentState!.validate()) {
      if (_currentPage < 3) {
        _animationController.reverse().then((_) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          );
          setState(() => _currentPage++);
          _animationController.forward();
        });
      } else {
        _handleRegister();
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _animationController.reverse().then((_) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
        setState(() => _currentPage--);
        _animationController.forward();
      });
    } else {
      context.pop();
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKeys[3].currentState!.validate()) return;

    if (!_acceptTerms) {
      Helpers.showErrorSnackBar(
        context,
        AppLocalizations.of(context)!.acceptTermsError,
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      // The user request did not mention first name and last name.
      // I will use the username as a fallback for the first name.
      firstName: _usernameController.text.trim(),
      lastName: null,
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneFullNumber,
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    if (success && mounted) {
      // Auto-login: go directly to home
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final l10n = AppLocalizations.of(context)!;
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  // Custom App Bar with back button and progress
                  _buildAppBar(),

                  // Progress indicator
                  _buildProgressIndicator(),

                  // Error message
                  if (authProvider.error != null)
                    _buildErrorMessage(authProvider.error!),

                  // Pages
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildUsernamePage(),
                        _buildPhonePage(),
                        _buildEmailPage(),
                        _buildSecurityPage(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _previousPage,
          ),
          Expanded(
            child: Text(
              _getPageTitle(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  String _getPageTitle() {
    final l10n = AppLocalizations.of(context)!;
    switch (_currentPage) {
      case 0:
        return "Nom d'utilisateur";
      case 1:
        return "Numéro de téléphone";
      case 2:
        return "Adresse e-mail";
      case 3:
        return l10n.registerSecurityTitle;
      default:
        return l10n.registerTitle;
    }
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == 3 ? 0 : 4,
                  ),
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: index <= _currentPage
                        ? AppColors.primaryGradient
                        : null,
                    color: index <= _currentPage
                        ? null
                        : AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(
              context,
            )!.registerStepLabel(_currentPage + 1, 4),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernamePage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKeys[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Container(
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Center(
                    child: Image.asset(
                      'assets/logo.jpg',
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                Text(
                  "Choisissez votre nom d'utilisateur",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Votre nom d'utilisateur est unique.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                CustomTextField(
                  controller: _usernameController,
                  label: AppLocalizations.of(context)!.usernameLabelRequired,
                  hintText: AppLocalizations.of(context)!.usernameHint,
                  prefixIcon: Icons.alternate_email,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _nextPage(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.usernameRequired;
                    }
                    if (!Helpers.isValidUsername(value)) {
                      return AppLocalizations.of(context)!.usernameInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: AppLocalizations.of(context)!.continueAction,
                  onPressed: _nextPage,
                  suffixIcon: Icons.arrow_forward,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhonePage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKeys[1],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Illustration/Icon
                Container(
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_iphone,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                Text(
                  "Votre numéro de téléphone",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Nous vous enverrons un code de vérification.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                IntlPhoneField(
                  controller: _phoneController,
                  initialCountryCode: 'auto',
                  disableLengthCheck: true,
                  flagsButtonPadding: const EdgeInsets.only(left: 16),
                  dropdownIconPosition: IconPosition.trailing,
                  dropdownIcon: const Icon(Icons.arrow_drop_down),
                  decoration: InputDecoration(
                    hintText: "Numéro de Téléphone",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                      ),
                    ),
                    counterText: '',
                  ),

                  onChanged: (phone) {
                    _phoneFullNumber = phone.completeNumber;
                  },
                  onSubmitted: (_) => _nextPage(),
                  validator: (phone) {
                    if (phone == null || phone.number.isEmpty) {
                      return "Le numéro de téléphone est requis";
                    }
                    final digits = phone.completeNumber.replaceAll(
                      RegExp(r'[\\s\\-\\+]'),
                      '',
                    );
                    if (digits.length < 7 || digits.length > 15) {
                      return AppLocalizations.of(context)!.phoneInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: AppLocalizations.of(context)!.continueAction,
                  onPressed: _nextPage,
                  suffixIcon: Icons.arrow_forward,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailPage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKeys[2],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.email_outlined,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                Text(
                  "Votre adresse e-mail",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Utilisée pour la récupération de compte.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                CustomTextField(
                  controller: _emailController,
                  label: "Adresse e-mail",
                  hintText: AppLocalizations.of(context)!.emailHint,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "L'adresse e-mail est requise";
                    }
                    if (!Helpers.isValidEmail(value)) {
                      return AppLocalizations.of(context)!.emailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: AppLocalizations.of(context)!.continueAction,
                  onPressed: _nextPage,
                  suffixIcon: Icons.arrow_forward,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityPage() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKeys[3],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 120,
                      margin: const EdgeInsets.only(bottom: 32),
                      child: Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    Text(
                      AppLocalizations.of(context)!.registerSecureTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.registerSecureSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    CustomTextField(
                      controller: _passwordController,
                      label: AppLocalizations.of(context)!.pinLabelRequired,
                      hintText: AppLocalizations.of(context)!.pinCreateHint,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.pinRequired;
                        }
                        if (value.length != 4 ||
                            !RegExp(r'^\d{4}$').hasMatch(value)) {
                          return AppLocalizations.of(context)!.pinInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: AppLocalizations.of(
                        context,
                      )!.pinConfirmLabelRequired,
                      hintText: AppLocalizations.of(context)!.pinConfirmHint,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _nextPage(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          );
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(
                            context,
                          )!.pinConfirmRequired;
                        }
                        if (value != _passwordController.text) {
                          return AppLocalizations.of(context)!.pinMismatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Terms and conditions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() => _acceptTerms = value ?? false);
                          },
                          activeColor: AppColors.secondary,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _acceptTerms = !_acceptTerms);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text: AppLocalizations.of(
                                        context,
                                      )!.acceptTermsPrefix,
                                    ),
                                    TextSpan(
                                      text: AppLocalizations.of(
                                        context,
                                      )!.acceptTermsLink,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(
                                      text: AppLocalizations.of(
                                        context,
                                      )!.acceptPrivacyMiddle,
                                    ),
                                    TextSpan(
                                      text: AppLocalizations.of(
                                        context,
                                      )!.acceptPrivacyLink,
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
                    const SizedBox(height: 32),

                    CustomButton(
                      text: AppLocalizations.of(context)!.createMyAccount,
                      onPressed: _nextPage,
                      isLoading: authProvider.isLoading,
                    ),
                    const SizedBox(height: 24),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.alreadyHaveAccount,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(AppLocalizations.of(context)!.loginLink),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
