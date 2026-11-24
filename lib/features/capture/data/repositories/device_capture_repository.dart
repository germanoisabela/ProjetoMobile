import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/capture_mode.dart';
import '../../domain/entities/captured_input.dart';
import '../../domain/repositories/capture_repository.dart';

class DeviceCaptureRepository implements CaptureRepository {
  const DeviceCaptureRepository();

  @override
  Future<CapturedInput?> pickFromCamera() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image == null) return null;

    return CapturedInput(
      path: image.path,
      name: image.name,
      mode: CaptureMode.camera,
    );
  }

  @override
  Future<CapturedInput?> pickImageOrPdf() async {
    final files = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    if (files == null || files.files.isEmpty) return null;

    final file = files.files.first;
    final path = file.path;
    if (path == null) {
      throw const FileSystemException(
        'Não foi possível acessar o caminho do arquivo selecionado.',
      );
    }

    return CapturedInput(
      path: path,
      name: file.name,
      mode: CaptureMode.imageOrPdf,
    );
  }
}
