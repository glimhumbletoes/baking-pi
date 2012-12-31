.section .data
.align 12

# Configuration information for the system frame buffer
.global FrameBufferConfiguration
	FrameBufferConfiguration:

/* 0ffset  | W/R | description                          |    type	value  */
/* (+4)  0 | W/- | Physical resolution -> Width(px)     |*/ .int	1024 
/* (+4)  4 | W/- | Physical resolution -> Height(px)    |*/ .int	768
/* (+4)  8 | W/- | Virtual framebuffer -> Width(px)     |*/ .int	1024
/* (+4) 12 | W/- | Virutal framebuffer -> Height(px)    |*/ .int	768
/* (+4) 16 | -/R | GPU pitch (Bytes between rows)       |*/ .int	0
/* (+4) 20 | W/- | Bit depth (Bits per pixel)           |*/ .int	16
/* (+4) 24 | W/- | X offset of virtual framebuffer      |*/ .int	0
/* (+4) 28 | W/- | Y offset of virtual framebuffer      |*/ .int	0
/* (+4) 32 | -/R | Address of resulting framebuffer     |*/ .int	0
/* (+4) 36 | -/R | Size of resulting frameebuffer       |*/ .int	0
