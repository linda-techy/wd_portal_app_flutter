class ProgressUpdateDto {
  final int progressPercent;
  final String? note;

  const ProgressUpdateDto({required this.progressPercent, this.note});

  Map<String, dynamic> toJson() => {
        'progressPercent': progressPercent,
        if (note != null) 'note': note,
      };
}
