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

typedef struct measurement_session measurement_session_t;
typedef void (*batch_accepted_callback_t)(size_t batch_count, size_t total_count);

/* Borrowed UTF-8 string, valid only as long as the input label is alive. */
const char *measurement_label(const measurement_t *measurement);

/* Write to caller-owned memory on success. Never retain the input array. */
int summarize_into(const measurement_t *batch, size_t count, summary_t *out);

/* Status is required. The result is NULL on error, otherwise owned by C. */
summary_t *summarize(const measurement_t *batch, size_t count, int *status);
void summary_free(summary_t *summary);

/* C owns the handle until session_free. Creation returns NULL on failure. */
measurement_session_t *session_create(void);
/* Keep only aggregate values. On error, leave the session unchanged.
 * On success, invoke a non-NULL callback once on the calling thread.
 * Never retain the batch or callback. Do not reenter or free this session
 * from the callback.
 */
int session_add(measurement_session_t *session, const measurement_t *batch,
                size_t count, batch_accepted_callback_t on_accepted);
/* Write to caller-owned memory. Return SUMMARY_EMPTY before the first batch. */
int session_summary(const measurement_session_t *session, summary_t *out);
void session_free(measurement_session_t *session);

#endif
