#ifndef FFI_MEASUREMENTS_H
#define FFI_MEASUREMENTS_H

#include <stddef.h>

#define SUMMARY_OK 0
#define SUMMARY_EMPTY 1
#define SUMMARY_INVALID 2
#define SUMMARY_ALLOCATION_FAILED 3

typedef struct measurement {
  const char *label;
  double value;
} measurement_t;

typedef struct summary {
  size_t count;
  double minimum;
  double maximum;
  double mean;
} summary_t;

/* Borrowed UTF-8 string, valid only as long as the input label is alive. */
const char *measurement_label(const measurement_t *measurement);

/* Write to caller-owned memory on success. Never retain the input array. */
int summarize_into(const measurement_t *batch, size_t count, summary_t *out);

/* Status is required. The result is NULL on error, otherwise owned by C. */
summary_t *summarize(const measurement_t *batch, size_t count, int *status);
void summary_free(summary_t *summary);

#endif
