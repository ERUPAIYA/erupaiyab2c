// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/app_colors.dart';
import '../../../config/app_env.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/k_dialog.dart';
import '../repositories/receipt_repository.dart';
import '../services/receipt_file_service.dart';
import '../utils/receipt_html_renderer.dart';
import '../views/receipt_html_viewer_screen.dart';
import '../views/receipt_viewer_screen.dart';

void _debugLog(String message) {
  if (!AppEnv.enableLogs || !kDebugMode) return;
  debugPrint(message);
}

enum ReceiptAction { share, download }

class ReceiptActions {
  ReceiptActions._();

  static String resolveReceiptTransactionId({
    required String refId,
    required String txnId,
  }) {
    if (refId.trim().isNotEmpty) return refId.trim();
    return txnId.trim();
  }

  static Future<void> handleReceiptAction(
    BuildContext context, {
    required String transactionId,
    required ReceiptAction action,
  }) async {
    if (transactionId.trim().isEmpty) {
      AppSnackbar.show('Missing transaction id.');
      return;
    }

    BuildContext? dialogContext;
    try {
      dialogContext = navigatorKey.currentContext;
      if (dialogContext != null) {
        showDialog(
          context: dialogContext,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: SpinKitCircle(
              color: AppColors.primary,
              size: 48,
            ),
          ),
        );
      }

      if (Platform.isAndroid) {
        _debugLog('[Receipt] Android flow start: $transactionId');
        final html = await _fetchReceiptHtml(transactionId);
        _debugLog('[Receipt] HTML fetched (${html.length} chars)');
        if (action == ReceiptAction.share) {
          _hideLoading(dialogContext);
          _debugLog('[Receipt] Converting HTML to PDF for sharing');
          File pdfFile;
          try {
            pdfFile = await ReceiptFileService.buildPdfFileFromHtmlViaWebView(
              html: html,
              transactionId: transactionId,
            );
          } catch (e) {
            _debugLog('[Receipt] Native WebView PDF failed: $e');
            final shareResult = await _buildSharePdfBytes(html);
            final pdfBytes = shareResult.bytes;
            if (shareResult.usedFallback) {
              AppSnackbar.show(
                'Using a basic receipt because full rendering is unavailable.',
              );
            }
            pdfFile = await ReceiptFileService.savePdfToTemp(
              pdfBytes: pdfBytes,
              transactionId: transactionId,
            );
          }
          _debugLog('[Receipt] PDF saved: ${pdfFile.path}');
          await Share.shareXFiles(
            [
              XFile(
                pdfFile.path,
                mimeType: 'application/pdf',
                name: 'receipt_$transactionId.pdf',
              ),
            ],
            text: 'Payment Receipt',
          );
          _debugLog('[Receipt] Share sheet invoked');
        } else {
          final pdfBytes = await ReceiptFileService.buildPdfBytesFromHtml(html);
          _debugLog('[Receipt] PDF bytes generated (${pdfBytes.length} bytes)');
          final file = await ReceiptFileService.savePdfToDownloads(
            pdfBytes: pdfBytes,
            transactionId: transactionId,
          );
          _hideLoading(dialogContext);
          if (!context.mounted) return;
          await _showDownloadSuccessDialog(
            context,
            transactionId: transactionId,
            file: file,
            onOpen: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReceiptViewerScreen(
                    pdfBytes: pdfBytes,
                    transactionId: transactionId,
                  ),
                ),
              );
            },
          );
        }
        return;
      }

      _debugLog('[Receipt] Non-Android flow start: $transactionId');
      final pdfBytes = await _fetchReceiptPdfBytes(transactionId);
      _debugLog('[Receipt] PDF bytes generated (${pdfBytes.length} bytes)');
      if (action == ReceiptAction.share) {
        _hideLoading(dialogContext);
        final pdfFile = await ReceiptFileService.savePdfToTemp(
          pdfBytes: pdfBytes,
          transactionId: transactionId,
        );
        _debugLog('[Receipt] PDF saved: ${pdfFile.path}');
        await Share.shareXFiles(
          [
            XFile(
              pdfFile.path,
              mimeType: 'application/pdf',
              name: 'receipt_$transactionId.pdf',
            ),
          ],
          text: 'Payment Receipt',
        );
        _debugLog('[Receipt] Share sheet invoked');
      } else {
        final file = await _saveReceiptPdf(
          bytes: pdfBytes,
          transactionId: transactionId,
        );
        _hideLoading(dialogContext);
        if (!context.mounted) return;
        await _showDownloadSuccessDialog(
          context,
          transactionId: transactionId,
          file: file,
          onOpen: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReceiptViewerScreen(
                  pdfBytes: pdfBytes,
                  transactionId: transactionId,
                ),
              ),
            );
          },
        );
      }
    } catch (e, t) {
      _debugLog('Receipt generation error: $e');
      _debugLog(t.toString());
      _hideLoading(dialogContext);
      AppSnackbar.show(e.toString());
    }
  }

  static Future<void> openReceiptViewer(
    BuildContext context, {
    required String transactionId,
  }) async {
    if (transactionId.trim().isEmpty) {
      AppSnackbar.show('Missing transaction id.');
      return;
    }

    BuildContext? dialogContext;
    try {
      dialogContext = navigatorKey.currentContext;
      if (dialogContext != null) {
        showDialog(
          context: dialogContext,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: SpinKitCircle(
              color: AppColors.primary,
              size: 48,
            ),
          ),
        );
      }

      if (Platform.isAndroid) {
        final html = await _fetchReceiptHtml(transactionId);
        _hideLoading(dialogContext);
        if (!context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReceiptHtmlViewerScreen(
              html: html,
              transactionId: transactionId,
            ),
          ),
        );
        return;
      }

      final pdfBytes = await _fetchReceiptPdfBytes(transactionId);
      _hideLoading(dialogContext);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReceiptViewerScreen(
            pdfBytes: pdfBytes,
            transactionId: transactionId,
          ),
        ),
      );
    } catch (e, t) {
      _debugLog('Receipt view error: $e');
      _debugLog(t.toString());
      _hideLoading(dialogContext);
      AppSnackbar.show(e.toString());
    }
  }

  static const Duration _shareRenderTimeout = Duration(seconds: 15);

  static Future<_SharePdfResult> _buildSharePdfBytes(String html) async {
    var usedFallback = false;
    final startedAt = DateTime.now();
    _debugLog('[Receipt] Share render start');
    try {
      final renderFuture = ReceiptFileService.buildPdfBytesFromHtml(html);
      final fallbackFuture = Future<Uint8List>.delayed(
        _shareRenderTimeout,
        () async {
          usedFallback = true;
          _debugLog(
            '[Receipt] Share render timed out after ${_shareRenderTimeout.inSeconds}s, using fallback',
          );
          return ReceiptFileService.buildSimplePdfFromHtml(html);
        },
      );
      final bytes = await Future.any<Uint8List>([
        renderFuture,
        fallbackFuture,
      ]);
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      _debugLog(
        '[Receipt] Share render completed in ${elapsedMs}ms (fallback=$usedFallback, bytes=${bytes.length})',
      );
      return _SharePdfResult(bytes: bytes, usedFallback: usedFallback);
    } catch (e) {
      final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
      _debugLog('[Receipt] Share render failed after ${elapsedMs}ms: $e');
      final bytes = await ReceiptFileService.buildSimplePdfFromHtml(html);
      return _SharePdfResult(bytes: bytes, usedFallback: true);
    }
  }

  static Future<Uint8List> _fetchReceiptPdfBytes(String transactionId) async {
    final repo = ReceiptRepository();
    final html = await repo.fetchReceiptHtml(transactionId: transactionId);
    if (html.trim().isEmpty) {
      throw Exception('Empty receipt content.');
    }
    return ReceiptHtmlRenderer.toPdfBytes(html);
  }

  static Future<String> _fetchReceiptHtml(String transactionId) async {
    final repo = ReceiptRepository();
    final html = await repo.fetchReceiptHtml(transactionId: transactionId);
    if (html.trim().isEmpty) {
      throw Exception('Empty receipt content.');
    }
    return html;
  }

  static Future<File> _saveReceiptPdf({
    required List<int> bytes,
    required String transactionId,
  }) async {
    return ReceiptFileService.savePdfToDownloads(
      pdfBytes: Uint8List.fromList(bytes),
      transactionId: transactionId,
    );
  }

  static void _hideLoading(BuildContext? dialogContext) {
    if (dialogContext == null) return;
    if (Navigator.of(dialogContext).canPop()) {
      Navigator.of(dialogContext).pop();
    }
  }

  static Future<void> _showDownloadSuccessDialog(
    BuildContext context, {
    required String transactionId,
    required File file,
    required Future<void> Function() onOpen,
  }) async {
    final savedToDownloads = file.path.contains('/Download/');
    final locationLabel = savedToDownloads
        ? 'Downloads'
        : (Platform.isIOS ? 'Files' : 'device storage');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text('Receipt Downloaded'),
          content: Text(
            'Your receipt has been saved to $locationLabel. You can open it now.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await onOpen();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open'),
            ),
          ],
        );
      },
    );
    _debugLog('[Receipt] Saved file path: ${file.path} for $transactionId');
  }
}

class _SharePdfResult {
  const _SharePdfResult({required this.bytes, required this.usedFallback});

  final Uint8List bytes;
  final bool usedFallback;
}
