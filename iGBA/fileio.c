#include "zip.h"
#include "unzip.h"
#include <stdio.h>
#include <string.h>

int load_archive(const char *filename, const char *entry,
		char *buffer, int *file_size)
{
    int size = 0;
	char max_name[256];
    unsigned char *buf = NULL;
	unzFile *fd = NULL;
	unz_file_info info;
	int ret = 0;
	 
	/* Attempt to open the archive */
	fd = unzOpen(filename);
	if(!fd)
	{
		return (0);
	}

	/* Go to first file in archive */
	if (entry != NULL)
		strcpy(max_name, entry);
	else {
		ret = unzGoToFirstFile(fd);

		for (; ret == UNZ_OK; ret = unzGoToNextFile(fd)) {
			char name[256];
			ret = unzGetCurrentFileInfo(fd, &info,
					name, sizeof(name), NULL, 0, NULL, 0);
			if (ret != UNZ_OK)
				break;

			if (size < info.uncompressed_size) {
				size = info.uncompressed_size;
				strcpy(max_name, name);
			}
		}
		if ((ret != UNZ_OK && ret != UNZ_END_OF_LIST_OF_FILE) || size == 0) {
			unzClose(fd);
			return 0;
		}
	}

	ret = unzLocateFile(fd, max_name, 1);
	if(ret != UNZ_OK) {
		unzClose(fd);
		return 0;
	}
	unzGetCurrentFileInfo(fd, &info, NULL, 0, NULL, 0, NULL, 0);

	/* Allocate file data buffer */
	size = info.uncompressed_size;
	if(size>*file_size)
	{
	   unzClose(fd);
	   return (0);
	}
	buf = buffer;

	/* Open the file for reading */
	ret = unzOpenCurrentFile(fd);
	if (ret != UNZ_OK) {
		unzClose(fd);
		return 0;
	}

	/* Read (decompress) the file */
	ret = unzReadCurrentFile(fd, buf, info.uncompressed_size);
	if(ret != info.uncompressed_size)
	{
		//free(buf);
		unzCloseCurrentFile(fd);
		unzClose(fd);
		return (0);
	}

	/* Close the current file */
	ret = unzCloseCurrentFile(fd);
	if(ret != UNZ_OK)
	{
		//free(buf);
		unzClose(fd);
		return (0);
	}

	/* Close the archive */
	ret = unzClose(fd);
	if(ret != UNZ_OK)
	{
		//free(buf);
		return (0);
	}

	/* Update file size and return pointer to file data */
	*file_size = size;
	return (1);
}

int save_archive(const char *filename, const char *entry,
		const char *buffer, int size)
{
    zipFile *fd = NULL;
    int ret = 0;
    //fd=zipOpen(filename, APPEND_STATUS_ADDINZIP);
    //if(!fd)
       fd=zipOpen(filename, APPEND_STATUS_CREATE);
    if(!fd)
    {
       return (0);
    }
    ret=zipOpenNewFileInZip(fd, entry,
			    NULL,
                            NULL,0,
			    NULL,0,
			    NULL,
			    Z_DEFLATED,
			    Z_DEFAULT_COMPRESSION);
			    
    if(ret != ZIP_OK)
    {
       zipClose(fd,NULL);
       return (0);    
    }
	
    ret=zipWriteInFileInZip(fd,buffer,size);
    if(ret != ZIP_OK)
    {
      zipCloseFileInZip(fd);
      zipClose(fd,NULL);
      return (0);
    }
	
    ret=zipCloseFileInZip(fd);
    if(ret != ZIP_OK)
    {
      zipClose(fd,NULL);
      return (0);
    }
	
    ret=zipClose(fd,NULL);
    if(ret != ZIP_OK)
    {
      return (0);
    }
	
    return(1);
}
