.section .init


#
# IMPORTANT:
#	please note that for OK05 to work you must make modifications to either the linker script
#	or the config.txt; as this is not covered in the site content I have modified the linker
#	script so that this code should work "as is" (i.e. with the normal "make" and copy and 
#	paste method).
#
#	if you are doing this yourself and are looking for solutions try placing kernel_old=1 in the
#	config.txt file on you SD card before looking at my solution.
#
#	newer versions of the boot loader copy kernel.img to 0x8000 rather than 0x0000. setting 
#	kernel_old=1 will force the kernel.img to be copied to 0x0000 as before. To fix this in the
#	linker you need to change the layout such that the .init section is mapped to 0x8000.
#	you should also move the .text section as this is currently mapped to 0x8000.
#


# Start of the operating system
.global _start
	_start:

		# we have to jump over address 0x100 which is used during boot up by ATAGs. 
		# (ATAG's: parameters passed from bootloader to kernel)
		b main


.section .text


	main:

		# move the stack pointer to a new location
		mov sp, #0x8000

		# set the function  on the GPIO pin #16 to #1 (output)
		mov r0, #16
		mov r1, #1
		bl SetGpioPinFunction

		# load pattern data in to register
		pattern_data	.req r4
		ldr pattern_data, =pattern
		ldr pattern_data, [pattern_data]

		# initialize register to keep track of pattern index
		pattern_sequence .req r5
		mov pattern_sequence, #0
		
	set_light_state$:
		
		# update r1 such that it will be zero if the light should be on according to the sequence, or 
		# *some other* number if the light should be out.
		mov r1, #1
		lsl r1, pattern_sequence
		and r1, pattern_data

		# set the state on the LED by moving the GPIO pin for the LED (#16) in to
		# r0 and the current LED state in to r1
		mov r0, #16
		bl SetGpioPin

		# wait for a small moment (1/10th second)
		ldr r0, =250000
		bl Sleep

		# increment the pattern sequence, the "and" ensures that the value does not escape
		# the first 5 bits aeffectively constraining pattern_sequence between 0 and 31
		add pattern_sequence, #1
		and pattern_sequence, #31

		# jump back to invert the current light state.
		b set_light_state$


# Data section
.section .data
.align 4
pattern:
	.int 0b11111111101010100010001000101010
		
