#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "rochedb_nif.h"

#ifdef ROCHEDB_NIF_DYNAMIC_LOAD
#include <windows.h>

typedef int (*roche_nif_to_bif_fn)(const void *, size_t, void **, size_t *);
typedef int (*roche_bif_to_nif_fn)(const void *, size_t, void **, size_t *);
typedef int (*roche_validate_bif_fn)(const void *, size_t);
typedef void (*roche_nif_free_fn)(void *);
typedef const char *(*roche_nif_last_error_fn)(void);

static roche_nif_to_bif_fn p_roche_nif_to_bif;
static roche_bif_to_nif_fn p_roche_bif_to_nif;
static roche_validate_bif_fn p_roche_validate_bif;
static roche_nif_free_fn p_roche_nif_free;
static roche_nif_last_error_fn p_roche_nif_last_error;

#define roche_nif_to_bif p_roche_nif_to_bif
#define roche_bif_to_nif p_roche_bif_to_nif
#define roche_validate_bif p_roche_validate_bif
#define roche_nif_free p_roche_nif_free
#define roche_nif_last_error p_roche_nif_last_error

static void load_rochedb_nif(void) {
  HMODULE lib = LoadLibraryA("rochedb_nif.dll");
  assert(lib != NULL);
  p_roche_nif_to_bif =
      (roche_nif_to_bif_fn)GetProcAddress(lib, "roche_nif_to_bif");
  p_roche_bif_to_nif =
      (roche_bif_to_nif_fn)GetProcAddress(lib, "roche_bif_to_nif");
  p_roche_validate_bif =
      (roche_validate_bif_fn)GetProcAddress(lib, "roche_validate_bif");
  p_roche_nif_free =
      (roche_nif_free_fn)GetProcAddress(lib, "roche_nif_free");
  p_roche_nif_last_error =
      (roche_nif_last_error_fn)GetProcAddress(lib, "roche_nif_last_error");
  assert(p_roche_nif_to_bif != NULL);
  assert(p_roche_bif_to_nif != NULL);
  assert(p_roche_validate_bif != NULL);
  assert(p_roche_nif_free != NULL);
  assert(p_roche_nif_last_error != NULL);
}
#else
static void load_rochedb_nif(void) {}
#endif

int main(void) {
  load_rochedb_nif();

  const char *nif = "(record@5,3,file.nim title@2,0#field# \"RocheDB\"@4,0)";
  void *bif = NULL;
  size_t bif_len = 0;
  assert(roche_nif_to_bif(nif, strlen(nif), &bif, &bif_len) == 0);
  assert(bif != NULL && bif_len > 0);

  void *decoded = NULL;
  size_t decoded_len = 0;
  assert(roche_validate_bif(bif, bif_len) == 0);
  assert(roche_bif_to_nif(bif, bif_len, &decoded, &decoded_len) == 0);
  assert(decoded_len == strlen(nif));
  assert(memcmp(decoded, nif, decoded_len) == 0);
  roche_nif_free(decoded);

  void *bad_out = (void *)0x1;
  size_t bad_len = 999;
  assert(roche_bif_to_nif("not-bif", 7, &bad_out, &bad_len) != 0);
  assert(bad_out == NULL);
  assert(bad_len == 0);
  assert(strstr(roche_nif_last_error(), "invalid BIF") != NULL);
  assert(roche_validate_bif("not-bif", 7) != 0);
  assert(strstr(roche_nif_last_error(), "invalid BIF") != NULL);

  bad_out = (void *)0x1;
  bad_len = 999;
  assert(roche_nif_to_bif(NULL, 1, &bad_out, &bad_len) != 0);
  assert(bad_out == NULL);
  assert(bad_len == 0);
  assert(strstr(roche_nif_last_error(), "input pointer is nil") != NULL);

  assert(roche_nif_to_bif(nif, strlen(nif), NULL, &bad_len) != 0);
  assert(strstr(roche_nif_last_error(), "output pointers are required") != NULL);

  assert(roche_bif_to_nif(bif, bif_len, &decoded, NULL) != 0);
  assert(strstr(roche_nif_last_error(), "output pointers are required") != NULL);

  assert(roche_bif_to_nif(bif, bif_len, &decoded, &decoded_len) == 0);
  assert(roche_nif_last_error()[0] == '\0');
  roche_nif_free(decoded);
  roche_nif_free(bif);

  bif = NULL;
  bif_len = 0;
  assert(roche_nif_to_bif(NULL, 0, &bif, &bif_len) == 0);
  assert(bif != NULL && bif_len > 0);
  assert(roche_bif_to_nif(bif, bif_len, &decoded, &decoded_len) == 0);
  assert(decoded == NULL && decoded_len == 0);
  roche_nif_free(decoded);
  roche_nif_free(bif);

  const char nul_nif[] = "\"a\\00b\"";
  bif = NULL;
  bif_len = 0;
  assert(roche_nif_to_bif(nul_nif, sizeof(nul_nif) - 1, &bif, &bif_len) == 0);
  assert(roche_bif_to_nif(bif, bif_len, &decoded, &decoded_len) == 0);
  assert(decoded_len == sizeof(nul_nif) - 1);
  assert(memcmp(decoded, nul_nif, decoded_len) == 0);
  roche_nif_free(decoded);
  roche_nif_free(bif);

  puts("rochedb-nif C ABI contract passed");
  return 0;
}
