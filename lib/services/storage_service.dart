import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// จัดการไฟล์ในแอป: โฟลเดอร์คลิป + ไฟล์ metadata
/// คลิปเก็บใน Application Documents → ไม่โผล่ในอัลบั้มเครื่อง
class StorageService {
  Directory? _clipsDirCache;

  /// โฟลเดอร์เก็บคลิปดิบ (AppDocuments/clips)
  Future<Directory> clipsDir() async {
    if (_clipsDirCache != null) return _clipsDirCache!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/clips');
    if (!await dir.exists()) await dir.create(recursive: true);
    _clipsDirCache = dir;
    return dir;
  }

  /// ไฟล์ metadata ของสัปดาห์ (AppDocuments/week_log.json)
  Future<File> metaFile() async {
    final docs = await getApplicationDocumentsDirectory();
    return File('${docs.path}/week_log.json');
  }

  /// path เต็มของคลิปจากชื่อไฟล์ (relative)
  Future<String> absolutePath(String fileName) async {
    final dir = await clipsDir();
    return '${dir.path}/$fileName';
  }

  /// ย้ายไฟล์ที่อัดเสร็จ (จาก temp ของ camera) เข้าโฟลเดอร์ clips
  /// คืนชื่อไฟล์ (relative) ที่จะเก็บใน metadata
  Future<String> importRecording(String tempPath, String fileName) async {
    final dest = await absolutePath(fileName);
    await File(tempPath).copy(dest);
    // ลบไฟล์ temp เดิม (best-effort)
    try {
      await File(tempPath).delete();
    } catch (_) {}
    return fileName;
  }

  /// ลบคลิปเดี่ยว
  Future<void> deleteClipFile(String fileName) async {
    final f = File(await absolutePath(fileName));
    if (await f.exists()) await f.delete();
  }

  /// ล้างคลิปทั้งหมด + metadata (ใช้ตอนขึ้นสัปดาห์ใหม่)
  Future<void> wipeAll() async {
    final dir = await clipsDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
    final meta = await metaFile();
    if (await meta.exists()) await meta.delete();
  }
}
