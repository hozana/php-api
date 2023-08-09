docker run \
  --rm \
  -e SONAR_HOST_URL="https://sonarqube.hozana.org" \
  -v "./:/usr/src" \
  sonarsource/sonar-scanner-cli \
  -Dsonar.projectKey=hozana_php-api_AYnPNZCiK8WAZS0kN_A5 \
  -Dsonar.scm.provider=git \
  -Dsonar.token= \
