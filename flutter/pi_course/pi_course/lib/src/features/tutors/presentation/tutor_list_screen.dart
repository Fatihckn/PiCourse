import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../subjects/data/subjects_repository.dart';
import '../../tutors/data/tutors_repository.dart';
import '../../../core/di/providers.dart';

final _searchProvider = StateProvider<String>((ref) => '');
final _selectedSubjectProvider = StateProvider<int?>((ref) => null);
final _debouncedSearchProvider = StateProvider<String>((ref) => '');

class TutorListScreen extends ConsumerStatefulWidget {
  const TutorListScreen({super.key});

  @override
  ConsumerState<TutorListScreen> createState() => _TutorListScreenState();
}

class _TutorListScreenState extends ConsumerState<TutorListScreen> {
  Timer? _debounceTimer;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(_searchProvider.notifier).state = value;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      ref.read(_debouncedSearchProvider.notifier).state = value;
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Secure storage'dan token'ı temizle
              _logout();
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      // Secure storage'dan token'ı temizle
      final storage = ref.read(secureStorageProvider);
      await storage.delete(key: 'auth_token');
      
      // Login sayfasına yönlendir
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yapılırken hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(_searchProvider);
    final subjectId = ref.watch(_selectedSubjectProvider);
    
    // Controller'ı search state ile senkronize et
    if (_searchController.text != search) {
      _searchController.text = search;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pi Course',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Eğitmenler',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => context.push('/lesson-requests'),
                                icon: Icon(Icons.list_alt, color: Colors.blue.shade600),
                                tooltip: 'Taleplerim',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => _showLogoutDialog(context),
                                icon: Icon(Icons.logout, color: Colors.red.shade600),
                                tooltip: 'Çıkış Yap',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Search and Filter
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Eğitmen ara...',
                                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _SubjectFilter(),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Tutors List
              Expanded(
                child: _TutorsList(
                  search: ref.watch(_debouncedSearchProvider),
                  subjectId: subjectId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectFilter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(subjectsRepositoryProvider).list(),
      builder: (context, snapshot) {
        final items = snapshot.data;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: ref.watch(_selectedSubjectProvider),
              hint: Text(
                'Konu',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              onChanged: (v) => ref.read(_selectedSubjectProvider.notifier).state = v,
              items: [
                DropdownMenuItem<int?>(
                  value: null, 
                  child: Text('Tümü', style: TextStyle(color: Colors.grey.shade600)),
                ),
                if (items != null)
                  ...items.map(
                    (s) => DropdownMenuItem<int?>(
                      value: s.id, 
                      child: Text(s.name),
                    ),
                  )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TutorsList extends ConsumerWidget {
  const _TutorsList({required this.search, required this.subjectId});
  final String search;
  final int? subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(tutorsRepositoryProvider).list(
            subjectId: subjectId,
            ordering: '-rating',
            search: search.isEmpty ? null : search,
            limit: 20,
            offset: 0,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Eğitmenler yükleniyor...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bir hata oluştu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hata detayı: ${snapshot.error}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => (context as Element).markNeedsBuild(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        final data = snapshot.data;
        if (data == null || data.results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Eğitmen bulunamadı',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      search.isNotEmpty
                          ? '"$search" araması için sonuç bulunamadı'
                          : 'Şu anda kayıtlı eğitmen bulunmuyor',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.separated(
            itemCount: data.results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tutor = data.results[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push('/tutors/${tutor.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Avatar
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade400,
                                      Colors.purple.shade400,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tutor.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.star, size: 16, color: Colors.amber[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${tutor.rating.toStringAsFixed(1)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(Icons.attach_money, size: 16, color: Colors.green[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${tutor.hourlyRate.toStringAsFixed(0)}₺/saat',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tutor.bio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                          if (tutor.subjects.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: tutor.subjects.take(3).map((subject) => 
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    subject.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                )
                              ).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}


