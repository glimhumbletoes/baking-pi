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

		# flag bit 16 (GPIO pin attached to the LED) and write out to the address space
		# to turn the pin on (#40; #28 to turn off).
		mov r1, #1
		lsl r1, #16
		str r1, [r0, #40]


	loop$:	# and loop forever to prevent CPU run off.
		b loop$

		
