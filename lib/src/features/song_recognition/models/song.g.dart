// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 0;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      id: fields[0] as String?,
      title: fields[1] as String,
      artist: fields[2] as String,
      album: fields[3] as String,
      albumCoverUrl: fields[4] as String,
      releaseDate: fields[5] as String,
      genre: fields[6] as String,
      hasFanChant: fields[7] as bool,
      lyrics: (fields[8] as List?)?.cast<LyricLine>(),
      isFavorite: fields[9] as bool,
      recognizedAt: fields[10] as DateTime?,
      appleMusicId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.album)
      ..writeByte(4)
      ..write(obj.albumCoverUrl)
      ..writeByte(5)
      ..write(obj.releaseDate)
      ..writeByte(6)
      ..write(obj.genre)
      ..writeByte(7)
      ..write(obj.hasFanChant)
      ..writeByte(8)
      ..write(obj.lyrics)
      ..writeByte(9)
      ..write(obj.isFavorite)
      ..writeByte(10)
      ..write(obj.recognizedAt)
      ..writeByte(11)
      ..write(obj.appleMusicId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LyricLineAdapter extends TypeAdapter<LyricLine> {
  @override
  final int typeId = 2;

  @override
  LyricLine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LyricLine(
      text: fields[0] as String,
      type: fields[1] as LyricType,
      startTime: fields[2] as int,
      endTime: fields[3] as int,
      isHighlighted: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LyricLine obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.isHighlighted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricLineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LyricTypeAdapter extends TypeAdapter<LyricType> {
  @override
  final int typeId = 1;

  @override
  LyricType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LyricType.artist;
      case 1:
        return LyricType.fan;
      case 2:
        return LyricType.both;
      default:
        return LyricType.artist;
    }
  }

  @override
  void write(BinaryWriter writer, LyricType obj) {
    switch (obj) {
      case LyricType.artist:
        writer.writeByte(0);
        break;
      case LyricType.fan:
        writer.writeByte(1);
        break;
      case LyricType.both:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
