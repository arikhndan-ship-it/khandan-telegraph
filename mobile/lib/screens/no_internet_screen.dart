import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../app/theme.dart';
import 'package:khandan_app/l10n/app_localizations.dart';

class NoInternetScreen extends StatefulWidget {
  final VoidCallback? onConnected;
  final WidgetBuilder? appBuilder;

  const NoInternetScreen({
    super.key,
    this.onConnected,
    this.appBuilder,
  });

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen> {
  bool _checking = false;

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _retry() async {
    setState(() => _checking = true);
    final connected = await _hasInternet();
    if (!mounted) return;

    if (connected) {
      widget.onConnected?.call();
    } else {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Wifi off icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      color: AppTheme.primaryColor,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    l10n.noInternetTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Serif',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    l10n.noInternetDesc,
                    textAlign: isRtl ? TextAlign.right : TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textGray,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Retry button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _checking ? null : _retry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                      ),
                      child: _checking
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.refresh, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.retryConnection,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Language toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LangButton(
                          label: 'English',
                          isSelected: Localizations.localeOf(context).languageCode == 'en',
                          onTap: () => _changeLocale(const Locale('en')),
                        ),
                        const SizedBox(width: 12),
                        _LangButton(
                          label: 'کوردی',
                          isSelected: Localizations.localeOf(context).languageCode == 'ckb',
                          onTap: () => _changeLocale(const Locale('ckb')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _changeLocale(Locale locale) {
    // We need to rebuild the MaterialApp with new locale
    // The parent KhandanApp will handle this
    KhandanAppState? appState;
    try {
      appState = KhandanApp.of(context);
    } catch (_) {}
    if (appState != null) {
      appState.setLocale(locale);
    }
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
