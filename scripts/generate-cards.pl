#!/usr/bin/perl -w

my $end_ptr = "1111111";

my %families;
$families{"11"} = "H";
$families{"10"} = "D";
$families{"01"} = "S";
$families{"00"} = "C";

my %card_values;
$card_values{"0001"} = "A";
$card_values{"0010"} = "2";
$card_values{"0011"} = "3";
$card_values{"0100"} = "4";
$card_values{"0101"} = "5";
$card_values{"0110"} = "6";
$card_values{"0111"} = "7";
$card_values{"1000"} = "8";
$card_values{"1001"} = "9";
$card_values{"1010"} = "T";
$card_values{"1011"} = "J";
$card_values{"1100"} = "Q";
$card_values{"1101"} = "K";

my %shown_values;
$shown_values{"1"} = "+";
$shown_values{"0"} = " ";

my $current_card_index = 0;

sub show_card {
  my ($value, $shown, $next_ptr, $debug) = @_;

  my ($card_value, $family) = $value =~ /^([01]{4})_([01]{2})/;
  my $label = $card_values{$card_value} . $families{$family} . $shown_values{$shown} . $debug . " - " . sprintf("%07b", $current_card_index);

  print "  dw " . $family . "_0_0_" . $card_value . "_" . $shown . "_" . $next_ptr . "b ; $label\n";
  $current_card_index += 2;
}


my %card_value_family_hash;

for (my $family=0; $family <= 3; $family++) {
  for (my $value=1; $value <= 13; $value++) {
    $card_value_family_hash{sprintf("%04b_%02b", $value, $family)} = 1;
  }
}

my @stack;
foreach my $val (keys %card_value_family_hash) {
  push (@stack, $val);
}

print "first_card";

my @pile_pointers;
$pile_pointers[0] = "00000000";

for (my $i = 0; $i < 23; $i++) {
	my $val = pop @stack;

	my $debug = '';
	$debug = " - Top of deck stack" if $i == 0;

	my $next_ptr;
	my $shown;
	if ($i == 22) {
		$shown = "1";
		$next_ptr = $end_ptr;
       	}
	else {
		$shown = "0";
		$next_ptr = sprintf("%07b", $current_card_index + 2);
	}

	show_card($val, $shown, $next_ptr, $debug);
}

$pile_pointers[1] = sprintf("%07b", $current_card_index);
my $drawn = pop @stack;
show_card($drawn, "1", $end_ptr, " - Drawn card");

$pile_pointers[2] = $end_ptr;
$pile_pointers[3] = $end_ptr;
$pile_pointers[4] = $end_ptr;
$pile_pointers[5] = $end_ptr;
$pile_pointers[6] = $end_ptr;

my $num_hidden = 0;
for (my $stack = 7; $stack <= 13; $stack++) {
	$pile_pointers[$stack] = sprintf("%07b", $current_card_index);
	for ($i = 0; $i < $num_hidden; $i++) {
		my $debug = "";
		$debug = " - Beginning of stack $stack" if $i == 0;
		my $val = pop @stack;
		my $next_ptr = sprintf("%07b", $current_card_index + 2);
		show_card($val, "0", $next_ptr, $debug);
	}

	my $debug = "";
	$debug = " - Beginning of stack $stack" if $num_hidden == 0;

	my $val = pop @stack;
	show_card($val, "1", $end_ptr, $debug);
	$num_hidden++;
}

print "\npile_pointers";
for ($i = 0; $i < 14; $i++) {
  print "  db " . $pile_pointers[$i] . "b\n";
}

