import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/l10n_ext.dart';
import 'app_update_controller.dart';
import 'app_update_service.dart';

class AppUpdateGate extends ConsumerStatefulWidget {
  const AppUpdateGate({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate>
    with WidgetsBindingObserver {
  DateTime? _lastCheck;
  bool _openingStore = false;
  String? _dismissedUpdate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_check);
  }

  Future<void> _check() async {
    if (!mounted) return;
    _lastCheck = DateTime.now();
    await ref.read(appUpdateProvider.notifier).check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final required =
        ref.read(appUpdateProvider).valueOrNull?.isRequired == true;
    if (required ||
        _lastCheck == null ||
        DateTime.now().difference(_lastCheck!) > const Duration(minutes: 1)) {
      _check();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _openStore(AppUpdate update) async {
    if (_openingStore) return;
    setState(() => _openingStore = true);
    var opened = false;
    try {
      opened = await launchUrl(update.storeUrl,
          mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!mounted) return;
    setState(() => _openingStore = false);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.updateStoreOpenFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(appUpdateProvider);
    if (status.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final update = status.valueOrNull;
    final l10n = context.l10n;
    if (update == null || !update.isRequired) {
      // Keep the router in the same tree position when a notice is dismissed.
      return Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (update != null && _dismissedUpdate != update.identity)
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                child: Card(
                  margin: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: Text(
                                      update.title ?? l10n.updateAvailableTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium)),
                              IconButton(
                                tooltip: l10n.updateLater,
                                onPressed: () => setState(
                                    () => _dismissedUpdate = update.identity),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(update.message ?? l10n.updateAvailableBody),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            children: [
                              TextButton(
                                onPressed: () => setState(
                                    () => _dismissedUpdate = update.identity),
                                child: Text(l10n.updateLater),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 44)),
                                onPressed: _openingStore
                                    ? null
                                    : () => _openStore(update),
                                child: Text(update.platform == 'ios'
                                    ? l10n.updateInAppStore
                                    : l10n.updateInGooglePlay),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(height: 44),
                    const SizedBox(height: 40),
                    const Icon(Icons.system_update_rounded,
                        size: 64, color: AppColors.primary),
                    const SizedBox(height: 24),
                    Text(update.title ?? l10n.updateRequiredTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    Text(update.message ?? l10n.updateRequiredBody,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed:
                          _openingStore ? null : () => _openStore(update),
                      child: Text(update.platform == 'ios'
                          ? l10n.updateInAppStore
                          : l10n.updateInGooglePlay),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                        onPressed: _check, child: Text(l10n.updateCheckAgain)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
