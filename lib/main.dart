import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Câmera',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CameraApp(cameras: cameras),
    );
  }
}

class CameraApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraApp({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController? controller;
  bool isFrontCamera = false;
  FlashMode currentFlashMode = FlashMode.off;
  double currentZoomLevel = 1.0;
  String? mediaPath; // Modificado para armazenar a foto ou vídeo
  bool isRecording = false; // Estado de gravação de vídeo
  Offset focusPoint = Offset(0.5, 0.5); // Ponto de foco inicial

  @override
  void initState() {
    super.initState();
    initCamera(widget.cameras[0]);
  }

  Future<void> initCamera(CameraDescription cameraDescription) async {
    controller = CameraController(cameraDescription, ResolutionPreset.high);
    try {
      await controller?.initialize();
      setState(() {});
      print('Câmera inicializada com sucesso');
    } catch (e) {
      print('Erro ao inicializar a câmera: $e');
    }
  }

  void switchCamera() async {
    isFrontCamera = !isFrontCamera;
    final selectedCamera = isFrontCamera ? widget.cameras[1] : widget.cameras[0];
    await initCamera(selectedCamera);
  }

  void toggleFlashMode() {
    setState(() {
      currentFlashMode = (currentFlashMode == FlashMode.off) ? FlashMode.torch : FlashMode.off;
      controller?.setFlashMode(currentFlashMode);
      print('Modo de flash: ${currentFlashMode.toString()}');
    });
  }

  void zoomCamera(double value) {
    setState(() {
      currentZoomLevel = value;
      controller?.setZoomLevel(currentZoomLevel);
      print('Zoom alterado para: $currentZoomLevel');
    });
  }

  Future<void> takePicture() async {
    if (controller == null || !controller!.value.isInitialized) {
      print('Controller não inicializado');
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final XFile file = await controller!.takePicture();
      await file.saveTo(filePath);
      setState(() {
        mediaPath = filePath;
      });
      print('Foto salva em: $filePath');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GalleryPage(mediaPath: filePath)),
      );
    } catch (e) {
      print('Erro ao tirar a foto: $e');
    }
  }

  Future<void> startVideoRecording() async {
    if (controller == null || !controller!.value.isInitialized) {
      print('Controller não inicializado');
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
      await controller!.startVideoRecording();
      setState(() {
        isRecording = true;
      });
      print('Gravação de vídeo iniciada');
    } catch (e) {
      print('Erro ao iniciar gravação de vídeo: $e');
    }
  }

  Future<void> stopVideoRecording() async {
    if (controller == null || !controller!.value.isInitialized || !isRecording) {
      print('Gravação não iniciada ou controller não inicializado');
      return;
    }
    try {
      final file = await controller!.stopVideoRecording();
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
      await file.saveTo(filePath);
      setState(() {
        mediaPath = filePath;
        isRecording = false;
      });
      print('Gravação de vídeo salva em: $filePath');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GalleryPage(mediaPath: filePath)),
      );
    } catch (e) {
      print('Erro ao parar gravação de vídeo: $e');
    }
  }

  void onTapFocusPoint(TapDownDetails details) {
    final offset = details.localPosition;
    setState(() {
      focusPoint = offset;
    });
    if (controller != null && controller!.value.isInitialized) {
      controller!.setFocusPoint(
        Offset(
          (focusPoint.dx / MediaQuery.of(context).size.width).clamp(0.0, 1.0),
          (focusPoint.dy / MediaQuery.of(context).size.height).clamp(0.0, 1.0),
        ),
      );
      print('Ponto de foco ajustado: $focusPoint');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('App de Câmera'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () {
              print('Botão da galeria clicado');
              if (mediaPath != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GalleryPage(mediaPath: mediaPath)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Nenhuma foto ou vídeo para mostrar')),
                );
              }
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTapDown: onTapFocusPoint,
        child: Stack(
          children: [
            CameraPreview(controller!),
            Positioned(
              left: focusPoint.dx - 30,
              top: focusPoint.dy - 30,
              child: Icon(
                Icons.control_camera, // Mudado para um ícone disponível
                color: Colors.red,
                size: 60,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(isFrontCamera ? Icons.camera_front : Icons.camera_rear),
              onPressed: () {
                print('Botão de troca de câmera clicado');
                switchCamera();
              },
            ),
            IconButton(
              icon: Icon(currentFlashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on),
              onPressed: () {
                print('Botão de flash clicado');
                toggleFlashMode();
              },
            ),
            IconButton(
              icon: Icon(isRecording ? Icons.stop : Icons.videocam),
              onPressed: () {
                if (isRecording) {
                  print('Botão de parar gravação clicado');
                  stopVideoRecording();
                } else {
                  print('Botão de iniciar gravação clicado');
                  startVideoRecording();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.photo_camera),
              onPressed: () {
                print('Botão de captura de foto clicado');
                takePicture();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryPage extends StatelessWidget {
  final String? mediaPath;
  const GalleryPage({Key? key, this.mediaPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galeria')),
      body: Center(
        child: mediaPath != null
            ? (mediaPath!.endsWith('.jpg')
            ? Image.file(File(mediaPath!))
            : VideoPlayerScreen(mediaPath: mediaPath!))
            : const Text('Nenhuma imagem ou vídeo para exibir'),
      ),
    );
  }
}

class VideoPlayerScreen extends StatelessWidget {
  final String mediaPath;
  const VideoPlayerScreen({Key? key, required this.mediaPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reprodução de Vídeo')),
      body: Center(
        child: VideoPlayerWidget(mediaPath: mediaPath),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String mediaPath;
  const VideoPlayerWidget({Key? key, required this.mediaPath}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.mediaPath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    )
        : const Center(child: CircularProgressIndicator());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
