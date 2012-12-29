.section .init
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

		mov r1, #0

	set_light_state$:

		# set the state on the LED
		mov r0, #16
		bl SetGpioPin


		# invert state of r1
		mvn r1, r1

		# reload the wait buffer
		mov r2, #0x3F0000

	poor_mans_wait$:
		
		# wait for an arbitrary duration and then toggle the light state.		
		sub r2, #1
		cmp r2, #0
		bne poor_mans_wait$
		b set_light_state$

		
