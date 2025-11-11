# Laporan Praktikum: Geolocation (flutter_new12)

Nama: Ahmad Bachtiar Raflyansyah
Mata Praktikum: Pemrograman Mobile
Tanggal: 11 November 2025

## Ringkasan
Laporan ini mendokumentasikan perbaikan dan pengujian fitur geolocation serta reverse-geocoding pada proyek `flutter_new12`. Fokus utama adalah menangani kasus nilai null pada hasil reverse-geocoding dan menambahkan mekanisme fallback menggunakan layanan Nominatim (OpenStreetMap) sehingga aplikasi tetap memberikan informasi lokasi walau layanan utama gagal.

## Tujuan
- Menghilangkan crash/bug akibat "Unexpected null value" saat menampilkan alamat hasil reverse-geocoding.
- Menambahkan fallback reverse-geocoding (Nominatim) ketika plugin `geocoding` tidak memberikan hasil yang memadai.
- Menampilkan pesan fallback yang ramah pengguna (mis. menampilkan koordinat ketika alamat tidak tersedia).

## Perubahan yang dilakukan
- Memperbarui fungsi reverse-geocoding agar melakukan pengecekan null-safe pada setiap field alamat.
- Menambahkan panggilan HTTP ke API Nominatim sebagai fallback bila plugin `geocoding` mengembalikan hasil kosong atau tidak lengkap.
- Menambahkan UI/UX pesan fallback: menampilkan koordinat jika tidak ada alamat manusiawi.

## Implementasi teknis (singkat)
- Bahasa/framework: Flutter (Dart)
- Dependency utama di `pubspec.yaml`: `geolocator`, `geocoding` (untuk panggilan Nominatim) — pastikan versi sesuai kebutuhan proyek.
- File yang kemungkinan diubah: file util/helper untuk reverse-geocoding, service yang memanggil Nominatim, dan bagian UI yang menampilkan alamat.

## Cara menjalankan (lokal)
1. Pastikan Flutter sudah terinstal dan environment sudah dikonfigurasi.
2. Periksa `pubspec.yaml` dan pastikan dependency berikut ada (contoh):

```yaml
dependencies:
  flutter:
    sdk: flutter
  geolocator: ^9.0.0
  geocoding: ^2.0.0
```

3. Ambil dependency dan jalankan aplikasi:

```bash
flutter pub get
flutter run
```

4. Di aplikasi: gunakan tombol atau fitur "Dapatkan Lokasi" / "Reverse Geocode" untuk menguji fungsi. Perhatikan log untuk fallback Nominatim bila `geocoding` tidak mengembalikan alamat.

## Verifikasi & Hasil
- Setelah perbaikan, aplikasi tidak lagi crash pada kasus nilai null dari hasil geocoding.
- Contoh pengujian (koordinat):
  - Lat: -8.2941983, Lng: 114.3072228
  - Hasil (Nominatim): Labansukadi, Labanasem, Banyuwangi, East Java, Indonesia

![WhatsApp Image 2025-11-11 at 19 17 05](https://github.com/user-attachments/assets/16ba03e8-4aa1-4244-99ee-b28524efbacc)


## Kesimpulan
Penambahan validasi null-safe dan mekanisme fallback (Nominatim) meningkatkan ketahanan aplikasi terhadap kegagalan layanan geocoding. Aplikasi kini dapat tetap menyajikan informasi lokasi kepada pengguna meskipun sumber utama gagal atau mengembalikan data tidak lengkap.





