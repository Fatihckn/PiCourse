enum LessonRequestStatus { pending, accepted, rejected, completed }

class LessonRequestModel {
  const LessonRequestModel({
    required this.id,
    required this.studentId,
    required this.tutorId,
    required this.subjectId,
    required this.startTime,
    required this.durationMinutes,
    required this.status,
    this.note,
    this.tutorName,
    this.studentName,
    this.subjectName,
  });

  final int id;
  final int studentId;
  final int tutorId;
  final int subjectId;
  final String startTime; // ISO8601
  final int durationMinutes;
  final LessonRequestStatus status;
  final String? note;
  final String? tutorName;
  final String? studentName;
  final String? subjectName;

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static LessonRequestStatus _parseStatus(dynamic value) {
    if (value == null) return LessonRequestStatus.pending;
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'pending':
          return LessonRequestStatus.pending;
        case 'accepted':
          return LessonRequestStatus.accepted;
        case 'rejected':
          return LessonRequestStatus.rejected;
        case 'completed':
          return LessonRequestStatus.completed;
        default:
          return LessonRequestStatus.pending;
      }
    }
    return LessonRequestStatus.pending;
  }

  factory LessonRequestModel.fromJson(Map<String, dynamic> json) {
    return LessonRequestModel(
      id: _parseInt(json['id']),
      studentId: _parseInt(json['student_id']),
      tutorId: _parseInt(json['tutor_id']),
      subjectId: _parseInt(json['subject_id']),
      startTime: json['start_time'] as String? ?? '',
      durationMinutes: _parseInt(json['duration_minutes']),
      status: _parseStatus(json['status']),
      note: json['note'] as String?,
      tutorName: json['tutor_name'] as String?,
      studentName: json['student_name'] as String?,
      subjectName: json['subject_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'tutor_id': tutorId,
      'subject_id': subjectId,
      'start_time': startTime,
      'duration_minutes': durationMinutes,
      'status': status.name,
      'note': note,
    };
  }
}


