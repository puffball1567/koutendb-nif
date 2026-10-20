#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "koutendb_nif.h"
#include "rochedb_nif.h"

#ifdef KOUTENDB_NIF_DYNAMIC_LOAD
#include <windows.h>

typedef int (*kouten_nif_to_bif_fn)(const void *, size_t, void **, size_t *);
typedef int (*kouten_bif_to_nif_fn)(const void *, size_t, void **, size_t *);
typedef int (*kouten_validate_bif_fn)(const void *, size_t);
typedef void (*kouten_nif_free_fn)(void *);
typedef const char *(*kouten_nif_last_error_fn)(void);

static kouten_nif_to_bif_fn p_kouten_nif_to_bif;
static kouten_nif_to_bif_fn p_roche_nif_to_bif;
static kouten_bif_to_nif_fn p_kouten_bif_to_nif;
static kouten_bif_to_nif_fn p_roche_bif_to_nif;
static kouten_validate_bif_fn p_kouten_validate_bif;
static kouten_validate_bif_fn p_roche_validate_bif;
static kouten_nif_free_fn p_kouten_nif_free;
static kouten_nif_free_fn p_roche_nif_free;
static kouten_nif_last_error_fn p_kouten_nif_last_error;
static kouten_nif_last_error_fn p_roche_nif_last_error;

#define kouten_nif_to_bif p_kouten_nif_to_bif
#define roche_nif_to_bif p_roche_nif_to_bif
#define kouten_bif_to_nif p_kouten_bif_to_nif
#define roche_bif_to_nif p_roche_bif_to_nif
#define kouten_validate_bif p_kouten_validate_bif
#define roche_validate_bif p_roche_validate_bif
#define kouten_nif_free p_kouten_nif_free
#define roche_nif_free p_roche_nif_free
#define kouten_nif_last_error p_kouten_nif_last_error
#define roche_nif_last_error p_roche_nif_last_error

static void load_koutendb_nif(void) {
  HMODULE lib = LoadLibraryA("koutendb_nif.dll");
  assert(lib != NULL);
  p_kouten_nif_to_bif =
      (kouten_nif_to_bif_fn)GetProcAddress(lib, "kouten_nif_to_bif");
  p_kouten_bif_to_nif =
      (kouten_bif_to_nif_fn)GetProcAddress(lib, "kouten_bif_to_nif");
  p_kouten_validate_bif =
      (kouten_validate_bif_fn)GetProcAddress(lib, "kouten_validate_bif");
  p_kouten_nif_free =
      (kouten_nif_free_fn)GetProcAddress(lib, "kouten_nif_free");
  p_kouten_nif_last_error =
      (kouten_nif_last_error_fn)GetProcAddress(lib, "kouten_nif_last_error");
  p_roche_nif_to_bif = (kouten_nif_to_bif_fn)GetProcAddress(lib, "roche_nif_to_bif");
  assert(p_roche_nif_to_bif != NULL);
  assert(p_kouten_nif_to_bif != NULL);
  p_roche_bif_to_nif = (kouten_bif_to_nif_fn)GetProcAddress(lib, "roche_bif_to_nif");
  assert(p_roche_bif_to_nif != NULL);
  assert(p_kouten_bif_to_nif != NULL);
  p_roche_validate_bif = (kouten_validate_bif_fn)GetProcAddress(lib, "roche_validate_bif");
  assert(p_roche_validate_bif != NULL);
  assert(p_kouten_validate_bif != NULL);
  p_roche_nif_free = (kouten_nif_free_fn)GetProcAddress(lib, "roche_nif_free");
  assert(p_roche_nif_free != NULL);
  assert(p_kouten_nif_free != NULL);
  p_roche_nif_last_error = (kouten_nif_last_error_fn)GetProcAddress(lib, "roche_nif_last_error");
  assert(p_roche_nif_last_error != NULL);
  assert(p_kouten_nif_last_error != NULL);
}
#else
static void load_koutendb_nif(void) {}
#endif

int main(void) {
  load_koutendb_nif();

  const char *nif = "(record@5,3,file.nim title@2,0#field# \"KoutenDB\"@4,0)";
  void *bif = NULL;
  size_t bif_len = 0;
  assert(kouten_nif_to_bif(nif, strlen(nif), &bif, &bif_len) == 0);
  assert(bif != NULL && bif_len > 0);

  void *decoded = NULL;
  size_t decoded_len = 0;
  assert(kouten_validate_bif(bif, bif_len) == 0);
  assert(kouten_bif_to_nif(bif, bif_len, &decoded, &decoded_len) == 0);
  assert(decoded_len == strlen(nif));
  assert(memcmp(decoded, nif, decoded_len) == 0);
  kouten_nif_free(decoded);

  void *bad_out = (void *)0x1;
  size_t bad_len = 999;
  assert(kouten_bif_to_nif("not-bif", 7, &bad_out, &bad_len) != 0);
  assert(bad_out == NULL);
  assert(bad_len == 0);
  assert(strstr(kouten_nif_last_error(), "invalid BIF") != NULL);
  assert(kouten_validate_bif("not-bif", 7) != 0);
  assert(strstr(kouten_nif_last_error(), "invalid BIF") != NULL);

  bad_out = (void *)0x1;
  bad_len = 999;
  assert(kouten_nif_to_bif(NULL, 1, &bad_out, &bad_len) != 0);
  assert(bad_out == NULL);
  assert(bad_len == 0);
  assert(strstr(kouten_nif_last_error(), "input pointer is nil") != NULL);

  assert(kouten_nif_to_bif(nif, strlen(nif), NULL, &bad_len) != 0);
  assert(strstr(kouten_nif_last_error(), "output pointers are required") != NULL);

  assert(kouten_bif_to_nif(bif, bif_len, &decoded, NULL) != 0);
  assert(strstr(kouten_nif_last_error(), "output pointers are required") != NULL);

  assert(kouten_bif_to_nif(bif, bif_len, &decoded, &decoded_len) == 0);
  assert(kouten_nif_last_error()[0] == '\0');
  kouten_nif_free(decoded);
  kouten_nif_free(bif);

  bif = NULL;
  bif_len = 0;
  assert(kouten_nif_to_bif(NULL, 0, &bif, &bif_len) == 0);
  assert(bif != NULL && bif_len > 0);
  assert(kouten_bif_to_nif(bif, bif_len, &decoded, &decoded_len) == 0);
  assert(decoded == NULL && decoded_len == 0);
  kouten_nif_free(decoded);
  kouten_nif_free(bif);

  const char nul_nif[] = "\"a\\00b\"";
  bif = NULL;
  bif_len = 0;
  assert(kouten_nif_to_bif(nul_nif, sizeof(nul_nif) - 1, &bif, &bif_len) == 0);
  assert(kouten_bif_to_nif(bif, bif_len, &decoded, &decoded_len) == 0);
  assert(decoded_len == sizeof(nul_nif) - 1);
  assert(memcmp(decoded, nul_nif, decoded_len) == 0);
  kouten_nif_free(decoded);
  kouten_nif_free(bif);

  /* Both ABI names accept current NIF syntax and share memory/error state. */
  const char *current = "(record 0xFF 0b1111_1111u 1_000 \"key: #value\")";
  const char *canonical = "(record 255 255u 1000 \"key\\3A \\23value\")";
  assert(roche_nif_to_bif(current, strlen(current), &bif, &bif_len) == 0);
  assert(roche_validate_bif(bif, bif_len) == 0);
  assert(kouten_bif_to_nif(bif, bif_len, &decoded, &decoded_len) == 0);
  assert(decoded_len == strlen(canonical));
  assert(memcmp(decoded, canonical, decoded_len) == 0);
  roche_nif_free(decoded);
  assert(roche_bif_to_nif(bif, bif_len, &decoded, &decoded_len) == 0);
  assert(decoded_len == strlen(canonical));
  assert(memcmp(decoded, canonical, decoded_len) == 0);
  kouten_nif_free(decoded);
  roche_nif_free(bif);
  assert(roche_validate_bif("not-bif", 7) != 0);
  assert(strstr(roche_nif_last_error(), "invalid BIF") != NULL);
  assert(strcmp(roche_nif_last_error(), kouten_nif_last_error()) == 0);
  assert(kouten_nif_to_bif("(ok)", 4, &bif, &bif_len) == 0);
  assert(roche_nif_last_error()[0] == '\0');
  kouten_nif_free(bif);

  puts("koutendb-nif C ABI contract passed");
  return 0;
}
