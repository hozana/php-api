docker run \
  --rm \
  -e SONAR_HOST_URL="https://sonarqube.hozana.org" \
  -v "./:/usr/src" \
  sonarsource/sonar-scanner-cli \
  -Dsonar.projectKey=hozana_php-api_AYnPNZCiK8WAZS0kN_A5 \
  -Dsonar.scm.provider=git \
  -Dsonar.token=sqp_a6dbb71b77c86d5979d0bd6e1cf31b00b9e8bdb3 \