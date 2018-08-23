#ifndef PIC_H
#define PIC_H

#include <types.h>

void irq_add(int irq, void (*handler)(struct regs_struct *regs));
void irq_remove(int irq);

extern void pic_init();

#endif