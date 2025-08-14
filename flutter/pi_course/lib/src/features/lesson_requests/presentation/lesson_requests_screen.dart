import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/lesson_requests_repository.dart';
import '../domain/lesson_request.dart';
import '../../auth/domain/user.dart';
import '../../../core/di/providers.dart';

class LessonRequestsScreen extends ConsumerStatefulWidget {
  const LessonRequestsScreen({super.key});

  @override
  ConsumerState<LessonRequestsScreen> createState() => _LessonRequestsScreenState();
}

class _LessonRequestsScreenState extends ConsumerState<LessonRequestsScreen> {
  String? _status;
  bool _isUpdating = false; // Status güncelleme için loading state
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında mevcut kullanıcının bilgilerini al
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setCurrentUser();
    });
  }

  void _setCurrentUser() {
    final currentUser = ref.read(currentUserNotifierProvider);
    if (currentUser != null) {
      setState(() {
        _currentUser = currentUser;
      });
    }
  }

  // Status güncelleme metodu
  Future<void> _updateStatus(int requestId, LessonRequestStatus newStatus) async {
    if (_isUpdating) return; // Zaten güncelleme yapılıyorsa çık
    
    print('Status güncelleme başlatılıyor: Request ID: $requestId, New Status: ${newStatus.name}');
    
    setState(() {
      _isUpdating = true;
    });

    try {
      print('API çağrısı yapılıyor...');
      final result = await ref
          .read(lessonRequestsRepositoryProvider)
          .patchStatus(requestId, newStatus);
      
      print('API çağrısı başarılı: ${result.status.name}');
      
      // Başarılı güncelleme sonrası liste yenile
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == LessonRequestStatus.accepted 
                ? 'Talep kabul edildi!' 
                : 'Talep reddedildi!'
            ),
            backgroundColor: newStatus == LessonRequestStatus.accepted 
              ? Colors.green 
              : Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Status güncelleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status güncellenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

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

  String _getScreenTitle() {
    if (_currentUser == null) return 'Talepler';
    
    switch (_currentUser!.role) {
      case UserRole.student:
        return 'Gönderdiğim Talepler';
      case UserRole.tutor:
        return 'Gelen Talepler';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_getScreenTitle())),
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
          Expanded(
            child: FutureBuilder(
              key: ValueKey('${_currentUser!.role}_${_status}_${_isUpdating}'), // Liste yenileme için key
              future: ref.read(lessonRequestsRepositoryProvider).list(
                role: _currentUser!.role.name, 
                status: _status
              ),
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
                          _currentUser!.role == UserRole.student 
                            ? 'Henüz talep göndermediniz'
                            : 'Henüz gelen talep bulunmuyor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentUser!.role == UserRole.student
                            ? 'Yeni bir talep oluşturarak başlayabilirsiniz'
                            : 'Öğrencilerden gelen talepleri burada görebilirsiniz',
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
                                            ? '${r.subjectName} - ${_currentUser!.role == UserRole.student ? (r.tutorName ?? 'Eğitmen #${r.tutorId}') : (r.studentName ?? 'Öğrenci #${r.studentId}')}'
                                            : 'Konu #${r.subjectId} - ${_currentUser!.role == UserRole.student ? 'Eğitmen #${r.tutorId}' : 'Öğrenci #${r.studentId}'}',
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
                            if (_currentUser!.role == UserRole.tutor && r.status == LessonRequestStatus.pending) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _isUpdating 
                                      ? null 
                                      : () async {
                                          await _updateStatus(r.id, LessonRequestStatus.accepted);
                                        },
                                    icon: _isUpdating 
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.check, size: 16),
                                    label: Text(_isUpdating ? 'Güncelleniyor...' : 'Kabul Et'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _isUpdating 
                                      ? null 
                                      : () async {
                                          await _updateStatus(r.id, LessonRequestStatus.rejected);
                                        },
                                    icon: _isUpdating 
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.close, size: 16),
                                    label: Text(_isUpdating ? 'Güncelleniyor...' : 'Reddet'),
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


