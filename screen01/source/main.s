.section .init

# Start of the operating system
.global _start
	_start:

		# technically we are already now mapped to 0x8000 because of the revised
		# linker script, kept this to keep format with the tutorials
		b main


.section .text


	main:

		# move the stack pointer to a new location
		mov sp, #0x8000

		# setup screen parameters (resolution and bit depth)
		mov r0, #1024
		mov r1, #768
		mov r2, #16

		# call to initialize display
		bl InitializeDisplay
	
		# make sure screen was initialized, we expect it to return a pointer to the
		# screen configuration structure. a null return is interpreted as failure.
		teq r0, #0
		beq error_in_main$

		# store the address of the frame buffer configuration structure
		frame_buffer_info 	.req r4	
		frame_buffer_px 	.req r3
		mov frame_buffer_info, r0
				
	render$:
		
		# get the address of the first pixel in the frame buffer
		ldr frame_buffer_px, [frame_buffer_info, #32]
		
		# reserve registeres for x, y and colour information.
		colour	.req r0
		y	.req r1
		x	.req r2

		# refill the y register
		mov y, #768
		
	draw_row$:

		# refill the x register		
		mov x, #1024
	
	draw_pixel$:

		# strh differs from str by only writing half a word rather than a full one
		# (a word being the standard size of the CPU registers, in this case 32bit)
		# which means we only write 16 bits (the bit-depth we requested) to the 
		# address of the current pixel... tldr; set the colour of the pixel.
		strh colour, [frame_buffer_px]

		# add two bytes to the address (2x8=16bits) to step to the next pixel
		add frame_buffer_px, #2

		# subtract one from the column (x) tracker, and if we are not at the end of
		# the row yet keep repeat until we are.
		sub x, #1
		teq x, #0
		bne draw_pixel$
		
		# next row, change colour and decrement the row tracker (y), and if we are not
		# and the end of the screen yet keep repeating until we are.
		add colour, #1
		sub y, #1
		teq y, #0
		bne draw_row$
		
		# end of the screen - start the whole process again.
		b render$

		#
		# Normal code execution never gets here - stuck in continuous render$ loop.
		# below is code we use to handle error states in initializtion.


	error_in_main$:

		# something has gone wrong - turn on OK led to signal this.
		bl TurnOnOKLED		

		# and then wait forever....

	wait_forever$:
		b wait_forever$
		
	
	TurnOnOKLED:
		
		push { lr }
	
		# set GPIO pin 16 to output	
		mov r0, #16
		mov r1, #1
		bl SetGpioPinFunction

		# set ouput off to pin 16 (whichs turns the LED *on*)
		mov r0, #16
		mov r1, #0
		bl SetGpioPin

		pop { pc }
