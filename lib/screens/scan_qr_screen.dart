import 'package:authenticator/const/colors.dart';
import 'package:authenticator/const/styles.dart';
import 'package:authenticator/screens/add_manually_screen.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

/// Full-screen QR code scanner used to add a 2FA account by scanning an
/// `otpauth://` URI. On a successful scan the parsed values are forwarded to
/// [AddManuallyScreen] for review before saving.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? _controller;
  bool _handled = false;

  void _onViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((scanData) {
      final raw = scanData.code;
      if (_handled || raw == null || raw.isEmpty) return;
      final parsed = _parseOtpAuth(raw);
      if (parsed != null) {
        _handled = true;
        controller.pauseCamera();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => AddManuallyScreen(
              initialService: parsed.issuer,
              initialAccount: parsed.account,
              initialSecret: parsed.secret,
            ),
          ),
        );
      }
    });
  }

  /// Parses an `otpauth://totp/Issuer:account?secret=...&issuer=...` URI.
  _OtpData? _parseOtpAuth(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme.toLowerCase() != 'otpauth') return null;

    final secret = uri.queryParameters['secret'];
    if (secret == null || secret.isEmpty) return null;

    // Label is the path, e.g. "/GitHub:alice@dev.io".
    final label = Uri.decodeComponent(
      uri.path.startsWith('/') ? uri.path.substring(1) : uri.path,
    );

    String? issuer = uri.queryParameters['issuer'];
    String account = label;
    if (label.contains(':')) {
      final parts = label.split(':');
      issuer ??= parts.first.trim();
      account = parts.sublist(1).join(':').trim();
    }

    return _OtpData(
      issuer: issuer?.trim(),
      account: account.trim(),
      secret: secret.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cutOut = MediaQuery.of(context).size.width * 0.7;
    return Scaffold(
      backgroundColor: AppColors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        title: Text(
          'Scan QR Code',
          style: AppTextStyles.h2.copyWith(color: AppColors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _controller?.toggleFlash(),
            icon: const Icon(Icons.flash_on),
          ),
          IconButton(
            onPressed: () => _controller?.flipCamera(),
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          QRView(
            key: _qrKey,
            onQRViewCreated: _onViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: AppColors.white,
              borderRadius: 24,
              borderLength: 32,
              borderWidth: 6,
              cutOutSize: cutOut,
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 60,
            child: Text(
              'Point your camera at the QR code shown by the service.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpData {
  final String? issuer;
  final String account;
  final String secret;

  const _OtpData({
    required this.issuer,
    required this.account,
    required this.secret,
  });
}
