FROM alpine:latest
RUN apk update
RUN apk add make musl-dev gcc
WORKDIR /mnt
COPY . .
RUN make -B && make install
WORKDIR /

