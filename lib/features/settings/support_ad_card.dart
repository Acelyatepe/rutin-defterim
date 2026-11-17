import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/admob_config.dart';

class SupportAdCard extends StatefulWidget {
  const SupportAdCard({super.key});
  @override
  State<SupportAdCard> createState() => _SupportAdCardState();
}

class _SupportAdCardState extends State<SupportAdCard> {
  static Future<InitializationStatus>? _initialization;
  bool _busy = false;
  bool _privacyRequired = false;
  InterstitialAd? _ad;

  bool get _visible =>
      mounted &&
      ModalRoute.of(context)?.isCurrent == true &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    _refreshPrivacy();
  }

  Future<void> _refreshPrivacy() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      if (mounted) {
        setState(
          () => _privacyRequired =
              status == PrivacyOptionsRequirementStatus.required,
        );
      }
    } catch (_) {}
  }

  Future<void> _updateConsent() async {
    final result = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        if (!result.isCompleted) result.complete();
      },
      (error) {
        if (!result.isCompleted) {
          result.completeError(StateError(error.message));
        }
      },
    );
    await result.future.timeout(const Duration(seconds: 30));
    await _refreshPrivacy();
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _support() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _updateConsent();
      if (!_visible) return;
      final consent = Completer<void>();
      ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error == null) {
          consent.complete();
        } else {
          consent.completeError(StateError(error.message));
        }
      });
      await consent.future;
      await _refreshPrivacy();
      if (!await ConsentInformation.instance.canRequestAds()) {
        _message(
          'Gizlilik tercihlerin nedeniyle şu anda reklam gösterilemiyor.',
        );
        return;
      }
      if (!_visible) return;
      _initialization ??= MobileAds.instance.initialize();
      try {
        await _initialization;
      } catch (_) {
        _initialization = null;
        rethrow;
      }
      if (!_visible) return;
      final loaded = Completer<InterstitialAd?>();
      final timeout = Timer(const Duration(seconds: 30), () {
        if (!loaded.isCompleted) loaded.complete(null);
      });
      try {
        await InterstitialAd.load(
          adUnitId: Platform.isAndroid
              ? AdmobConfig.androidInterstitial
              : AdmobConfig.iosInterstitial,
          request: const AdRequest(nonPersonalizedAds: true),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              if (loaded.isCompleted || !_visible) {
                ad.dispose();
                if (!loaded.isCompleted) loaded.complete(null);
              } else {
                loaded.complete(ad);
              }
            },
            onAdFailedToLoad: (_) {
              if (!loaded.isCompleted) loaded.complete(null);
            },
          ),
        );
        final ad = await loaded.future;
        if (ad == null) {
          _message(
            'Şu anda reklam yok veya bağlantı kurulamadı. Daha sonra deneyebilirsin.',
          );
          return;
        }
        if (!_visible) {
          ad.dispose();
          return;
        }
        _ad = ad;
        final closed = Completer<void>();
        ad.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _ad = null;
            if (!closed.isCompleted) closed.complete();
          },
          onAdFailedToShowFullScreenContent: (ad, _) {
            ad.dispose();
            _ad = null;
            _message('Reklam açılamadı. Daha sonra deneyebilirsin.');
            if (!closed.isCompleted) closed.complete();
          },
        );
        await ad.show();
        await closed.future;
      } finally {
        timeout.cancel();
        if (!loaded.isCompleted) loaded.complete(null);
      }
    } catch (_) {
      _ad?.dispose();
      _ad = null;
      _message(
        'Reklam hazırlanamadı. İnternet bağlantını kontrol edip tekrar deneyebilirsin.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _privacy() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _updateConsent();
      if (!_visible) return;
      if (!_privacyRequired) {
        _message(
          'Şu anda değiştirilecek bir reklam gizlilik tercihi bulunmuyor.',
        );
        return;
      }
      final done = Completer<void>();
      ConsentForm.showPrivacyOptionsForm((error) {
        if (error == null) {
          done.complete();
        } else {
          done.completeError(StateError(error.message));
        }
      });
      await done.future;
      await _refreshPrivacy();
    } catch (_) {
      _message('Gizlilik tercihleri açılamadı. Daha sonra tekrar dene.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'İstersen bir reklam görüntüleyerek Rutin Defterim’e destek olabilirsin. Tamamen isteğe bağlıdır; uygulamanın özelliklerini etkilemez. İnternet bağlantısı gerekir.',
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: _busy ? null : _support,
            icon: const Icon(Icons.favorite_border_rounded),
            label: Text(_busy ? 'Hazırlanıyor…' : 'İsteğe bağlı reklamı aç'),
          ),
          TextButton(
            onPressed: _busy ? null : _privacy,
            child: Text(
              _privacyRequired
                  ? 'Reklam gizlilik tercihlerini değiştir'
                  : 'Reklam gizlilik tercihleri',
            ),
          ),
        ],
      ),
    ),
  );
}
