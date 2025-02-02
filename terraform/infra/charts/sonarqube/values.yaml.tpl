community:
  enabled: true

postgresql:
  enabled: false

jdbcOverwrite:
  enabled: true
  jdbcUrl: "${rds_endpoint}"
  jdbcUsername: "${rds_username}"
  jdbcPassword: "${rds_password}"

service:
  type: ClusterIP
  externalPort: 9000
  internalPort: 9000

ingress:
  enabled: false

sonarProperties:
  sonar.web.context: "/sonarqube"

metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: monitoring

monitoringPasscode: "techchallenge-sonarqube-secret"