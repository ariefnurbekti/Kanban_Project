# STAGE 1: Build Frontend Assets
# Ini untuk membangun bagian tampilan (HTML/CSS/JS)
FROM node:16.3.0 AS frontend
WORKDIR /webapp
COPY webapp .
RUN npm install --no-optional
RUN npm run pack

# STAGE 2: Build Backend Go Binary
# Ini untuk membangun program server utama secara langsung
FROM golang:1.16.5 AS backend
WORKDIR /app
COPY . .
# Masuk ke direktori server untuk build
WORKDIR /app/server
# Download semua library yang dibutuhkan
RUN go mod download
# Build program Go untuk Linux dan letakkan di /app/focalboard-server
RUN CGO_ENABLED=0 GOOS=linux go build -a -o /app/focalboard-server .

# STAGE 3: Membuat Image Final yang Dapat Dijalankan
# Ini adalah tahap akhir untuk merakit semuanya menjadi satu image yang bersih
FROM alpine:3.15
RUN apk --no-cache add ca-certificates
WORKDIR /opt/focalboard

# Salin aset frontend yang sudah jadi dari STAGE 1
COPY --from=frontend /webapp/pack ./webapp/pack

# Salin program server yang sudah jadi dari STAGE 2
COPY --from=backend /app/focalboard-server ./main

# Beritahu port yang digunakan
EXPOSE 8000

# Perintah untuk menjalankan aplikasi
ENTRYPOINT ["./main"]
