FROM golang:1.15.2-alpine AS base
WORKDIR /src
ENV CGO_ENABLED=0
COPY go.* /
COPY *.go /
RUN go mod download

FROM base AS build
WORKDIR ..
ARG TARGETOS
ARG TARGETARCH
RUN GOOS=linux GOARCH=amd64 go build -o /out/example .

FROM base AS unit-test
RUN mkdir /out && go test -v -coverprofile=/out/cover.out ./...

FROM golangci/golangci-lint:v1.31.0-alpine AS lint
COPY --from=base ./src/* ./src/
RUN golangci-lint run --timeout 10m0s ./...

FROM scratch AS unit-test-coverage
COPY --from=unit-test /out/cover.out /cover.out

FROM scratch AS bin-unix
COPY --from=build /out/example /

FROM bin-unix AS bin-linux
FROM bin-unix AS bin-darwin

FROM scratch AS bin-windows
COPY --from=build /out/example /example.exe

FROM bin-${TARGETOS} as bin 

FROM debian:latest as service
COPY --from=build /out/example /service
ENTRYPOINT ["/service"]
