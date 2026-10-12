import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class PhotoStorage {
  static Future<String> store(XFile photo, int rabbitId) async {
    final directory = await getApplicationDocumentsDirectory();
    final folder = Directory('${directory.path}/rabbit_hub_photos');
    await folder.create(recursive: true);
    final extension = photo.name.contains('.')
        ? photo.name.split('.').last
        : 'jpg';
    final destination =
        '${folder.path}/${rabbitId}_${DateTime.now().microsecondsSinceEpoch}.$extension';
    return (await File(photo.path).copy(destination)).path;
  }
}
