import 'package:flutter/material.dart';

/// Halaman tujuan deep link `/pengumuman/:id`.
/// Dibuka otomatis saat pengguna menekan notifikasi FCM yang membawa
/// `data.route` (mis. "/pengumuman/3").
class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.campaign, size: 72, color: Colors.indigo),
              const SizedBox(height: 16),
              Text(
                'Pengumuman #$id',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Halaman ini adalah target deep link data.route dari '
                'payload notifikasi FCM.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
