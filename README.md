# boot2sol

Solitaire. Written inside the bootloader.

## Overview
As part of Move Inc.'s Startup Hackathon, 2016, our team decided to write
solitaire within a bootloader. The goal is to boot a PC with a traditional BIOS
(no EFI) into an interactive game of solitaire.

## Team Members
* Brian Sizemore - [@bpsizemore](/bpsizemore)
* Brian Masney - [@masneyb](/masneyb)
* Will Austin - [@dreae](/dreae)
* Ricky Hussmann - [@rhussmann](/rhussmann)

## Technical Requirements
* Must be written in 16-bit x86 assembly language
* Program code and data must fit on a single sector on disk
  * 512 bytes total
  * Last 2 bytes is the boot sector signature
  * Only **510 bytes** total to initialize
* System running in real mode; no memory production available
* Limited tooling available for debugging issues
* Requires detailed knowledge of x86 architecture

## Development Toolchain
* Developed in Linux
  * Brian M. and Will used Fedora natively
  * Brian S. used Fedora under Virtualbox
  * Ricky H. used Ubuntu under VMWare
* NASM used for assembly
* mkdosfs creating the boot floppy
* QEMU for virtulizing the hardware


## Design
There are thirteen piles in solitaire:
* The draw pile
* The discard pile
* A pile for each completed suit (four piles)
* Seven play piles

We included another pile, the space between the discard pile and the suit piles.
This pile is never added to or drawn from, but its existence simplifies the
implementation. So, boot2sol recognizes a total of 14 piles, zero indexed.

The representation of each card uses two bytes:

Family | Unused | Card Value | Shown | Next
-------|--------|------------|-------|-----
2 bits | 2 bits | 4 bits     | 1 bit | 7 bits

## Development Notes, for historical purposes

### NOTES: 1/6/2016

Will and I spent a little time trying to figure out what was going on with the
execution of the program.

We noticed we were never incrementing the pile number in the next_stack display
column number in the next_stack function. Will is adding functionality to space
columns out by four spaces in the next_stack function (add dh, 4).

Additionally, after making this change we noticed every third column appears
to print out correctly. The intermediate columns print the correct number of
cards (except column 8), but the values are incorrect.

We also noticed that instructions that should be equivalent don't appear to be.
For example, in the next_stack function, change inc register to add regsiter, 1.
The output from the program is different, but only for certain cards. Possibly
because instruction are different sizes causing memory or alignment problems?

No idea.

### Ricky's Notes: 1/6/2016 - 20:38
Found a spot where we were using a literal 52 instead of literal
104. Also, there was an off-by-one error for the number of lower
piles in a comparison. Fixed that as we well.

With these modifications, the lower pile is almost all correct.
However, there are a couple cards at the top of the pile that are
pulled as "the space of clubs." Other than that, the rest of the
pile appears correct!
