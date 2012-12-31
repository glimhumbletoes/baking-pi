# Initializes the display for a given resolution
# Parameters: 	r0 - Resoltuion -> Width
#		r1 - Resolution -> Height
#		r2 - Bit Depth
# Returns:	r0 - Pointer to Framebuffer, 0 on failure.
.global InitializeDisplay
	InitializeDisplay:
		
		# don't want to constrain the resolution so can't
		# effectively bounds box this - we'll have to rely
		# on the GPU telling us if the request is obscene,
		# we can however check that the bit depth is acceptable
		cmp r2, #32
		movhi r0, #0
		movhi pc, lr

		push { r4, lr }

		# update the frame buffer with the caller configuration
		# map frame_buffer in to r4 to ensure it persists 
		# across function calls.
		frame_buffer	.req r4
		ldr frame_buffer, =FrameBufferConfiguration 		
		str r0, [frame_buffer, #0]
		str r0, [frame_buffer, #8]
		str r1, [frame_buffer, #4]
		str r1, [frame_buffer, #12]
		str r2, [frame_buffer, #20]

		# send message to GPU
		mov r0, frame_buffer
		mov r1, #1
		bl MailboxWrite
		
		# wait for the GPU to write back telling us the result
		mov r0, #1
		bl MailboxRead
	
		# the GPU will write back with OK (zero) on success. 
		# error states are reported with an appropriate error 
		# number. unfortunatly this isn't publically available so
		# translating the error numbers back to something meaningful
		# would be a bit of a challenge
		teq r0, #0
		movne r0, #0
		popne { r4, pc }

	wait_for_framebuffer$:

		# keep reading the pointer to the frame buffer until we are
		# given one. apparently this isn't always immediate.
		ldr r0, [frame_buffer, #32]
		teq r0, #0
		beq wait_for_framebuffer$

		# we have a framebuffer - copy the address of the framebuffer
		# configuration structure in to r0 and return.
		mov r0, frame_buffer	
		.unreq frame_buffer

		pop { r4, pc }
