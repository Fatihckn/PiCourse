import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../subjects/data/subjects_repository.dart';
import '../../subjects/domain/subject.dart';
import '../../tutors/data/tutors_repository.dart';
import '../../tutors/domain/tutor.dart';
import '../data/lesson_requests_repository.dart';

class LessonRequestFormScreen extends ConsumerStatefulWidget {
  const LessonRequestFormScreen({super.key, this.tutorId});
  final int? tutorId;

  @override
  ConsumerState<LessonRequestFormScreen> createState() => _LessonRequestFormScreenState();
}

class _LessonRequestFormScreenState extends ConsumerState<LessonRequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _subjectId;
  DateTime? _dateTime;
  final _durationCtrl = TextEditingController(text: '60');
  final _noteCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _durationCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;

    setState(() => _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (_formKey.currentState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form yüklenirken hata oluştu')),
      );
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_dateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tarih ve saat seçin')),
      );
      return;
    }

    if (_subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir konu seçin')),
      );
      return;
    }

    if (widget.tutorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Eğitmen bilgisi bulunamadı')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final iso = _dateTime!.toUtc().toIso8601String();
      final durationMinutes = int.tryParse(_durationCtrl.text.trim());
      
      if (durationMinutes == null || durationMinutes <= 0) {
        throw Exception('Geçersiz süre değeri: ${_durationCtrl.text}');
      }

      final result = await ref.read(lessonRequestsRepositoryProvider).create(
        tutorId: widget.tutorId!,
        subjectId: _subjectId!,
        startTime: iso,
        durationMinutes: durationMinutes,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ders talebi başarıyla oluşturuldu!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Bir hata oluştu';
      if (e.toString().contains('400')) {
        errorMessage = 'Geçersiz veri gönderildi. Lütfen tüm alanları kontrol edin.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Ağ bağlantısı hatası';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ders Talebi Oluştur')),
      body: FutureBuilder(
        future: widget.tutorId != null 
            ? Future.wait([
                ref.read(subjectsRepositoryProvider).list(),
                ref.read(tutorsRepositoryProvider).get(widget.tutorId!),
              ])
            : ref.read(subjectsRepositoryProvider).list(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Veriler yükleniyor...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Veriler yüklenirken hata oluştu',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Hata Detayı:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: const TextStyle(fontSize: 12, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text('Veri bulunamadı'),
            );
          }

          List<SubjectModel> subjects;
          TutorModel? tutor;

          if (widget.tutorId != null) {
            // Future.wait kullanıldığında data bir List olur
            final dataList = data as List;
            subjects = dataList[0] as List<SubjectModel>;
            tutor = dataList[1] as TutorModel;
          } else {
            // Sadece subjects çağrıldığında data direkt List<SubjectModel> olur
            subjects = data as List<SubjectModel>;
            tutor = null;
          }
          
          // Tutor'ın öğrettiği konuları filtrele
          final availableSubjects = tutor != null 
              ? subjects.where((subject) => 
                  tutor!.subjects.any((tutorSubject) => tutorSubject.id == subject.id))
                  .toList()
              : subjects;
          
          if (availableSubjects.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.book_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Konu bulunamadı',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tutor != null 
                          ? 'Bu eğitmen henüz hiç konu eklememiş'
                          : 'Henüz hiç konu eklenmemiş',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  if (tutor != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Seçilen Eğitmen:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tutor.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Öğrettiği konular: ${tutor.subjects.map((s) => s.name).join(', ')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  DropdownButtonFormField<int>(
                    value: _subjectId,
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Konu seçin', style: TextStyle(color: Colors.grey)),
                      ),
                      ...availableSubjects.map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      )),
                    ],
                    onChanged: (v) {
                      setState(() => _subjectId = v);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Konu',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.book),
                    ),
                    validator: (v) {
                      if (v == null) {
                        return 'Lütfen bir konu seçin';
                      }
                      return null;
                    },
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDateTime,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _dateTime == null ? 'Tarih/Saat seçin' : 'Seçilen Tarih/Saat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _dateTime == null
                                      ? 'Tıklayarak seçin'
                                      : DateFormat('dd MMMM yyyy, HH:mm').format(_dateTime!),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: _dateTime == null ? FontWeight.normal : FontWeight.w500,
                                    color: _dateTime == null ? Colors.grey.shade400 : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Süre (dakika)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                      hintText: '60',
                    ),
                    validator: (v) {
                      final duration = int.tryParse(v?.trim() ?? '');
                      if (duration == null || duration <= 0) {
                        return 'Geçerli bir süre girin (dk)';
                      }
                      if (duration > 480) { // 8 saat maksimum
                        return 'Maksimum 480 dakika olabilir';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Not (opsiyonel)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                      hintText: 'Ders hakkında notlarınız...',
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text('Ders Talebini Gönder'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}