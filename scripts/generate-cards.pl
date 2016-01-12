#!/usr/bin/perl -w

my $end_ptr = "111111";

my @families = ( 'C', 'S', 'D', 'H' );
my @values = ( 'A', '2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K' );

# Put the cards in a hash to randomize the deck
my %card_hash;
for (my $family = 0; $family < 4; $family++) {
  for (my $value = 0; $value < 13; $value++) {
    my %v;
    $v{"label"} = $values[$value] . $families[$family];
    $card_hash{sprintf("%06b", ($family * 13) + $value)} = \%v;
  }
}

my %v;
$v{"label"} = "End of Pile";
$card_hash{$end_ptr} = \%v;

# Now create a stack for the deck
my @stack;
foreach my $val (keys %card_hash) {
  push (@stack, $val);
}

# Create the individual piles
my @pile_pointers;

my $last = pop @stack;
$pile_pointers[0] = $last;
for (my $i = 0; $i < 23; $i++) {
	my $val = pop @stack;
        $card_hash{$last}->{"shown"} = "0";
	$card_hash{$last}->{"next"} = $val;
	$last = $val;
}
$card_hash{$last}->{"shown"} = "1";
$card_hash{$last}->{"next"} = $end_ptr;

$last = pop @stack;
$pile_pointers[1] = $last;
$card_hash{$last}->{"shown"} = "1";
$card_hash{$last}->{"next"} = $end_ptr;

$pile_pointers[2] = $end_ptr;
$pile_pointers[3] = $end_ptr;
$pile_pointers[4] = $end_ptr;
$pile_pointers[5] = $end_ptr;
$pile_pointers[6] = $end_ptr;

my $num_hidden = 0;
for (my $stack = 7; $stack <= 13; $stack++) {
	$last = pop @stack;
	$pile_pointers[$stack] = $last;
	for (my $i = 0; $i < $num_hidden; $i++) {
		my $val = pop @stack;
	        $card_hash{$last}->{"shown"} = "0";
		$card_hash{$last}->{"next"} = $val;
		$last = $val;
	}
	$card_hash{$last}->{"shown"} = "1";
	$card_hash{$last}->{"next"} = $end_ptr;

	$num_hidden++;
}

print "\tfirst_card";
for (my $family = 0; $family < 4; $family++) {
  for (my $value = 0; $value < 13; $value++) {
    my $key = sprintf("%06b", ($family * 13) + $value);
    my $nextlabel = $card_hash{$card_hash{$key}->{"next"}}->{"label"};
    print "\tdb " . $card_hash{$key}->{"shown"} . "_0_" . $card_hash{$key}->{"next"} . "b ; Current Position=$key, Current Card=" . $card_hash{$key}->{"label"} . ", Next Card=$nextlabel";
    print ", Shown" if $card_hash{$key}->{"shown"} eq "1";
    print "\n";
  }
}

print "\n\tpile_pointers";
for ($i = 0; $i < 14; $i++) {
  print "\tdb " . $pile_pointers[$i] . "b ; Card=" . $card_hash{$pile_pointers[$i]}->{"label"};
  print ", Shown" if $card_hash{$pile_pointers[$i]}->{"shown"} eq "1";
  print "\n";
}

