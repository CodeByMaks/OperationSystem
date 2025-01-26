OUTPUT_FORMAT("binary")
SECTIONS
{
    . = 0x1000;
    
    .text :
    {
        kernel.o(.text)
        desktop.o(.text)
        window_system.o(.text)
        mouse_driver.o(.text)
    }
    
    .data :
    {
        kernel.o(.data)
        desktop.o(.data)
        window_system.o(.data)
        mouse_driver.o(.data)
    }
    
    .bss :
    {
        kernel.o(.bss)
        desktop.o(.bss)
        window_system.o(.bss)
        mouse_driver.o(.bss)
    }
}
