FROM alpine:latest
RUN apk update
RUN apk add make musl-dev gcc python3
RUN pip3 install gcovr
WORKDIR /mnt
COPY . .
RUN make -B && make install
WORKDIR /

