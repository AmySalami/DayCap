import 'package:gal/gal.dart';

/// บันทึกวิดีโอที่รวมแล้วลงอัลบั้มในเครื่อง (album: day_cap)
class GalleryService {
  static const _album = 'day_cap';

  /// ขอสิทธิ์ถ้ายังไม่มี แล้วบันทึกวิดีโอลงอัลบั้ม
  /// คืน false ถ้าผู้ใช้ไม่ให้สิทธิ์
  Future<bool> saveVideo(String path) async {
    if (!await Gal.hasAccess(toAlbum: true)) {
      final granted = await Gal.requestAccess(toAlbum: true);
      if (!granted) return false;
    }
    await Gal.putVideo(path, album: _album);
    return true;
  }
}
