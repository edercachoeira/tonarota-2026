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

  // Dimensões da área do visualizador (container)
  static const double _viewerHeight = 300.0;

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
      // Dimensões originais da imagem em pixels
      final int imgW = _decodedImage!.width;
      final int imgH = _decodedImage!.height;

      // Obtém o tamanho real do container no viewport (largura real, não fixa)
      // Usaremos _viewerWidth calculada a partir do container
      final RenderBox? viewerBox = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
      if (viewerBox == null) {
        throw Exception('Erro de layout: container do viewer não encontrado.');
      }
      final double viewerWidth = viewerBox.size.width;
      final double viewerHeight = viewerBox.size.height;

      // Escala base: como a imagem se encaixa no container (BoxFit.contain implícito)
      final double scaleX = viewerWidth / imgW;
      final double scaleY = viewerHeight / imgH;
      final double baseScale = scaleX < scaleY ? scaleX : scaleY;

      // Tamanho da imagem como renderizada (antes do InteractiveViewer zoom)
      final double renderedW = imgW * baseScale;
      final double renderedH = imgH * baseScale;

      // Offset da imagem dentro do container (centralização)
      final double offsetX = (viewerWidth - renderedW) / 2.0;
      final double offsetY = (viewerHeight - renderedH) / 2.0;

      // Dimensões do crop frame no viewport
      final double cropW = _getCropWidth(viewerWidth);
      final double cropH = cropW / widget.aspectRatio;

      // Posição do crop frame no container (centralizado)
      final double cropLeft = (viewerWidth - cropW) / 2.0;
      final double cropTop = (viewerHeight - cropH) / 2.0;

      // Transformação do InteractiveViewer
      final matrix = _transformController.value;
      final double ivScale = matrix.storage[0]; // zoom do InteractiveViewer
      final double ivTx = matrix.storage[12];   // translação X
      final double ivTy = matrix.storage[13];   // translação Y

      // Escala total (base * zoom do InteractiveViewer)
      final double totalScale = baseScale * ivScale;

      // A posição da imagem no viewport, considerando o offset de centralização,
      // a translação e a escala do InteractiveViewer.
      // O InteractiveViewer aplica escala e translação sobre o child que inclui
      // o offset de centralização.
      //
      // Posição do pixel (0,0) da imagem original no viewport:
      //   viewportX = (offsetX + 0 * baseScale) * ivScale + ivTx
      //   viewportX = offsetX * ivScale + ivTx
      //
      // Para mapear o crop frame de volta para coordenadas da imagem original:
      //   cropLeft = offsetX * ivScale + ivTx + srcX * totalScale
      //   srcX = (cropLeft - offsetX * ivScale - ivTx) / totalScale

      final double srcX = (cropLeft - offsetX * ivScale - ivTx) / totalScale;
      final double srcY = (cropTop - offsetY * ivScale - ivTy) / totalScale;
      final double srcW = cropW / totalScale;
      final double srcH = cropH / totalScale;

      // Clamp ao tamanho da imagem para evitar erros
      final double clampedX = srcX.clamp(0, imgW.toDouble());
      final double clampedY = srcY.clamp(0, imgH.toDouble());
      final double clampedW = srcW.clamp(0, imgW.toDouble() - clampedX);
      final double clampedH = srcH.clamp(0, imgH.toDouble() - clampedY);

      // Renderiza o corte no canvas do Flutter
      const double targetWidth = 1280.0;
      final double targetHeight = targetWidth / widget.aspectRatio;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      final srcRect = Rect.fromLTWH(clampedX, clampedY, clampedW, clampedH);
      final dstRect = Rect.fromLTWH(0, 0, targetWidth, targetHeight);

      canvas.drawImageRect(
        _decodedImage!,
        srcRect,
        dstRect,
        Paint()..filterQuality = ui.FilterQuality.high,
      );

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(targetWidth.toInt(), targetHeight.toInt());

      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Falha ao exportar bytes da imagem cortada.');
      }

      final croppedBytes = byteData.buffer.asUint8List();

      // Upload dos bytes brutos para o backend
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

  // Calcula a largura do crop frame com base na largura do container
  double _getCropWidth(double containerWidth) {
    // O crop frame ocupa no máximo 90% da largura do container, até 320px
    return (containerWidth * 0.85).clamp(100, 320);
  }

  final GlobalKey _viewerKey = GlobalKey();

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
              key: _viewerKey,
              height: _viewerHeight,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double containerW = constraints.maxWidth;
                    final double containerH = constraints.maxHeight;
                    final double cropW = _getCropWidth(containerW);
                    final double cropH = cropW / widget.aspectRatio;

                    return Stack(
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
                            minScale: 0.5,
                            boundaryMargin: const EdgeInsets.all(200),
                            child: Center(
                              child: Image.memory(
                                _imageBytes!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          // Overlay de Máscara Escura e Frame de Recorte
                          IgnorePointer(
                            child: CustomPaint(
                              size: Size(containerW, containerH),
                              painter: CropOverlayPainter(
                                cropWidth: cropW,
                                cropHeight: cropH,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),

            if (_decodedImage != null) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '💡 Dica: Arraste para mover a imagem e use scroll/pinça para redimensionar.',
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

    // Borda do crop frame
    final borderPaint = Paint()
      ..color = AppTheme.primaryTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(cropRect, borderPaint);

    // Cantos destacados do crop frame
    const double cornerLen = 20.0;
    const double cornerWidth = 3.0;
    final cornerPaint = Paint()
      ..color = AppTheme.primaryTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(left, top), Offset(left + cornerLen, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLen), cornerPaint);
    // Top-right
    canvas.drawLine(Offset(left + cropWidth, top), Offset(left + cropWidth - cornerLen, top), cornerPaint);
    canvas.drawLine(Offset(left + cropWidth, top), Offset(left + cropWidth, top + cornerLen), cornerPaint);
    // Bottom-left
    canvas.drawLine(Offset(left, top + cropHeight), Offset(left + cornerLen, top + cropHeight), cornerPaint);
    canvas.drawLine(Offset(left, top + cropHeight), Offset(left, top + cropHeight - cornerLen), cornerPaint);
    // Bottom-right
    canvas.drawLine(Offset(left + cropWidth, top + cropHeight), Offset(left + cropWidth - cornerLen, top + cropHeight), cornerPaint);
    canvas.drawLine(Offset(left + cropWidth, top + cropHeight), Offset(left + cropWidth, top + cropHeight - cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
