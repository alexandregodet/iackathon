import 'package:equatable/equatable.dart';

class DocumentInfo extends Equatable {
  final int id;
  final String name;
  final String filePath;
  final int totalChunks;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final bool isActive;

  const DocumentInfo({
    required this.id,
    required this.name,
    required this.filePath,
    required this.totalChunks,
    required this.createdAt,
    this.lastUsedAt,
    this.isActive = false,
  });

  DocumentInfo copyWith({
    int? id,
    String? name,
    String? filePath,
    int? totalChunks,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? isActive,
  }) {
    return DocumentInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      totalChunks: totalChunks ?? this.totalChunks,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        filePath,
        totalChunks,
        createdAt,
        lastUsedAt,
        isActive,
      ];
}
