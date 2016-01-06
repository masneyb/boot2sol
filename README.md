# boot2sol

A solitaire-based bootloader.

## NOTES: 1/6/2016

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