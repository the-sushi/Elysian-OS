#!/bin/bash

#Config variables
PLATFORM="x86"
CCPLATFORM="i386"
BINLOC="$HOME/i386elfgcc/bin" #location of compiliation tools
CC="$BINLOC/$CCPLATFORM-elf-gcc"
LD="$BINLOC/$CCPLATFORM-elf-ld"
CCFLAGS="-D ARCH=$PLATFORM -Wall -O -fstrength-reduce -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./libk/include -I./arch/$PLATFORM/include -c"

red=`tput setaf 1`
green=`tput setaf 2`
clr=`tput sgr0`

if [ "$1" = "clean" ]
then
	rm Kernel.bin OS.iso iso/boot/Kernel.bin out.bochs &> /dev/null
	echo "${green}Done cleaning!"
	exit 0
fi

asm()
{
	nasm $1.asm -f elf32 -o $1.o
	linkfiles="$linkfiles $1.o"
}


echo "${green}Building kernel for platform $PLATFORM${clr}"
cd src/kernel/


#NASM commands
echo "boot.asm -> boot.o"
asm arch/$PLATFORM/boot
echo "pic.asm -> pic.o"
asm arch/$PLATFORM/pic
echo "idt_helper.asm -> idt_helper.o"
asm arch/$PLATFORM/idt_helper
echo "blink.asm -> blink.o"
asm arch/$PLATFORM/blink


#CC commands
echo "start.c -> start.o"
$BINLOC/$CCPLATFORM-elf-gcc start.c $CCFLAGS -o start.o
linkfiles="$linkfiles start.o"


echo -e "${green}\nCompiling libk${clr}"
for file in libk/*.c
do
	object=${file/".c"/}".o"
	echo "$file -> $object"
	$CC $file $CCFLAGS -o $object
	linkfiles="$linkfiles $object"
done

for file in arch/$PLATFORM/*.c
do
	object=${file/".c"/}".o"
	echo "$file -> $object"
	$CC $file -mgeneral-regs-only $CCFLAGS -o $object
	linkfiles="$linkfiles $object"
done

echo -e "${green}\nLinking object files...${clr}"
$BINLOC/$CCPLATFORM-elf-ld -T arch/$PLATFORM/link.ld -o Kernel.bin $linkfiles -z max-page-size=4096 --nmagic

#Clean up
echo -e "${green}\nCleaning up...${clr}"
mv Kernel.bin ../..
rm $linkfiles

#make iso
echo -e "${green}\nMaking iso...${clr}"
cd ../..
cp -p Kernel.bin iso/boot/
grub-mkrescue -o OS.iso iso &> /dev/null

echo -e "${green}\n*** Done! ***${clr}\n"