import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../subjects/domain/subject.dart';
import '../../subjects/data/subjects_repository.dart';
import '../data/my_tutor_profile_provider.dart';
import '../../../core/di/providers.dart';

class TutorProfileEditScreen extends ConsumerStatefulWidget {
  const TutorProfileEditScreen({super.key});

  @override
  ConsumerState<TutorProfileEditScreen> createState() => _TutorProfileEditScreenState();
}

class _TutorProfileEditScreenState extends ConsumerState<TutorProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _hourlyRateCtrl = TextEditingController();
  
  List<SubjectModel> _allSubjects = [];
  List<SubjectModel> _selectedSubjects = [];
  bool _loading = false;
  bool _subjectsLoaded = false;

  @override
  void initState() {
    super.initState();
    // Widget build edildikten sonra profil bilgilerini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubjects();
      _loadCurrentProfile();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa açıldığında profil bilgilerini yeniden yükle
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _hourlyRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await ref.read(subjectsRepositoryProvider).list();
      setState(() {
        _allSubjects = subjects;
        _subjectsLoaded = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dersler yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCurrentProfile() async {
    try {
      // Her zaman API'den güncel profil bilgilerini al
      await ref.read(myTutorProfileProvider.notifier).loadProfile();
      final loadedProfile = ref.read(myTutorProfileProvider);
      
      if (loadedProfile != null && mounted) {
        setState(() {
          _nameCtrl.text = loadedProfile.name;
          _bioCtrl.text = loadedProfile.bio;
          _hourlyRateCtrl.text = loadedProfile.hourlyRate.toString();
          _selectedSubjects = List.from(loadedProfile.subjects);
        });
        print('Profil bilgileri yüklendi: ${loadedProfile.name}, ${loadedProfile.bio}, ${loadedProfile.hourlyRate}');
      } else {
        print('Profil yüklenemedi veya null');
      }
    } catch (e) {
      // Profil yüklenemezse yeni profil oluşturulacak
      print('Mevcut profil yüklenemedi: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil bilgileri yüklenirken hata: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir ders seçmelisiniz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    
    try {
      // Profil güncelleme API'sini çağır
      await ref.read(myTutorProfileProvider.notifier).updateProfile(
        name: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        hourlyRate: double.parse(_hourlyRateCtrl.text.trim()),
        subjectIds: _selectedSubjects.map((s) => s.id).toList(),
      );
      
      // Profil güncellendikten sonra state'i yenile
      await ref.read(myTutorProfileProvider.notifier).loadProfile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil güncellenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleSubject(SubjectModel subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
      } else {
        _selectedSubjects.add(subject);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Düzenle'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık Kartı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.purple.shade600,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Öğretmen Profili',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Verebileceğiniz dersleri ve ücret bilgilerinizi ayarlayın',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form Kartı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kişisel Bilgiler',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // İsim Alanı
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Ad Soyad',
                            hintText: 'Adınızı ve soyadınızı girin',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) => v?.trim().isEmpty == true ? 'Ad soyad gerekli' : null,
                        ),
                        const SizedBox(height: 20),

                        // Bio Alanı
                        TextFormField(
                          controller: _bioCtrl,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Hakkımda',
                            hintText: 'Kendinizi ve deneyimlerinizi kısaca anlatın',
                            prefixIcon: Icon(Icons.description),
                            alignLabelWithHint: true,
                          ),
                          validator: (v) => v?.trim().isEmpty == true ? 'Hakkımda bilgisi gerekli' : null,
                        ),
                        const SizedBox(height: 20),

                        // Saatlik Ücret
                        TextFormField(
                          controller: _hourlyRateCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Saatlik Ücret (TL)',
                            hintText: 'Örn: 150',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          validator: (v) {
                            if (v?.trim().isEmpty == true) return 'Saatlik ücret gerekli';
                            final rate = double.tryParse(v!);
                            if (rate == null || rate <= 0) return 'Geçerli bir ücret girin';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Dersler Başlığı
                        const Text(
                          'Verebileceğiniz Dersler',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dersler Listesi
                        if (!_subjectsLoaded)
                          const Center(
                            child: CircularProgressIndicator(),
                          )
                        else
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _allSubjects.map((subject) {
                              final isSelected = _selectedSubjects.contains(subject);
                              return FilterChip(
                                label: Text(subject.name),
                                selected: isSelected,
                                onSelected: (_) => _toggleSubject(subject),
                                selectedColor: Colors.blue.shade100,
                                checkmarkColor: Colors.blue.shade600,
                                backgroundColor: Colors.grey.shade100,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.blue.shade700 : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 32),

                        // Kaydet Butonu
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Profili Kaydet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
