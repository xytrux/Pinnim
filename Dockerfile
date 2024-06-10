FROM nim:2.0 AS builder

WORKDIR /usr/src

COPY . ./

RUN nimble build -y -d:release

FROM gcr.io/distroless/base-debian12:nonroot

COPY --from=builder /usr/src/main /main

CMD ["/main"]

# this may or may not work, I haven't tested it.