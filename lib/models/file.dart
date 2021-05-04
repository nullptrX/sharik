import 'dart:io' show Platform;

import 'package:hive/hive.dart';

part 'file.g.dart';

@HiveType(typeId: 1)
class FileModel {
  @HiveField(0)
  final FileTypeModel type;

  /// path to file if type is file
  /// path to apk if type is app
  /// raw text if type is text
  @HiveField(1)
  final String data;

  @HiveField(2)
  late String name;

  String get icon {
    switch (type) {
      case FileTypeModel.file:
        return 'assets/icon_folder2.svg';

      case FileTypeModel.text:
        return 'assets/icon_file_word.svg';

      case FileTypeModel.app:
        return 'assets/icon_file_app.svg';
    }
  }

  FileModel({required this.type, required this.data, String? fileName}) {
    if (fileName == null) {
      switch (type) {
        case FileTypeModel.file:
          name = data.split(Platform.isWindows ? '\\' : '/').last;
          break;
        case FileTypeModel.text:
          final _ = data.trim().replaceAll('\n', ' ');
          name = _.length >= 101 ? _.substring(0, 100) : _;
          break;
        case FileTypeModel.app:
          throw Exception('when type is app, name is neccesary');
      }
    } else {
      name = fileName;
    }
  }
}

@HiveType(typeId: 2)
enum FileTypeModel {
  @HiveField(0)
  file,
  @HiveField(1)
  text,
  @HiveField(2)
  app
}

FileTypeModel string2fileType(String type){
  switch(type){
    case 'file':
      return FileTypeModel.file;

    case 'text':
      return FileTypeModel.text;

    case 'app':
      return FileTypeModel.app;
  }
  throw UnimplementedError('Type $type does not exist');
}