// sharc_fin.h

//bit masks
#define WDEN0         0x0001
#define WDEN1         0x0002
#define H1F0_EN       0x0010
#define H2F0_EN       0x0020
#define H3F0_EN       0x0040
#define H4F0_EN       0x0080

#define B_H1F0        0x0001
#define B_H1F1        0x0002
#define B_H2F0        0x0004
#define B_H2F1        0x0008
#define B_H3F0        0x0010
#define B_H3F1        0x0020
#define B_H4F0        0x0040
#define B_H4F1        0x0080
#define B_PCFLG       0x0100
#define B_PMCFLG0     0x0200
#define B_PMCFLG1     0x0400
#define B_PRFLG       0x0800
#define B_UART0       0x1000
#define B_UART1       0x2000

//registers
#define ADDR_OVRRIDE  0x40	//Address Override Register
#define STATUS_REG    0x41	//Status Register (R/O)	
#define PBUS_CFG_REG  0x42	//Pbus Configuration Register	
#define WDOG_CFG_REG  0x43	//WatchDog Config Register (WORM)	
#define PMCA_CFG_REG  0x44	//PMCA Config Register	
#define PMCB_STAT_REG 0x45	//PMCB Status Register (unimplemented)	
#define OB_I2C_CTL    0x46	//Onboard I2C Control Register	
#define PMC_I2C_CTL   0x47	//PMC I2C Control Register	
#define SD_SIZE_CFG   0x48	//SD Size Config Register	
#define SD_CONFIG_WD  0x49	//SD Config Word Register	
#define SD_WINDOW_REG 0x4A	//SD Window Register	
#define MAX3100       0x4B	//MAX3100 Uart Reg
#define RESERVED0     0x4C	//Unused
#define RESERVED1     0x4D	//Unused
#define RESERVED2     0x4E	//Unused
#define RESERVED3     0x4F	//Unused
// INT MUX
#define HH1_IRQ0      0x50  //HH1_IRQ0 map to flags
#define HH1_IRQ1      0x51  //HH1_IRQ1 map to flags
#define HH2_IRQ0      0x52  //HH2_IRQ0 map to flags
#define HH2_IRQ1      0x53  //HH2_IRQ1 map to flags
#define HH3_IRQ0      0x54  //HH3_IRQ0 map to flags
#define HH3_IRQ1      0x55  //HH3_IRQ1 map to flags
#define HH4_IRQ0      0x56  //HH4_IRQ0 map to flags
#define HH4_IRQ1      0x57  //HH4_IRQ1 map to flags
#define HH_PCINT      0x58	//PCInt
#define RESERVED4     0x59	//Unused
#define HH_PMCI0      0x5A	//PMCI0
#define HH_PMCI1      0x5B	//PMCI1
#define RESERVED5     0x5C	//Unused
#define RESERVED6     0x5D	//Unused
#define HH_FLAGS      0x5E	//Flgs
#define HH_IRQ        0x5F	//Irq
