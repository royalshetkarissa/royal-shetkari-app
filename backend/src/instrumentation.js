const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const logger = require('./utils/logger');

/**
 * Initialize OpenTelemetry Distributed Tracing.
 */
const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    // URL for Jaeger or Honeycomb OTLP endpoint
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318/v1/traces',
  }),
  instrumentations: [getNodeAutoInstrumentations()],
  serviceName: 'royal-shetkari-backend',
});

if (process.env.ENABLE_TRACING === 'true') {
  sdk.start();
  logger.info('🔭 OpenTelemetry Tracing initialized');
}

process.on('SIGTERM', () => {
  sdk
    .shutdown()
    .then(() => logger.info('Tracing terminated'))
    .catch((error) => logger.error('Error terminating tracing', error))
    .finally(() => process.exit(0));
});

module.exports = sdk;
