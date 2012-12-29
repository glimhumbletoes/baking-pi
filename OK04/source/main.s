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

		# well use r4 to keep the light state
		light_state	.req r4
		mov light_state, #0

	set_light_state$:

		# set the state on the LED by moving the GPIO pin for the LED (#16) in to
		# r0 and the current LED state in to r1
		mov r0, #16
		mov r1, light_state
		bl SetGpioPin

		# invert the light state for next iteration.
		mvn light_state, light_state

		# set r0 to the number of milliseconds to sleep (1,000,000ms = 1s), this
		# is entirely arbitrary - for now 1 second.
		ldr r0, =1000000
		bl Sleep

		# jump back to invert the current light state.
		b set_light_state$

		
