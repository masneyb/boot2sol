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

## Ricky's Notes: 1/6/2016 - 20:38
Found a spot where we were using a literal 52 instead of literal
104. Also, there was an off-by-one error for the number of lower
piles in a comparison. Fixed that as we well.

With these modifications, the lower pile is almost all correct.
However, there are a couple cards at the top of the pile that are
pulled as "the space of clubs." Other than that, the rest of the
pile appears correct!