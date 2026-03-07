FROM dart:stable AS build
WORKDIR /app

COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get
RUN dart pub global activate dart_frog_cli
RUN dart pub global run dart_frog_cli:dart_frog build

FROM dart:stable
WORKDIR /app

COPY --from=build /app/build ./

RUN dart pub get

ENV PORT=8080
EXPOSE 8080

CMD ["dart", "run", "bin/server.dart"]
