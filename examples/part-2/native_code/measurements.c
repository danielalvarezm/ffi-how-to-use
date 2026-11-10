#include "measurements.h"

#include <math.h>

const char *measurement_label(const measurement_t *measurement) {
  return measurement->label;
}

int summarize_into(const measurement_t *batch, size_t count, summary_t *out) {
  if (count == 0) {
    return SUMMARY_EMPTY;
  }
  if (batch == NULL || out == NULL) {
    return SUMMARY_INVALID;
  }

  double minimum = batch[0].value;
  double maximum = minimum;
  double sum = 0.0;
  for (size_t i = 0; i < count; ++i) {
    const double value = batch[i].value;
    sum += value;
    if (!isfinite(value) || !isfinite(sum)) {
      return SUMMARY_INVALID;
    }
    if (value < minimum) {
      minimum = value;
    }
    if (value > maximum) {
      maximum = value;
    }
  }

  *out = (summary_t){.count = count,
                     .minimum = minimum,
                     .maximum = maximum,
                     .mean = sum / (double)count};
  return SUMMARY_OK;
}
