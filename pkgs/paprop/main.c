#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pulse/pulseaudio.h>

#define PA_CTX_NAME "paprop"

enum PAPROP_MODE {
  PAPROP_MODE_PROP = 0,
  PAPROP_MODE_MUTE = 1,
};

enum PAPROP_STATE {
  PAPROP_STATE_SEARCHING = 0,
  PAPROP_STATE_ABORT = 1,
  PAPROP_STATE_FOUND = 2,
};

typedef struct search_data search_data_t;

typedef void(*pa_info_cb_t) (pa_context* ctx, const void* info, int eol, search_data_t* data);
typedef pa_operation*(*pa_context_get_info_list_t) (pa_context* ctx, const pa_info_cb_t cb, search_data_t* data);
typedef const char*(*find_predicate_t) (const void* info, search_data_t* data);
typedef int(*mute_predicate_t) (const void* info, search_data_t* data);

typedef struct search_data {
  const char* name;
  const char* prop;
  enum PAPROP_MODE mode;
  enum PAPROP_STATE state;
  find_predicate_t predicate;
  mute_predicate_t mutepredicate;
} search_data_t;

void pa_state_cb(pa_context* ctx, void* userdata);
void pa_info_cb(pa_context* ctx, const void* info, int eol, search_data_t* data);
int find_prop(pa_context_get_info_list_t get_list, pa_info_cb_t cb, search_data_t* data);

void pa_state_cb(pa_context* ctx, void* userdata) {
  pa_context_state_t state;
  int* pa_ready = userdata;

  state = pa_context_get_state(ctx);
  switch (state) {
    case PA_CONTEXT_FAILED:
    case PA_CONTEXT_TERMINATED:
      *pa_ready = 2;
      break;
    case PA_CONTEXT_READY:
      *pa_ready = 1;
      break;
    case PA_CONTEXT_UNCONNECTED:
    case PA_CONTEXT_CONNECTING:
    case PA_CONTEXT_AUTHORIZING:
    case PA_CONTEXT_SETTING_NAME:
    default:
      break;
  }
}

void pa_info_cb(pa_context* ctx, const void* info, int eol, search_data_t* data) {
  // If eol is set to a positive number, we're at the end of the list
  if (eol > 0) return;

  switch (data->mode) {
    case PAPROP_MODE_PROP: {
      const char* value = data->predicate(info, data);
      if (value != NULL) {
        data->state = PAPROP_STATE_FOUND;
        printf("%s\n", value);
      }
      break;
    }
    case PAPROP_MODE_MUTE: {
      if (data->mutepredicate == NULL) {
        fprintf(stderr, "is-muted is not supported for this info type");
        data->state = PAPROP_STATE_ABORT;
      }
      int value = data->mutepredicate(info, data);
      if (value != -1) {
        data->state = PAPROP_STATE_FOUND;
        printf("%d\n", value);
      }
      break;
    }
  }
}

#define DEF_FIND_PROP_PREDICATE(info_name, info_type) \
  const char* find_##info_name##_prop_predicate(pa_##info_name##_info* info, search_data_t* data) { \
    if (strcmp(info->name, data->name) != 0) return NULL; \
    return pa_proplist_gets(info->proplist, data->prop); \
  }

DEF_FIND_PROP_PREDICATE(sink, pa_sink_info)
DEF_FIND_PROP_PREDICATE(source, pa_source_info)
DEF_FIND_PROP_PREDICATE(card, pa_card_info)

#define DEF_MUTE_PREDICATE(info_name, info_type) \
  int mute_##info_name##_predicate(info_type* info, search_data_t* data) { \
    if (strcmp(info->name, data->name) != 0) return -1; \
    return info->mute; \
  }

DEF_MUTE_PREDICATE(sink,pa_sink_info);
DEF_MUTE_PREDICATE(source,pa_sink_info);

int find_prop(pa_context_get_info_list_t get_list, pa_info_cb_t cb, search_data_t* data) {
  pa_mainloop* pa_ml;
  pa_mainloop_api* pa_mlapi;
  pa_operation* pa_op;
  pa_context* pa_ctx;

  int retval = 0;
  int state = 0;
  int pa_ready = 0;

  pa_ml = pa_mainloop_new();
  pa_mlapi = pa_mainloop_get_api(pa_ml);
  pa_ctx = pa_context_new(pa_mlapi, PA_CTX_NAME);

  pa_context_connect(pa_ctx, NULL, 0, NULL);

  pa_context_set_state_callback(pa_ctx, pa_state_cb, &pa_ready);

  while (1) {
    // Wait for PA to be ready
    if (pa_ready == 0) {
      pa_mainloop_iterate(pa_ml, 1, NULL);
      continue;
    }

    // Exit out if we couldn't connect to the PA server
    if (pa_ready == 2) {
      retval = -1;
      goto free;
    }

    switch (state) {
      case 0:
        pa_op = get_list(
          pa_ctx,
          cb,
          data
        );
        state++;
        break;
      case 1:
        if (pa_operation_get_state(pa_op) != PA_OPERATION_DONE && data->state == PAPROP_STATE_SEARCHING) {
          break;
        }

        if (data->state != PAPROP_STATE_SEARCHING) {
          pa_operation_cancel(pa_op);
        }

        pa_operation_unref(pa_op);
        goto free;
      default:
        // We should never see this state
        fprintf(stderr, "in state %d\n", state);
        retval = -1;
        goto exit;
    }

    pa_mainloop_iterate(pa_ml, 1, NULL);
  }

free:
  pa_context_disconnect(pa_ctx);
  pa_context_unref(pa_ctx);
  pa_mainloop_free(pa_ml);
exit:
  return retval;
}

int main(int argc, char* argv[]) {
  if (argc < 4) {
    fprintf(stderr, "invalid argument count\n");
    return 1;
  }

  const char* op = argv[1];
  const char* type = argv[2];
  const char* name = argv[3];
  const char* prop = NULL;

  search_data_t data = {
    .name = name,
    .prop = prop,
    .mode = PAPROP_MODE_PROP,
    .state = PAPROP_STATE_SEARCHING,
  };
  if (strcmp(op, "is-muted") == 0) {
    if (argc != 4) {
      fprintf(stderr, "invalid argument count\n");
      return 1;
    }
    data.mode = PAPROP_MODE_MUTE;
  } else if (strcmp(op, "get-prop") == 0) {
    if (argc != 5) {
      fprintf(stderr, "invalid argument count\n");
      return 1;
    }
    data.mode = PAPROP_MODE_PROP;
    data.prop = argv[4];
  } else {
    fprintf(stderr, "unexpected op type: %s\n", op);
    return 1;
  }

  int err = 0;
  if (strcmp(type, "sink") == 0) {
    data.predicate = (find_predicate_t)find_sink_prop_predicate;
    data.mutepredicate = (mute_predicate_t)mute_sink_predicate;
    err = find_prop((pa_context_get_info_list_t)pa_context_get_sink_info_list, pa_info_cb, &data);
  } else if (strcmp(type, "source") == 0) {
    data.predicate = (find_predicate_t)find_source_prop_predicate;
    data.mutepredicate = (mute_predicate_t)mute_source_predicate;
    err = find_prop((pa_context_get_info_list_t)pa_context_get_source_info_list, pa_info_cb, &data);
  } else if (strcmp(type, "card") == 0) {
    data.predicate = (find_predicate_t)find_card_prop_predicate;
    data.mutepredicate = NULL;
    err = find_prop((pa_context_get_info_list_t)pa_context_get_card_info_list, pa_info_cb, &data);
  } else {
    fprintf(stderr, "unexpected info type: %s\n", type);
    err = 1;
  }

  if (err) return err;
  if (data.state != PAPROP_STATE_FOUND) return 1;
  return 0;
}
