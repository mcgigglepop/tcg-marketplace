# Build stage
FROM golang:1.23 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build the Go application (static binary)
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/web

# Final stage
FROM gcr.io/distroless/static
WORKDIR /app
COPY --from=builder /app/main .
COPY --from=builder /app/static ./static
COPY --from=builder /app/templates ./templates
EXPOSE 80
ENTRYPOINT ["./main"]
CMD ["-cache=false", "-production=false"]