# Gets the address of the base addess of the communication mailbox 
# Parameters: 	(none)
# Returns: 	r0 - Base address of the mailbox
# This doesn't need to be global
	GetMailboxAddress:

		#
		# note: this is not documented publically by broadcomm and 
		#   has apparently been largely reversed from existing 
		#   source code in the linux kernel:
		#	http://elinux.org/RPi_Framebuffer
		#

		# move the mailbox base address in to r0 and return.
		ldr r0, =0x2000b880
		mov pc, lr





# Reads a message from the mailbox on the specified channel
# Parameters:	r0 - Channel to read from
# Returns:	r0 - Message read from channel
.global MailboxRead
	MailboxRead:
		
		# make sure the channel is in an acceptable range (whilst the 
		# tutorial talks of being seven channels other references such as
		# https://github.com/raspberrypi/firmware/wiki/Mailboxes seem to
		# indicate there are more, which would tally with the fact that 
		# four bits are reserved for the channel rather than three. Also
		# as this is not publically documented I thought it safer to
		# check the mask bits rather than the range 
		cmp r0, #0xF
		movhi pc, lr

		push { lr }

		# store the channel to read to a safe register.
		# (no method calls in this block touch r3).
		channel_to_read	.req r3		
		mov channel_to_read, r0

		# store the base address of the mailbox
		mailbox_address	.req r1
		bl GetMailboxAddress
		mov mailbox_address, r0	

	wait_for_read_status_bit$:

		generic_buffer	.req r0

		# get status and check if we can read yet
		ldr generic_buffer, [mailbox_address, #0x18]
		tst generic_buffer, #0x40000000

		# and repeat if we are not ready.
		bne wait_for_read_status_bit$

		# go and fetch the message from the mailbox
		ldr generic_buffer, [mailbox_address]
		
		# and then check if this message was for the channel that we
		# are interested in; guess for now we can safely ignore others
		and r2, generic_buffer, #0xF
		teq r2, channel_to_read

		# continue waiting if this message was not for us
		bne wait_for_read_status_bit$
	
		# turns out; having the recieving channel in all messages
		# is a bit of a nusience. trim it off.
		and generic_buffer, #0xFFFFFFF0
	
		.unreq generic_buffer
		.unreq channel_to_read
		.unreq mailbox_address
		pop { pc }





# Write a message to the mailbox for a given channel
# Parameters:	r0 - Content to write
#		r1 - Channel to write message to
# Returns:	(none)
.global MailboxWrite
	MailboxWrite:


		# first we need to check that both parameters sit in appropriate 
		# bit fields, we can check the first with a cmp, and the second
		# we use tst (and) to ensure bits are not set were bits ought not be
		cmp  r1, #0xF
		movhi pc, lr		
		tst r0, #0xF
		movne pc, lr

		# parameters are OK. merge into a single message and pop this
		# somewhere safe, good point to trap lr to before some calls
		message_to_write	.req r3
		add message_to_write, r1, r0
		push { lr }

		# store the base address of the mailbox
		mailbox_address	.req r1
		bl GetMailboxAddress
		mov mailbox_address, r0	

	wait_for_write_status_bit$:

		# get status and check if we can write yet
		ldr r0, [mailbox_address, #0x18]
		tst r0, #0x80000000

		# and repeat if we are not ready.
		bne wait_for_write_status_bit$

		# write messsage to box
		str message_to_write, [mailbox_address, #0x20]
		
		.unreq message_to_write
		.unreq mailbox_address

		pop { pc }
