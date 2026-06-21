import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isFlashOn = false;
  final TextEditingController _manualInputController = TextEditingController();
  bool _showManualInput = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        _scannerController.stop();
        _navigateToAsset(code);
      }
    }
  }

  void _navigateToAsset(String code) {
    // Navigate to asset profile with the scanned ID
    context.pushReplacement('/asset/$code');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Scanner Code QR / NFC',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () {
              _scannerController.toggleTorch();
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _scannerController.facing == CameraFacing.front
                  ? Icons.camera_rear
                  : Icons.camera_front,
              color: Colors.white,
            ),
            onPressed: () {
              _scannerController.switchCamera();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Camera Viewport
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Container(
                    padding: EdgeInsets.all(24),
                    margin: EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: context.colors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_off,
                            color: context.colors.danger, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Caméra non disponible',
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Utilisez la saisie manuelle ci-dessous ou configurez les permissions de la caméra.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                context.colors.textSecondary.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Viewfinder Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: context.colors.accentPrimary, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Corner indicators
                  _buildViewfinderCorner(Alignment.topLeft),
                  _buildViewfinderCorner(Alignment.topRight),
                  _buildViewfinderCorner(Alignment.bottomLeft),
                  _buildViewfinderCorner(Alignment.bottomRight),
                ],
              ),
            ),
          ),

          // 3. Instruction Text & NFC simulation
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Alignez le code QR dans le cadre',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),

          // 4. Bottom panel containing NFC Indicator & Manual input fallback
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: context.colors.backgroundSecondary.withValues(alpha: 0.95),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: context.colors.border, width: 1.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // NFC Simulation area
                  InkWell(
                    onTap: () {
                      // Simulate NFC Tap
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Simulation NFC : Badge détecté (ASSET-001)'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      _navigateToAsset('ASSET-001');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contactless,
                              color: context.colors.accentSecondary, size: 28),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Approchez un badge NFC',
                                style: TextStyle(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Ou appuyez ici pour simuler',
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Saisie manuelle toggle
                  if (!_showManualInput)
                    SizedBox(
                      height: 48,
                      child: TextButton.icon(
                        icon: Icon(Icons.keyboard,
                            color: context.colors.accentPrimary),
                        label: Text(
                          'Saisir le code manuellement',
                          style: TextStyle(
                            color: context.colors.accentPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _showManualInput = true;
                          });
                        },
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _manualInputController,
                                autofocus: true,
                                style: TextStyle(
                                    color: context.colors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Ex: ASSET-001, horse_01...',
                                  hintStyle: TextStyle(
                                      color: context.colors.textMuted),
                                  filled: true,
                                  fillColor: context.colors.surface,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: context.colors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: context.colors.accentPrimary),
                                  ),
                                ),
                                onSubmitted: (val) {
                                  if (val.trim().isNotEmpty) {
                                    _navigateToAsset(val.trim());
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: 12),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.colors.accentPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  final text =
                                      _manualInputController.text.trim();
                                  if (text.isNotEmpty) {
                                    _navigateToAsset(text);
                                  }
                                },
                                child: Icon(Icons.arrow_forward),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showManualInput = false;
                            });
                          },
                          child: Text(
                            'Annuler la saisie manuelle',
                            style: TextStyle(
                                color: context.colors.textSecondary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinderCorner(Alignment alignment) {
    return Positioned(
      child: Align(
        alignment: alignment,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              top: alignment == Alignment.topLeft ||
                      alignment == Alignment.topRight
                  ? BorderSide(color: context.colors.accentPrimary, width: 4)
                  : BorderSide.none,
              bottom: alignment == Alignment.bottomLeft ||
                      alignment == Alignment.bottomRight
                  ? BorderSide(color: context.colors.accentPrimary, width: 4)
                  : BorderSide.none,
              left: alignment == Alignment.topLeft ||
                      alignment == Alignment.bottomLeft
                  ? BorderSide(color: context.colors.accentPrimary, width: 4)
                  : BorderSide.none,
              right: alignment == Alignment.topRight ||
                      alignment == Alignment.bottomRight
                  ? BorderSide(color: context.colors.accentPrimary, width: 4)
                  : BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
