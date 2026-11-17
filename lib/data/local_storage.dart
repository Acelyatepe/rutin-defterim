import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';

class LocalStorage {
  LocalStorage(this.directory);
  LocalStorage.memory() : directory = null;
  final Directory? directory;
  String? _memory;
  String? recoveryMessage;

  static Future<LocalStorage> open() async {
    final root = await getApplicationSupportDirectory();
    final directory = await Directory(
      '${root.path}/dayli',
    ).create(recursive: true);
    if (Platform.isIOS) {
      await const MethodChannel(
        'com.acelya.dayli/storage',
      ).invokeMethod<void>('excludeFromBackup', directory.path);
    }
    return LocalStorage(directory);
  }

  Future<DayliData?> load() async {
    recoveryMessage = null;
    if (directory == null) {
      return _memory == null ? null : DayliData.fromJson(jsonDecode(_memory!));
    }
    final primary = File('${directory!.path}/dayli.json');
    final backup = File('${directory!.path}/dayli.backup.json');
    if (!await primary.exists() && !await backup.exists()) return null;
    try {
      return DayliData.fromJson(jsonDecode(await primary.readAsString()));
    } catch (_) {
      try {
        final data = DayliData.fromJson(
          jsonDecode(await backup.readAsString()),
        );
        if (await primary.exists()) {
          await primary.copy(
            '${directory!.path}/dayli.damaged.${DateTime.now().microsecondsSinceEpoch}.json',
          );
        }
        final recovery = File('${directory!.path}/dayli.recovery.tmp');
        await recovery.writeAsString(jsonEncode(data.toJson()), flush: true);
        await recovery.rename(primary.path);
        recoveryMessage =
            'Son sağlam yerel kopya geri yüklendi. Son değişikliği kontrol et.';
        return data;
      } catch (_) {
        throw const FileSystemException(
          'Yerel veriler okunamadı. Mevcut dosyalar korundu.',
        );
      }
    }
  }

  Future<void> save(DayliData data) async {
    final json = jsonEncode(data.toJson());
    if (directory == null) {
      _memory = json;
      return;
    }
    final primary = File('${directory!.path}/dayli.json');
    final temporary = File('${directory!.path}/dayli.tmp');
    final backupTemporary = File('${directory!.path}/dayli.backup.tmp');
    await temporary.writeAsString(json, flush: true);
    if (await primary.exists()) {
      await backupTemporary.writeAsBytes(
        await primary.readAsBytes(),
        flush: true,
      );
      await backupTemporary.rename('${directory!.path}/dayli.backup.json');
    }
    await temporary.rename(primary.path);
  }
}
