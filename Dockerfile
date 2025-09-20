# STAGE 1: Build Frontend Assets
# Menggunakan Node.js untuk mengkompilasi aplikasi web (HTML, CSS, JS).
FROM node:16.3.0 AS frontend

WORKDIR /webapp
COPY webapp .

# Install dependencies dan build frontend assets
RUN npm install --no-optional
RUN npm run pack


# STAGE 2: Build Backend Binary dan Package
# Menggunakan Go untuk mengkompilasi server dan menggabungkannya dengan aset frontend ke dalam satu arsip.
FROM golang:1.16.5 AS backend

# Menggunakan /app sebagai direktori kerja yang bersih
WORKDIR /app

# Salin semua kode sumber proyek
COPY . .

# Salin aset frontend yang sudah jadi dari tahap sebelumnya
COPY --from=frontend /webapp/pack ./webapp/pack

# Jalankan perintah 'make' yang membuat binary Go dan mengemasnya menjadi arsip .tar.gz.
# Perintah ini akan menghasilkan file di: /app/dist/focalboard-server-linux-amd64.tar.gz
RUN make server-linux-package-docker


# STAGE 3: Membuat Image Final yang Dapat Dijalankan
# Ini adalah image akhir yang kecil dan bersih yang akan benar-benar di-deploy.
FROM alpine:3.15

# Install sertifikat yang diperlukan untuk koneksi HTTPS
RUN apk --no-cache add ca-certificates

# Atur direktori kerja untuk aplikasi
WORKDIR /opt/focalboard

# Salin arsip final dari tahap 'backend'
COPY --from=backend /app/dist/focalboard-server-linux-amd64.tar.gz .

# Ekstrak arsip. Ini akan membuat direktori 'focalboard-server-linux-amd64'.
RUN tar -xvzf focalboard-server-linux-amd64.tar.gz

# Informasikan port mana yang akan digunakan aplikasi.
# Di Railway, ini akan ditimpa oleh variabel FOCALBOARD_PORT.
EXPOSE 8000

# Atur perintah yang akan dijalankan saat container dimulai.
# Ini menunjuk ke file program 'main' di dalam direktori yang telah diekstrak.
ENTRYPOINT ["./focalboard-server-linux-amd64/main"]
