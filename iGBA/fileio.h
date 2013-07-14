#ifndef _FILEIO_H_
#define _FILEIO_H_

#ifdef __cplusplus
extern "C" {
#endif

int load_archive(const char *filename, const char *entry,
		char *buffer, int *file_size);
int save_archive(const char *filename, const char *entry,
		const char *buffer, int size);
#endif /* _FILEIO_H_ */

#ifdef __cplusplus
} // End of extern "C"
#endif

