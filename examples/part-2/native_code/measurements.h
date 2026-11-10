#ifndef FFI_MEASUREMENTS_H
#define FFI_MEASUREMENTS_H

typedef struct measurement {
  const char *label;
  double value;
} measurement_t;

/* Borrowed UTF-8 string, valid only as long as the input label is alive. */
const char *measurement_label(const measurement_t *measurement);

#endif
