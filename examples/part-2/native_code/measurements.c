#include "measurements.h"

#include <math.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct {
  size_t count;
  double minimum;
  double maximum;
  double sum;
} accumulator_t;

struct measurement_session {
  accumulator_t accumulator;
};

const char *measurement_label(const measurement_t *measurement) {
  return measurement->label;
}

static int accumulate(accumulator_t *accumulator, const measurement_t *batch,
                      size_t count) {
  if (count == 0) {
    return SUMMARY_EMPTY;
  }
  if (batch == NULL || count > SIZE_MAX - accumulator->count) {
    return SUMMARY_INVALID;
  }

  // Commit the new totals only after validating the entire batch.
  accumulator_t next = *accumulator;
  for (size_t i = 0; i < count; ++i) {
    const double value = batch[i].value;
    next.sum += value;
    if (!isfinite(value) || !isfinite(next.sum)) {
      return SUMMARY_INVALID;
    }
    if (next.count == 0 || value < next.minimum) {
      next.minimum = value;
    }
    if (next.count == 0 || value > next.maximum) {
      next.maximum = value;
    }
    ++next.count;
  }
  *accumulator = next;
  return SUMMARY_OK;
}

static summary_t to_summary(const accumulator_t *accumulator) {
  return (summary_t){.count = accumulator->count,
                     .minimum = accumulator->minimum,
                     .maximum = accumulator->maximum,
                     .mean = accumulator->sum / (double)accumulator->count};
}

int summarize_into(const measurement_t *batch, size_t count, summary_t *out) {
  if (out == NULL) {
    return SUMMARY_INVALID;
  }
  accumulator_t accumulator = {0};
  const int status = accumulate(&accumulator, batch, count);
  if (status == SUMMARY_OK) {
    *out = to_summary(&accumulator);
  }
  return status;
}

summary_t *summarize(const measurement_t *batch, size_t count, int *status) {
  if (status == NULL) {
    return NULL;
  }
  summary_t result;
  *status = summarize_into(batch, count, &result);
  if (*status != SUMMARY_OK) {
    return NULL;
  }

  summary_t *owned = malloc(sizeof *owned);
  if (owned == NULL) {
    *status = SUMMARY_ALLOCATION_FAILED;
    return NULL;
  }
  *owned = result;
  return owned;
}

void summary_free(summary_t *summary) { free(summary); }

measurement_session_t *session_create(void) {
  measurement_session_t *session = malloc(sizeof *session);
  if (session != NULL) {
    *session = (measurement_session_t){0};
  }
  return session;
}

int session_add(measurement_session_t *session, const measurement_t *batch,
                size_t count) {
  if (session == NULL) {
    return SUMMARY_INVALID;
  }
  return accumulate(&session->accumulator, batch, count);
}

int session_summary(const measurement_session_t *session, summary_t *out) {
  if (session == NULL || out == NULL) {
    return SUMMARY_INVALID;
  }
  if (session->accumulator.count == 0) {
    return SUMMARY_EMPTY;
  }
  *out = to_summary(&session->accumulator);
  return SUMMARY_OK;
}

void session_free(measurement_session_t *session) { free(session); }
