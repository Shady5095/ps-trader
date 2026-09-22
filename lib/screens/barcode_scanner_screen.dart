import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/localization/app_locale.dart';
import '../core/localization/app_strings.dart';
import '../theme/app_theme.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _animationController;
  bool _isDetected = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isDetected) return;
    for (final barcode in capture.barcodes) {
      final val = barcode.rawValue?.trim();
      if (val != null && val.isNotEmpty) {
        _isDetected = true;
        Navigator.pop(context, val);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaWidth = size.width * 0.82;
    final scanAreaHeight = size.height * 0.28;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        title: Text(
          AppStrings.scanBarcode.tr(context),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? AppColors.gold : Colors.white70,
            ),
            tooltip: 'Flash',
            onPressed: () async {
              await _controller.toggleTorch();
              if (mounted) {
                setState(() {
                  _isTorchOn = !_isTorchOn;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_outlined, color: Colors.white70),
            tooltip: 'Switch Camera',
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off_outlined,
                          size: 54, color: AppColors.danger),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.cameraPermissionRequired.tr(context),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _controller.start(),
                        child: Text(AppStrings.retry.tr(context)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Custom Scanner Overlay with laser line
          CustomPaint(
            painter: _ScannerOverlayPainter(
              scanAreaWidth: scanAreaWidth,
              scanAreaHeight: scanAreaHeight,
            ),
          ),

          // Animated Scan Laser Line
          Center(
            child: SizedBox(
              width: scanAreaWidth,
              height: scanAreaHeight,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(0, (_animationController.value * 2) - 1),
                    child: Container(
                      height: 2.5,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.1),
                            AppColors.primary,
                            AppColors.accent,
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.8),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom Instruction Text
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner, color: AppColors.accent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.pointCameraAtBarcode.tr(context),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double scanAreaWidth;
  final double scanAreaHeight;

  _ScannerOverlayPainter({
    required this.scanAreaWidth,
    required this.scanAreaHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final left = (size.width - scanAreaWidth) / 2;
    final top = (size.height - scanAreaHeight) / 2;
    final rect = Rect.fromLTWH(left, top, scanAreaWidth, scanAreaHeight);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));

    // Darkened surrounding mask
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect);
    backgroundPath.fillType = PathFillType.evenOdd;
    canvas.drawPath(backgroundPath, backgroundPaint);

    // Rounded rectangle border around scan area
    canvas.drawRRect(rrect, borderPaint);

    // Corner highlights
    final cornerPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const cornerLength = 26.0;

    // Top-left
    canvas.drawLine(Offset(left + 18, top), Offset(left + 18 + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top + 18), Offset(left, top + 18 + cornerLength), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(left + scanAreaWidth - 18, top), Offset(left + scanAreaWidth - 18 - cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaWidth, top + 18), Offset(left + scanAreaWidth, top + 18 + cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(left + 18, top + scanAreaHeight), Offset(left + 18 + cornerLength, top + scanAreaHeight), cornerPaint);
    canvas.drawLine(Offset(left, top + scanAreaHeight - 18), Offset(left, top + scanAreaHeight - 18 - cornerLength), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(left + scanAreaWidth - 18, top + scanAreaHeight), Offset(left + scanAreaWidth - 18 - cornerLength, top + scanAreaHeight), cornerPaint);
    canvas.drawLine(Offset(left + scanAreaWidth, top + scanAreaHeight - 18), Offset(left + scanAreaWidth, top + scanAreaHeight - 18 - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
