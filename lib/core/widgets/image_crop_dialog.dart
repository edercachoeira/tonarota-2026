import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class ImageCropDialog extends StatefulWidget {
  final String title;
  final double aspectRatio; // e.g. 16 / 9
  final Function(String imageUrl) onUploadSuccess;

  const ImageCropDialog({
    super.key,
    this.title = 'Cortar Imagem',
    this.aspectRatio = 16 / 9,
    required this.onUploadSuccess,
  });

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  Uint8List? _imageBytes;
  ui.Image? _decodedImage;
  bool _isDecoding = false;
  bool _isUploading = false;
  String? _errorMessage;

  final TransformationController _transformController = TransformationController();
  final GlobalKey _cropFrameKey = GlobalKey();
  final GlobalKey _imageKey = GlobalKey();

  // Dimensões do Crop Frame no viewport
  final double _cropWidth = 320.0;
  late final double _cropHeight = _cropWidth / widget.aspectRatio;

  void _pickImage() {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        setState(() {
          _isDecoding = true;
          _errorMessage = null;
          _imageBytes = null;
          _decodedImage = null;
        });

        final file = files[0];
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          final bytes = reader.result as Uint8List;
          _decodeImage(bytes);
        });
      }
    });
  }

  Future<void> _decodeImage(Uint8List bytes) async {
    try {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image img) {
        completer.complete(img);
      });
      final decoded = await completer.future;

      setState(() {
        _imageBytes = bytes;
        _decodedImage = decoded;
        _isDecoding = false;
        _transformController.value = Matrix4.identity();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao decodificar a imagem selecionada.';
        _isDecoding = false;
      });
    }
  }

  Future<void> _cropAndUpload() async {
    if (_decodedImage == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // 1. Obtém a matriz de transformação do InteractiveViewer (storage é column-major)
      final matrix = _transformController.value;
      final double scale = matrix.storage[0];  // Escala (Sx) em row 0, col 0
      final double tx = matrix.storage[12];    // Translação X (Tx) em row 0, col 3
      final double ty = matrix.storage[13];    // Translação Y (Ty) em row 1, col 3

      // 2. Calcula as posições dos componentes na tela
      final RenderBox? imageBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? frameBox = _cropFrameKey.currentContext?.findRenderObject() as RenderBox?;

      if (imageBox == null || frameBox == null) {
        throw Exception('Erro de layout ao calcular posições do corte.');
      }

      // Localiza a posição do frame de corte e da imagem na tela global
      final frameOffset = frameBox.localToGlobal(Offset.zero);
      final imageOffset = imageBox.localToGlobal(Offset.zero);

      // Distância relativa do topo esquerdo do frame até o topo esquerdo da imagem
      final double relativeLeft = frameOffset.dx - imageOffset.dx;
      final double relativeTop = frameOffset.dy - imageOffset.dy;

      // 3. Mapeia esses pontos de volta à escala original da imagem
      // Como o imageOffset retornado pelo localToGlobal já contém as translações (tx/ty),
      // a distância relativa na tela dividida pela escala dá a coordenada local exata no frame original.
      final double srcX = relativeLeft / scale;
      final double srcY = relativeTop / scale;
      final double srcW = _cropWidth / scale;
      final double srcH = _cropHeight / scale;

      // 4. Executa o corte renderizando no canvas do Flutter
      final recorder = ui.PictureRecorder();
      // Resolução desejada da imagem final recortada (ex: 1280x720 para qualidade HD)
      const double targetWidth = 1280.0;
      final double targetHeight = targetWidth / widget.aspectRatio;

      final canvas = ui.Canvas(recorder);

      final srcRect = Rect.fromLTWH(srcX, srcY, srcW, srcH);
      final dstRect = Rect.fromLTWH(0, 0, targetWidth, targetHeight);

      // Desenha a fatia recortada no canvas
      canvas.drawImageRect(_decodedImage!, srcRect, dstRect, Paint()..filterQuality = ui.FilterQuality.high);

      // Finaliza a gravação e converte em imagem física
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(targetWidth.toInt(), targetHeight.toInt());
      
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Falha ao exportar bytes da imagem cortada.');
      }

      final croppedBytes = byteData.buffer.asUint8List();

      // 5. Faz o upload dos bytes brutos para o backend
      final uri = Uri.parse('http://localhost:8080/api/v1/upload');
      final response = await http.post(
        uri,
        headers: {
          'content-type': 'image/png',
          'accept': 'application/json',
        },
        body: croppedBytes,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final String uploadedUrl = data['url'] as String;
        
        widget.onUploadSuccess(uploadedUrl);
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception('Servidor retornou código de erro: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao recortar ou enviar a imagem: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryTextColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isUploading ? null : () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 20),

            // Área do Visualizador / Corte
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_decodedImage == null && !_isDecoding) ...[
                      // Tela Inicial sem arquivo
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: AppTheme.primaryTeal.withOpacity(0.8),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Selecione uma imagem de alta resolução',
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _pickImage,
                            child: const Text('Escolher Arquivo'),
                          )
                        ],
                      )
                    ] else if (_isDecoding) ...[
                      // Processamento/Carregamento
                      const CircularProgressIndicator()
                    ] else ...[
                      // Visualizador interativo de Imagem
                      InteractiveViewer(
                        transformationController: _transformController,
                        maxScale: 5.0,
                        minScale: 0.1,
                        boundaryMargin: const EdgeInsets.all(100),
                        child: Center(
                          key: _imageKey,
                          child: Image.memory(_imageBytes!),
                        ),
                      ),
                      // Overlay de Máscara Escura e Frame de Recorte
                      IgnorePointer(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: CropOverlayPainter(
                            cropWidth: _cropWidth,
                            cropHeight: _cropHeight,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      // Frame Delimitador (para cálculo de tamanho e offset)
                      Positioned(
                        width: _cropWidth,
                        height: _cropHeight,
                        child: IgnorePointer(
                          child: Container(
                            key: _cropFrameKey,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primaryTeal, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (_decodedImage != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '💡 Dica: Arraste com um dedo para mover a imagem e use a pinça para redimensionar.',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11),
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_decodedImage != null) ...[
                  OutlinedButton(
                    onPressed: _isUploading ? null : _pickImage,
                    child: const Text('Mudar Imagem'),
                  ),
                  const SizedBox(width: 12),
                ],
                ElevatedButton(
                  onPressed: _decodedImage == null || _isUploading ? null : _cropAndUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Confirmar & Enviar'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Pintor da Máscara Escura com recorte transparente no centro
class CropOverlayPainter extends CustomPainter {
  final double cropWidth;
  final double cropHeight;
  final bool isDark;

  CropOverlayPainter({
    required this.cropWidth,
    required this.cropHeight,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    // Retângulo do frame centralizado
    final double left = (size.width - cropWidth) / 2;
    final double top = (size.height - cropHeight) / 2;
    final cropRect = Rect.fromLTWH(left, top, cropWidth, cropHeight);

    // Desenha máscara preenchendo toda a tela, exceto a região de crop
    canvas.drawPath(
      Path.combine(
        ui.PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRect(cropRect),
      ),
      backgroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
