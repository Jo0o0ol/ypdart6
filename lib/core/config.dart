const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

const inactivityTimeoutSeconds = int.fromEnvironment(
  'INACTIVITY_SECONDS',
  defaultValue: 180,
);

const inactivityWarningSeconds = int.fromEnvironment(
  'INACTIVITY_WARNING_SECONDS',
  defaultValue: 30,
);

const maxSessionMinutes = int.fromEnvironment(
  'MAX_SESSION_MINUTES',
  defaultValue: 30,
);
