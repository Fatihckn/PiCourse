import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/lesson_requests_repository.dart';
import '../domain/lesson_request.dart';

class LessonRequestsScreen extends ConsumerStatefulWidget {
  const LessonRequestsScreen({super.key});

  @override
  ConsumerState<LessonRequestsScreen> createState() => _LessonRequestsScreenState();
}

class _LessonRequestsScreenState extends ConsumerState<LessonRequestsScreen> {
  String _role = 'student';
  String? _status;

  Widget _buildStatusChip(LessonRequestStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case LessonRequestStatus.pending:
        color = Colors.orange;
        text = 'Bekliyor';
        break;
      case LessonRequestStatus.accepted:
        color = Colors.green;
        text = 'Kabul Edildi';
        break;
      case LessonRequestStatus.rejected:
        color = Colors.red;
        text = 'Reddedildi';
        break;
      case LessonRequestStatus.completed:
        color = Colors.blue;
        text = 'Tamamlandı';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Talepler')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _role,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'student', child: Text('Öğrenci Talepleri')),
                          DropdownMenuItem(value: 'tutor', child: Text('Eğitmen Talepleri')),
                        ],
                        onChanged: (v) => setState(() => _role = v ?? 'student'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _status,
                        isExpanded: true,
                        hint: const Text('Durum Filtresi'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Tümü')),
                          DropdownMenuItem(value: 'pending', child: Text('Bekliyor')),
                          DropdownMenuItem(value: 'accepted', child: Text('Kabul Edildi')),
                          DropdownMenuItem(value: 'rejected', child: Text('Reddedildi')),
                        ],
                        onChanged: (v) => setState(() => _status = v),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: ref.read(lessonRequestsRepositoryProvider).list(role: _role, status: _status),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }
                final data = snapshot.data;
                if (data == null || data.results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz talep bulunmuyor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Filtreleri değiştirerek farklı talepleri görebilirsiniz',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: data.results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final r = data.results[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Talep #${r.id}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                                                             Text(
                                         r.subjectName != null 
                                             ? '${r.subjectName} - ${r.tutorName ?? 'Eğitmen #${r.tutorId}'}'
                                             : 'Konu #${r.subjectId} - Eğitmen #${r.tutorId}',
                                         style: TextStyle(
                                           fontSize: 14,
                                           color: Colors.grey[600],
                                         ),
                                       ),
                                    ],
                                  ),
                                ),
                                _buildStatusChip(r.status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDateTime(r.startTime),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${r.durationMinutes} dakika',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            if (r.note != null && r.note!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Not: ${r.note}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            if (_role == 'tutor' && r.status == LessonRequestStatus.pending) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await ref
                                          .read(lessonRequestsRepositoryProvider)
                                          .patchStatus(r.id, LessonRequestStatus.accepted);
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Kabul Et'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await ref
                                          .read(lessonRequestsRepositoryProvider)
                                          .patchStatus(r.id, LessonRequestStatus.rejected);
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close, size: 16),
                                    label: const Text('Reddet'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}


