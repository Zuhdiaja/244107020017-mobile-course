# AI Verification

## 1. Immutable State

Status: LULUS

State ToDo tidak dimutasi secara langsung.

Tidak menggunakan:
- state.add()
- state.remove()
- mutasi list secara langsung

Perubahan state dilakukan dengan membuat list baru, contohnya:

state = [...state, Todo(title)];

Pada StatsNotifier, state juga diperbarui dengan assignment:

state = const AsyncLoading();

dan:

state = await AsyncValue.guard(_fetchStats);

---

## 2. Penggunaan ref.watch dan ref.read

Status: LULUS

`ref.watch` digunakan di dalam `build()` untuk mengamati perubahan state.

Contoh:

final todos = ref.watch(todoListProvider);

`ref.read` digunakan pada callback/event seperti tombol tambah,
toggle, delete, dan retry.

Contoh:

ref.read(todoListProvider.notifier).toggle(index);

dan:

ref.read(statsProvider.notifier).retry();

---

## 3. Penanganan AsyncValue

Status: LULUS

StatsPage menangani tiga kondisi AsyncValue:

1. Loading
   - Menampilkan CircularProgressIndicator.

2. Error
   - Menampilkan pesan error.
   - Menampilkan tombol Coba Lagi.

3. Data/Success
   - Menampilkan data statistik menggunakan ListView.

Ketiga kondisi ditangani menggunakan:

statsAsync.when(
  loading: ...,
  error: ...,
  data: ...,
);

---

## 4. Provider Eksplisit dan Tidak Duplikat

Status: LULUS

Provider statistik dideklarasikan satu kali:

final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);

Provider ToDo utama juga hanya dideklarasikan satu kali:

final todoListProvider =
    NotifierProvider<TodoListNotifier, List<Todo>>(
  TodoListNotifier.new,
);

Filter tugas dibuat sebagai provider turunan:

final unfinishedTodoProvider = Provider<List<Todo>>(...);

---

## 5. Riverpod API Modern

Status: LULUS

Implementasi menggunakan:

- Notifier
- NotifierProvider
- AsyncNotifier
- AsyncNotifierProvider
- ConsumerWidget
- Provider

Tidak menggunakan:

- StateProvider
- StateNotifierProvider
- API Riverpod lama

---

## 6. Refactoring

Status: LULUS

Widget ToDo dipisahkan menjadi:

lib/widgets/todo_tile.dart

Filter tugas dipisahkan menjadi:

unfinishedTodoProvider

Navigasi aplikasi menggunakan GoRouter dengan:

/       -> TodoPage
/stats  -> StatsPage

NavigationBar digunakan untuk berpindah antara halaman ToDo
dan Statistik.

---

## 7. Testing

Widget test digunakan untuk memastikan pengguna dapat menambahkan
tugas baru.

Skenario:

1. Membuka halaman ToDo.
2. Memastikan teks "Belum ada tugas" muncul.
3. Menekan tombol tambah.
4. Mengisi "Kerjakan PR minggu 3".
5. Menekan tombol Tambah.
6. Memastikan tugas muncul pada halaman.

Unit test juga digunakan untuk memverifikasi StatsNotifier
menghasilkan tiga data statistik.

---

## 8. Verifikasi Flutter

Perintah yang digunakan:

flutter analyze

flutter test

Hasil akhir yang diharapkan:

flutter analyze
No issues found!

flutter test
All tests passed!