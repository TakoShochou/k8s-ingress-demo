FROM scratch

ARG EXE
EXPOSE 8080

COPY ${EXE} /app.exe
CMD ["/app.exe"]
