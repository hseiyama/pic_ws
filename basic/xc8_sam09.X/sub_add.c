#include <xc.h>

// **** add ************************
unsigned char add(unsigned char a) {
	return a + 1;
}

// **** add2 ***********************
unsigned int add2(unsigned int b, unsigned int c) {
	unsigned int temp2;
	temp2 = b + c;
	return temp2;
}

// **** add3 ***********************
unsigned int __reentrant add3(unsigned int d, unsigned int e) {
	unsigned int temp3;
	temp3 = d + e;
	return temp3;	
}
