.section .init
.global _start

	_start:

		# store the address of the GPIO controller in r0
		# address provided is physical address, reference material uses bus addressing.
		ldr r0,=0x20200000

		# enable output to the pin that we want to turn off, by enabling its control bit 
		# in the GPIO controller. 
		mov r1, #1
		lsl r1, #18
		str r1, [r0, #4]

		# in order to turn off the LED we use signal 28, to allow toggling of the LED we'll 
		# buffer this value in r10, we'll load #40 in to r11 which is used to turn the LED on
		mov r10, #28
		mov r11, #40

	set_light_state$:

		# flag bit 16 (GPIO pin attached to the LED) and write out to the address space
		# to turn the pin on or off (uses r10 as offset; see above for details).
		mov r1, #1
		lsl r1, #16
		str r1, [r0, r10]
		
		# perform an XOR byte swap so that next time the code runs the on / off offset
		# has been changed to the other value.
		eors r10, r11
		eors r11, r10
		eors r10, r11

		# reload the wait buffer
		mov r2, #0x3F0000

	poor_mans_wait$:
		
		# wait for an arbitrary duration and then toggle the light state.		
		sub r2, #1
		cmp r2, #0
		bne poor_mans_wait$
		b set_light_state$

		
