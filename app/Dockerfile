#Build Stage

FROM golang:1.25.5-alpine3.22 AS builder


WORKDIR /app


ENV CGO_ENABLED=0\
    GOOS=linux \
    GOARCH=amd64


COPY  go.mod go.sum ./

RUN go mod download

COPY . .

RUN go build -o /app/app .

# RunTime

FROM gcr.io/distroless/static-debian12 AS runtime

WORKDIR /app

COPY --from=builder /app/app /app/app

COPY --from=builder /app/config.yaml /app/config.yaml

ENV GATUS_CONFIG_PATH=/app/config.yaml

EXPOSE 8080 

USER nonroot:nonroot

CMD ["/app/app"]






