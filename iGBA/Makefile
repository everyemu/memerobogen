CC = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin10-gcc-4.2.1
CXX = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin10-gcc-4.2.1
#CC = /dat/pre/bin/arm-apple-darwin9-gcc
LD = /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin10-gcc-4.2.1
VERSION = 4.3
LDFLAGS = -lobjc \
	        -lpthread \
          -framework CoreFoundation \
          -framework Foundation \
          -framework UIKit \
          -framework QuartzCore \
          -framework CoreGraphics \
          -framework CoreSurface \
          -framework CoreLocation \
          -framework AudioToolbox \
          -framework GraphicsServices \
          -framework OpenGLES \
          ./iphone/libSDLiPhoneOS.a -lz

# -framework AddressBook -lAdMobDeviceNoThumb3_0 -lsqlite3 -framework SystemConfiguration 

CFLAGS	= -F/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${VERSION}.sdk/System/Library/Frameworks -F/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${VERSION}.sdk/System/Library/PrivateFrameworks -I../../ -I../../Classes/ -I../../Classes/AdMob/ -I../../Classes/IOKit -I/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk/usr/lib/gcc/arm-apple-darwin10/4.2.1/include -isysroot /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${VERSION}.sdk  -L/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS${VERSION}.sdk/usr/lib -I./iphone/SDL -march=armv6 -mcpu=arm1176jzf-s -DARM_ARCH -DGP2X_BUILD -miphoneos-version-min=3.0 -O3 -fnested-functions -funsigned-char -ffast-math -ftemplate-depth-36 -mstructure-size-boundary=32 -falign-functions=32 -falign-loops -falign-labels -falign-jumps -finline -finline-functions -fno-builtin -fno-common -fomit-frame-pointer 
# -L../../Classes/AdMob/ -L../../Classes/AdMob/ARM/
#-maspen-version-min=2.0 
#-miphoneos-version-min=2.0 
#-fpeel-loops -falign-functions -fweb -fstrength-reduce -fexpensive-optimizations -finline -finline-functions -DVERSION='"$(VERSION)"'
#-mcpu=arm1176jzf-s -fpeel-loops
#-msoft-float
#-fstrict-aliasing -funroll-loops -fstrength-reduce -fpeel-loops

all:	gpSPhone

#iphone/video_blend.o 
#../../Classes/AdMob/AltAds.o

gpSPhone: iphone/video_blend.o iphone/gpSPhone/src/iphone.o ../../main.o ../../Classes/NowPlayingController.o ../../Classes/helpers.o   ../../Classes/OptionsController.o ../../Classes/RecentController.o ../../Classes/RomController.o ../../Classes/SaveStatesController.o ../../Classes/ShoutOutAppDelegate.o ../../Classes/SOApplication.o ../../Classes/TabBar.o ../../Classes/WebBrowserViewController.o ../../Classes/BTDevice.o ../../Classes/BTInquiryViewController.o ../../Classes/iCade/iCadeReaderView.o ../../Classes/Ads/AltAds.o iphone/arm_stub_c.o iphone/font.o iphone/display.o cheats.o zip.o unzip.o ioapi.o fileio.o main.o cpu.o sound.o input.o memory.o video.o iphone/arm_asm_stub.o cpu_threaded.o   
	$(LD) $(CFLAGS) $(LDFLAGS) -o $@ $^
	ldid -S $@

%.o:	%.m
	$(CC) ${CFLAGS} -fstrict-aliasing -funroll-loops -fstrength-reduce -fpeel-loops -std=c99 -c $< -o $@

%.o:	%.cpp
	$(CXX) ${CFLAGS} -fstrict-aliasing -funroll-loops -fstrength-reduce -fpeel-loops -std=c99 -c $< -o $@

%.o:	%.c
	$(CC) ${CFLAGS} -fstrict-aliasing -funroll-loops -fstrength-reduce -fpeel-loops -std=c99 -c $< -o $@

%.o:	%.S
	$(CC) ${CFLAGS} -fstrict-aliasing -funroll-loops -fstrength-reduce -fpeel-loops -c $< -o $@

cpu_threaded.o:	cpu_threaded.c
	$(CC) ${CFLAGS} -std=c99 -c $< -o $@

memory.o:	memory.c
	$(CC) ${CFLAGS} -fstrict-aliasing -fstrength-reduce -fpeel-loops -std=c99 -c $< -o $@

cpu.o:	cpu.c
	$(CC) ${CFLAGS} -fstrict-aliasing -std=c99 -c $< -o $@

clean:
	rm -f ./*.o iphone/*.o ../../*.o ../../Classes/*.o iphone/gpSPhone/*.o iphone/gpSPhone/src/*.o gpSPhone src/*.gch
	rm -rf ./build
