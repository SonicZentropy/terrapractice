set fallback := true

dockerBuild:
    docker build -t rust_backend .
dockerRun:
    docker run -it --name rust_backend -p 3000:3000 rust_backend
build:
    cargo build
run:
    cargo run