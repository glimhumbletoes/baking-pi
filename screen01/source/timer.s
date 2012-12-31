

# Gets the address of the timer controller
# Parameters: 	(none)
# Returns: 	r0 - Address of the timer controller
# This doesn't need to be global
	GetTimerAddress:

		# move the timer address in to r0 and return.
		ldr r0, =0x20003000
		mov pc, lr




# Gets the current timer counter value (each tick represents 1 microsecond)
# Parameters: 	(none)
# Returns:	r0 - Counter (Low)
#		r1 - Counter (High)
.global GetTimerCounter
	GetTimerCounter:

		# push link register on to stack
		push { lr }
		
		# get the address of the timer controller and place this value 
		# in to timer_address. we need r0 for the return value.
		timer_address	.req r2
		bl GetTimerAddress
		mov timer_address, r0

		# the current timer is stored as 8 bytes, each GP register in ARM
		# is only 4 therefor load r0 with the counters low (least significant)
		# 4 bytes and r1 with the high (most significant) four bits. The timer 
		# counter starts at an offset of 4 bytes from the base timer controller.
		ldrd r0, r1, [timer_address, #4]
		.unreq timer_address

		# return to caller
		pop { pc }





# Returns after a given large duration (double) in microseconds (one millionth of a second).
# Parameters: 	r0 - Duration in microseconds (Low)
#		r1 - Duration in microseconds (High)
# Returns:	(none)
.global SleepDouble
	SleepDouble:

		push { r4, r5, lr }

		# we use r4 and r5 rather than r2 and r3 as the ARM ABI does not guarentee that these 
		# registers will not be changed during a function call. during this method we call 
		# GetTimerCounter (which respectively calls GetTimerAddress which we known will modify
		# the state of r0, r1 and r2. its best just to avoid them for these values.
		request_low	.req r4
		request_high	.req r5
	
		# move the values to a safe location
		mov request_low, r0
		mov request_high, r1
		current_low	.req r0
		current_high	.req r1

		# get the current time
		bl GetTimerCounter

		# calculate the number we need to wait for and replace the duration in r4/r5 with this:
		# we need to add two numbers spread across four registers, these are currently:
		#	r0 - Current Timer (low)
		#	r1 - Current timer (high)
		#	r4 - Duration (low)
		#	r5 - Duration (high)
		# we can discard the duration in r4/r5, because we want to replace this with the target
		# time. first we perfrorm an add, this becomes "adds", as the s postfix indicates that
		# this instruction should update the status register. specifically we need to know if the
		# addition of the least significant bits results in a carry. we then perform an adc or
		# "add with carry" which will add the value in r1, to the value in request_high, and add
		# the carry bit as well (if it is set).
		adds request_low, current_low
		adc request_high, current_high
		
		# check if the last addition resulted in an overflow - in which case I'm not too sure how
		# best to handle this; for now this is a minor consideration immediately bail.
		# b - branch : vs - condition (overflow flag set).
		bvs exit_sleep_double$

	wait_for_duration$:
	
		# MSB => most signficant 4 bytes
		# LSB => least signifcant 4 bytes
		# we now need to wait for one of the following conditions:
		#	condition #1: the current times MSB > the duration MSB
		#		OR
		#	condition #2: the current times MSB = the duration MSB and the current times LSB >= the duration LSB
	
		# check for condition #1
		cmp current_high, request_high
		bhi exit_sleep_double$

		# else check for condition #2 (note; if previous check is _lower_ then comparison will not be done, and b(hs)
		# will never be true, meaning we will wait for the higher bit to tally
		cmpeq current_low, request_low
		bhs exit_sleep_double$
	
		# update the timer and go again...
		bl GetTimerCounter
		b wait_for_duration$

		
	exit_sleep_double$:

		# clear all register aliases
		.unreq current_high
		.unreq current_low
		.unreq request_high
		.unreq request_low

		# pop modified registers and return
		pop { r4, r5, pc }

	



# Returns after a given duration in microseconds (one millionth of a second).
# Parameters: 	r0 - Duration in microseconds.
# Returns:	(none)
.global Sleep
	Sleep:

		push { lr }	
	
		# ensure the high (most signifcant) register is zero'd and 
		# then just pass though to the sleep double register method.
		mov r1, #0
		bl SleepDouble

		pop { pc }
