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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
