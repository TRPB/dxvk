FROM archlinux:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
      base-devel \
      mingw-w64-gcc \
      meson \
      ninja \
      git \
      glslang

WORKDIR /build
