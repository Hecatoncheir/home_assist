#!/usr/bin/env bash
# Версия приложения для установщиков: из тега vX.Y.Z, иначе из pubspec.yaml.
set -euo pipefail

if [[ "${GITHUB_REF_TYPE:-}" == "tag" && "${GITHUB_REF_NAME:-}" == v* ]]; then
  echo "${GITHUB_REF_NAME#v}"
else
  sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml
fi
