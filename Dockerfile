# This dockerfile is used to build Focalboard for Linux
# it builds all the parts inside the container and the last stage just holds the
# package that can be extracted using docker cp command
# ie
# docker build -f Dockerfile.build --no-cache -t focalboard-build:dirty .
# docker run --rm -v /tmp/dist:/tmp -d --name test focalboard-build:dirty /bin/sh -c 'sleep 1000'
# docker cp test:/dist/focalboard-server-linux-amd64.tar.gz .

# build frontend
FROM node:16.3.0 AS frontend

WORKDIR /webapp
COPY webapp .

RUN npm install --no-optional
RUN npm run pack

# build backend and package
FROM golang:1.16.5 AS backend

COPY . .
COPY --from=frontend /webapp/pack webapp/pack

# RUN apt-get update && apt-get install libgtk-3-dev libwebkit2gtk-4.0-dev -y
RUN make server-linux
RUN make server-linux-package-docker
# Modify Dockerfile to include the missing extraction step
# This is the correct sequence of commands.
# 1. Copy the archive
# 2. Extract the archive
# 3. Point the entrypoint to the extracted executable
# ... (bagian sebelumnya)

# just hold the packages to output later
FROM alpine:3.12 AS dist

WORKDIR /dist

COPY --from=backend /go/dist/focalboard-server-linux-amd64.tar.gz .
RUN tar -xvzf focalboard-server-linux-amd64.tar.gz

ENTRYPOINT ["/dist/focalboard/main"]
