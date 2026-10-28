import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes.dart';
import '../../domain/entities/announcement.dart';
import '../providers/announcements_providers.dart';

/// Halaman daftar pengumuman + pencarian judul (Minggu 9: fitur hasil AI).
///
/// Halaman ini hanya: (1) menampung input query ke provider,
/// (2) membaca hasil filter, (3) menampilkan empty state.
/// Aturan filter sendiri hidup di [SearchAnnouncements] (domain).
class AnnouncementsPage extends ConsumerWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAnnouncements = ref.watch(announcementsProvider);
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(filteredAnnouncementsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const Key('search-field'),
              decoration: InputDecoration(
                hintText: 'Cari judul pengumuman...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          ref.read(searchQueryProvider.notifier).clear();
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).set(value),
            ),
          ),
          Expanded(
            child: asyncAnnouncements.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _Message(
                icon: Icons.cloud_off,
                color: colorScheme.error,
                title: 'Gagal memuat pengumuman',
              ),
              data: (_) => results.isEmpty
                  ? _Message(
                      icon: query.isEmpty ? Icons.campaign : Icons.search_off,
                      color: colorScheme.primary,
                      title: query.isEmpty
                          ? 'Belum ada pengumuman'
                          : 'Tidak ada pengumuman yang cocok',
                      subtitle: query.isEmpty
                          ? 'Daftar pengumuman masih kosong.'
                          : 'Coba kata kunci lain, mis. "ujian".',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final announcement = results[index];
                        return _AnnouncementCard(announcement: announcement);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state dan error state — teksnya terpisah agar mudah diuji widget.
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Satu baris pengumuman; menekan kartu membuka deep link /pengumuman/:id.
class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.campaign),
        title: Text(announcement.title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            announcement.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        onTap: () => context.go(AppRoutes.announcement(announcement.id)),
      ),
    );
  }
}
