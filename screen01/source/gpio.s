
# Gets the address of the GPIO register.
# Parameters: 	(none)
# Returns: 	r0 - Address of the GPIO controller
.global GetGpioAddress
	GetGpioAddress:

		# move the GPIO address in to r0 and return.
		ldr r0, =0x20200000
		mov pc, lr





# Sets the function of a GPIO pin
# Parameters: 	r0 - Pin to set state on.
#	      	r1 - State to assign pin.
# Returns:	(none)
.global SetGpioPinFunction
	SetGpioPinFunction:
	
		# verify pin and function are within an acceptable range.
		cmp r0, #53
		cmpls r1, #7
		movhi pc, lr
	
		# safely store lr so we can make a method call, move out
		# the pin from r0 to make sure its not overwritten by 
		# return value of GetGpioAddress
		push { r4, lr }
		mov r2, r0
		bl GetGpioAddress

	pin_to_block$:

		# there are 54 pins, the GPIO functions are stored in blocks of 10.
		# the following loop determines what block our pin is in.
		
		# compare the value in r2 to 9
		cmp r2, #9

		# if its greater than 9 then the pin isn't in this block as such
		# increment the the GPIO controller address in r0 by four to move
		# to the next block, and reduce the pin identifier in r2 by 10 to 
		# check the next block
		subhi r2, #10
		addhi r0, #4

		# if we didn't find the block; repeat
		bhi pin_to_block$

		# r0 now contains the address of the block that we need to adjust. 
		# r2 on the other hand contains the pin offset within this block
		# that we need to adjust.

		# each pin in this block has three status bits so to determine the 
		# correct bit offset we need to multiply the value in r2 value by three. 
		# multiplication is slow therefore  we logical-shift-left by 1 (equiv. to 
		# multiply by two) and then add the value again.
		add r2, r2, lsl #1

		# the three bits that actually set the state of the pin are still in 
		# r1. to push this to the right location we now logical-shift-left
		# the value in r1 by the appropriate amount of bits (in r2 as discussed)
		lsl r1, r2

		# create a mask we can use to turn off all the bits currently set for this pin
		mov r3, #7 
		lsl r3, r2
		mvn r3, r3

		# load the current value of the GPIO pin setup in to a register and turn
		# off all the state bits for the pin we are updating the value of.
		ldr r4, [r0]
		and r4, r3

		# merge the changed state for this pin with the current state for all other pins.
		orr r1, r4

		# push the new state in to the GPIO controller and return.
		str r1, [r0]
		pop { r4, pc }

	



# Either turns on or off a GPIO pin
# Parameters:	r0 - GPIO pin number
#		r1 - Set to on if zero, else off.
# Returns:	(none)
.global SetGpioPin
	SetGpioPin:

		# set some register labels for legibility		
		pin_number 	.req r2
		pin_state	.req r1

		
		# make sure the pin number is valid.
		mov pin_number, r0
		cmp pin_number, #53
		movhi pc, lr

		# store return address on the stack
		push { lr }

		# get the GPIO address
		gpio_address 	.req r0
		bl GetGpioAddress

		# to turn pins on or off the GPIO controller has two sets of four bytes. the first set 
		# of each controls the first 32 pins, the second the remaining 22 pins. we need to determine
		# which byte our pin is in.
		pin_byte 	.req r3

		# first we logical shift right by 5 bits (equiv. modulus by 32 / loose remainder), this tells 
		# us if we are in the first set (pin is less than 32 and the value is zero), or the second set
		# (pin is greater than 32 and the value is one). We then multiply this by four (logical shift 
		# left #2) to determine the offset from the GPIO conotroller to target the correct bank. 
		lsr pin_byte, pin_number, #5
		lsl pin_byte, #2	

		# finally add this to the GPIO controller to it now points at the correct bank.
		add gpio_address, pin_byte
		.unreq pin_byte

		# determine what bit to set (0-31 are in 0-31 of first byte, or 0-21 of second byte). The AND
		# operation ensures that only the bit offset we require is left in the register. [gpio_address]
		# already knows what byte block we are addressing.
		set_bit		.req r3
		and pin_number, #31
		mov set_bit, #1
		lsl set_bit, pin_number

		# determine if we are turning the pin on or off.
		teq pin_state, #0
		.unreq pin_state

		# do the actual setting of the bit in question
		# if state was zero, turn on the pin
		streq set_bit, [gpio_address, #40]
		strne set_bit, [gpio_address, #28]
		.unreq gpio_address
		.unreq set_bit

		# return to the caller
		pop { pc }

