import 'package:sqlite3/sqlite3.dart';

import 'camera_dao.dart';

class PackLoader {
  PackLoader._();

  static CameraDao openPack(String path) {
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    return CameraDao(db);
  }
}
