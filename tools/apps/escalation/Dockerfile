FROM golang:1.26.10-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/escalation .

FROM gcr.io/distroless/static:nonroot
COPY --from=build /out/escalation /escalation
USER 65532:65532
EXPOSE 8080
ENTRYPOINT ["/escalation"]
