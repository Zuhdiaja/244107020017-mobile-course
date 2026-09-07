# _02_week_2_responsive_dashboard

Nama : Muhammad Zuhdi Yudadharma<br>
NIM  : 244107020017<br>
Kelas: TI-3H<br>

1. hasil awal student dashboard<br>
![alt text](<screenshots/hasil awal.png>)

2. hasil setelah menambahkan <br>
_02_week_2_responsive_dashboard/screenshots/darkmode.png

Eksperimen <br>
1. Ubah breakpoint dari 700 menjadi nilai lain dan amati perubahan jumlah kolom.<br>
final columns = constraints.maxWidth >= 400 ? 2 : 1; = menghasilkan colum menjadi kecil<br>
![alt text](<screenshots/eksperimen 1.png>)

2. Ubah themeMode menjadi ThemeMode.dark, lalu kembalikan ke ThemeMode.system. = menghasilkan tampilan akan dark mode terus meskipun CupertinoSwitch mati<br>
![alt text](screenshots/hasildarktrs.png)

3. Uji aplikasi dengan ukuran layar emulator yang berbeda.<br>
![alt text](screenshots/hasil.png)

AI PROMPT<br>
| Aspek                | `GridView`                                                             | `LayoutBuilder + Column`                                                                   <br>
| **Tujuan utama**  : Menampilkan banyak item dalam bentuk grid                              : Mengatur elemen secara vertikal dan menyesuaikan layout berdasarkan ukuran layar              <br>
| **Responsif**     : Sangat cocok untuk kartu yang jumlahnya banyak                         : Lebih fleksibel untuk dashboard yang memiliki header, profil, statistik, dan section berbeda  <br>
| **Layar sempit**  : Bisa dibuat 1 kolom dengan `crossAxisCount`                            : Bisa mengubah susunan elemen berdasarkan `constraints.maxWidth`                               <br>
| **Layar lebar**   : Mudah dibuat 2–3 kolom                                                 : Lebih mudah mengatur kombinasi `Row`, `Column`, dan `Expanded`                                <br>
| **Header profil** :Kurang natural jika seluruh konten dibuat sebagai grid                  : Lebih natural karena header bisa ditempatkan di atas grid                                     <br>
| **Aksesibilitas** : Tidak otomatis lebih buruk, tetapi urutan pembacaan perlu diperhatikan : Lebih mudah mengatur urutan informasi secara logis                                            <br>
| **Kompleksitas**  : Relatif sederhana untuk kumpulan card                                  : Lebih kompleks karena membutuhkan pengaturan layout                                           <br>
| **Cocok untuk**   : Dashboard berbasis kartu/statistik                                     : Dashboard akademik dengan header + beberapa bagian informasi                                  <br>

- Tugas
1. Hasil <br>
![alt text](screenshots/tugas.png)

2. testing dasar<br>
![alt text](<screenshots/hasil tes.png>)
![alt text](<screenshots/hasil tes tampilan.png>)