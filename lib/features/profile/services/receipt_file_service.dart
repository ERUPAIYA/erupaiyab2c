import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptFileService {
  ReceiptFileService._();

  static const MethodChannel _receiptPrintChannel =
      MethodChannel('com.innoplix.erupaiya/receipt_print');
  static const Duration _androidTimeout = Duration(seconds: 45);
  static const Duration _defaultTimeout = Duration(seconds: 20);
  static const String _receiptMetaAndStyle = '''
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0" />
<style>
  @page { size: A4; margin: 12mm; }
  * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  html, body { margin: 0; padding: 0; font-size: 16px; -webkit-text-size-adjust: 100%; }
  body { width: 100%; box-sizing: border-box; }
  img, table, pre, code, .container { max-width: 100% !important; height: auto !important; }
  table { width: 100% !important; }
  @media print {
    html, body { font-size: 16px; }
    body { width: 100%; }
    img, table, pre, code, .container { max-width: 100% !important; }
  }
</style>
''';

  static String normalizeHtml(String html) {
    final headMatch =
        RegExp(r'<head[^>]*>', caseSensitive: false).firstMatch(html);
    if (headMatch != null) {
      return html.replaceRange(
        headMatch.end,
        headMatch.end,
        _receiptMetaAndStyle,
      );
    }
    if (RegExp(r'<html[^>]*>', caseSensitive: false).hasMatch(html)) {
      return html.replaceFirstMapped(
        RegExp(r'<html[^>]*>', caseSensitive: false),
        (match) => '${match.group(0)}<head>$_receiptMetaAndStyle</head>',
      );
    }
    return '<!doctype html><html><head>$_receiptMetaAndStyle</head>'
        '<body>$html</body></html>';
  }

  static Future<Uint8List> buildPdfBytesFromHtml(String html) async {
    final normalizedHtml = normalizeHtml(html);
    final preparedHtml = await _inlineAssetImages(normalizedHtml);
    final timeout = Platform.isAndroid ? _androidTimeout : _defaultTimeout;
    Future<Uint8List> attempt() {
      if (kDebugMode) {
        debugPrint(
          'Receipt HTML->PDF attempt (timeout ${timeout.inSeconds}s, html=${preparedHtml.length} chars)',
        );
      }
      return Printing.convertHtml(html: preparedHtml).timeout(
        timeout,
        onTimeout: () {
          throw Exception(
            'Receipt rendering timed out. Please update Android System WebView and try again.',
          );
        },
      );
    }

    try {
      return await attempt();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'Receipt HTML->PDF failed (attempt 1): $e\n$stackTrace',
        );
      }
      if (!Platform.isAndroid) rethrow;
      await Future.delayed(const Duration(milliseconds: 400));
      try {
        return await attempt();
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            'Receipt HTML->PDF failed (attempt 2): $e\n$stackTrace',
          );
        }
        return _buildFallbackPdf(html);
      }
    }
  }

  static Future<Uint8List> buildSimplePdfFromHtml(String html) async {
    return _buildFallbackPdf(html);
  }

  static Future<File> buildPdfFileFromHtmlViaWebView({
    required String html,
    required String transactionId,
  }) async {
    if (!Platform.isAndroid) {
      final bytes = await buildPdfBytesFromHtml(html);
      return savePdfToTemp(pdfBytes: bytes, transactionId: transactionId);
    }
    final normalizedHtml = normalizeHtml(html);
    final fileName = 'receipt_$transactionId.pdf';
    final path = await _receiptPrintChannel.invokeMethod<String>(
      'printHtmlToPdf',
      {
        'html': normalizedHtml,
        'fileName': fileName,
      },
    );
    if (path == null || path.isEmpty) {
      throw Exception('Failed to generate receipt PDF from WebView.');
    }
    return File(path);
  }

  static Future<String> _inlineAssetImages(String html) async {
    final assetRegex = RegExp("src=([\"'])(assets/[^\"']+)\\\\1");
    final matches = assetRegex.allMatches(html).toList();
    if (matches.isEmpty) return html;

    var updated = html;
    final seen = <String>{};
    for (final match in matches) {
      final assetPath = match.group(2);
      if (assetPath == null || assetPath.isEmpty) continue;
      if (seen.contains(assetPath)) continue;
      seen.add(assetPath);
      try {
        final data = await rootBundle.load(assetPath);
        final bytes = data.buffer.asUint8List();
        final mime = _mimeForAsset(assetPath);
        final base64Data = base64Encode(bytes);
        final dataUri = 'data:$mime;base64,$base64Data';
        updated = updated
            .replaceAll('src="$assetPath"', 'src="$dataUri"')
            .replaceAll("src='$assetPath'", "src='$dataUri'");
      } catch (_) {
        // Keep original src if asset can't be loaded.
      }
    }
    return updated;
  }

  static String _mimeForAsset(String assetPath) {
    final lower = assetPath.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  static Future<Uint8List> _buildFallbackPdf(String html) async {
    final txId = _asciiSafe(_extractValue(html, 'Transaction ID') ?? 'N/A');
    final amount = _asciiSafe(_extractValue(html, 'Amount') ?? 'N/A');
    final status = _asciiSafe(_extractValue(html, 'Status') ?? 'N/A');
    final date = _asciiSafe(_extractValue(html, 'Date') ?? 'N/A');
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Payment Receipt',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              _row('Transaction ID', txId),
              _divider(),
              _row('Amount', amount),
              _divider(),
              _row('Status', status),
              _divider(),
              _row('Date', date),
              _divider(),
              pw.SizedBox(height: 18),
            ],
          );
        },
      ),
    );
    return await doc.save();
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _divider() {
    return pw.Container(
      height: 1,
      color: PdfColors.grey300,
    );
  }

  static String? _extractValue(String html, String label) {
    final pattern = RegExp(
      '<span>\\s*${RegExp.escape(label)}\\s*</span>\\s*<span>(.*?)</span>',
      caseSensitive: false,
      dotAll: true,
    );
    final match = pattern.firstMatch(html);
    if (match == null) return null;
    return match.group(1)?.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  static String _asciiSafe(String value) {
    var out = value;
    out = out.replaceAll('—', '-');
    out = out.replaceAll('–', '-');
    out = out.replaceAll('₹', 'Rs ');
    out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
    return out;
  }

  static Future<File> savePdfToDownloads({
    required Uint8List pdfBytes,
    required String transactionId,
  }) async {
    final fileName = 'receipt_$transactionId.pdf';

    if (Platform.isAndroid) {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      try {
        if (await downloadsDir.exists()) {
          final file = File('${downloadsDir.path}/$fileName');
          return await file.writeAsBytes(pdfBytes, flush: true);
        }
      } catch (_) {
        // Fall through to app-accessible storage.
      }

      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final file = File('${externalDir.path}/$fileName');
        return await file.writeAsBytes(pdfBytes, flush: true);
      }
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    return file.writeAsBytes(pdfBytes, flush: true);
  }

  static Future<File> receiptCacheFile(String transactionId) async {
    final dir = await getTemporaryDirectory();
    final receiptsDir = Directory('${dir.path}/receipts');
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }
    return File('${receiptsDir.path}/receipt_$transactionId.pdf');
  }

  static Future<File?> getCachedReceipt(String transactionId) async {
    final file = await receiptCacheFile(transactionId);
    if (await file.exists() && await file.length() > 0) {
      return file;
    }
    return null;
  }

  static Future<File> savePdfToCache({
    required Uint8List pdfBytes,
    required String transactionId,
  }) async {
    final file = await receiptCacheFile(transactionId);
    return file.writeAsBytes(pdfBytes, flush: true);
  }

  static Future<File> savePdfToTemp({
    required Uint8List pdfBytes,
    required String transactionId,
  }) async {
    return savePdfToCache(
      pdfBytes: pdfBytes,
      transactionId: transactionId,
    );
  }

  static Future<File> savePngFromPdfBytes({
    required Uint8List pdfBytes,
    required String transactionId,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/receipt_$transactionId.png');
    final raster = await Printing.raster(pdfBytes, pages: const [0]).first;
    final pngBytes = await raster.toPng();
    return file.writeAsBytes(pngBytes, flush: true);
  }

  static Future<File> saveHtmlToTemp({
    required String html,
    required String transactionId,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/receipt_$transactionId.html');
    return file.writeAsString(html, flush: true);
  }
}
