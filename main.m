#include <stdio.h>
#import <Foundation/Foundation.h>
#import <mach-o/loader.h>
#import <mach-o/fat.h>
#import <sys/stat.h>
#import <version.h>

void printUsage(void)
{
	printf("Usage: slice_fixup <path/to/dylib>\n");
}

void removeSlice(NSString* binaryPath, cpu_type_t cputypeToRemove, cpu_subtype_t cpusubtypeToRemove)
{
	FILE* machoFile = fopen(binaryPath.fileSystemRepresentation, "rb+");
	if(!machoFile)
	{
		printf("ERROR: file %s does not exist\n", binaryPath.fileSystemRepresentation);
	}
	
	struct mach_header header;
	fread(&header,sizeof(header),1,machoFile);
	
	if(header.magic == FAT_MAGIC || header.magic == FAT_CIGAM)
	{
		fseek(machoFile,0,SEEK_SET);
		struct fat_header fatHeader;
		fread(&fatHeader,sizeof(fatHeader),1,machoFile);

		size_t fatTableSize = sizeof(struct fat_arch) * OSSwapBigToHostInt32(fatHeader.nfat_arch);
		char* newFatTable = malloc(fatTableSize);
		memset(&newFatTable[0], 0, fatTableSize);
		int newFatI = 0;
		
		for(int i = 0; i < OSSwapBigToHostInt32(fatHeader.nfat_arch); i++)
		{
			uint32_t archFileOffset = sizeof(fatHeader) + sizeof(struct fat_arch) * i;
			struct fat_arch fatArch;
			fseek(machoFile, archFileOffset,SEEK_SET);
			fread(&fatArch,sizeof(fatArch),1,machoFile);
			
			if(OSSwapBigToHostInt32(fatArch.cputype) != cputypeToRemove || OSSwapBigToHostInt32(fatArch.cpusubtype) != cpusubtypeToRemove)
			{
				memcpy(&newFatTable[sizeof(struct fat_arch) * newFatI], &fatArch, sizeof(struct fat_arch));
				newFatI++;
			}
		}

		if(OSSwapBigToHostInt32(fatHeader.nfat_arch) != newFatI)
		{
			fseek(machoFile,0,SEEK_SET);
			fatHeader.nfat_arch = OSSwapHostToBigInt32(newFatI);
			fwrite(&fatHeader, sizeof(fatHeader), 1, machoFile);
			fwrite(&newFatTable[0], fatTableSize, 1, machoFile);
		}

		free(newFatTable);
	}
	
	fclose(machoFile);
}

int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
		if(argc != 2)
		{
			printUsage();
			return 0;
		}

		NSString* dylibPath = [NSString stringWithUTF8String:argv[1]];

		cpu_type_t cputypeToRemove = 0x100000C;
		cpu_type_t cpusubtypeToRemove;
		if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_14_0)
		{
			cpusubtypeToRemove = 0x00000002;
		}
		else
		{
			cpusubtypeToRemove = 0x80000002;
		}

		removeSlice(dylibPath, cputypeToRemove, cpusubtypeToRemove);
		return 0;
	}
}
