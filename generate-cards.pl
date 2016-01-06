#!/usr/bin/perl -w

my %hash;

for ($family=0; $family <= 3; $family++) {
  for ($value=1; $value <= 13; $value++) {
    $hash{sprintf("%04b_%02b", $value, $family)} = 1;
  }
}

my @stack;
foreach my $val (keys %hash) {
  push (@stack, $val);
}

my $num_hidden = 6;
for ($stack = 13; $stack >= 7; $stack--) {
	for ($i = 0; $i < $num_hidden; $i++) {
		my $val = pop @stack;
		printf("  dw %04b_%s_0_%05bb\n", $stack, $val, $i);
	}
	my $val = pop @stack;
	printf("  dw %04b_%s_1_%05bb\n", $stack, $val, $num_hidden);
	$num_hidden--;
}

my $drawn = pop @stack;
printf("  dw 0001_%s_1_00000b\n", $drawn);

for ($i = 0; $i < 23; $i++) {
	my $val = pop @stack;
	printf("  dw 0000_%s_0_%05bb\n", $val, $i);

}
