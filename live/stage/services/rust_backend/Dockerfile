FROM rust:buster as builder

WORKDIR /app
COPY . .
RUN cargo build #--release
EXPOSE 3000

CMD ["/app/target/debug/rust_backend"]