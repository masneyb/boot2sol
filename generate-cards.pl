#!/usr/bin/perl -w

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

my %hash;

sub show_card {
  my $bits = shift;

  my ($pile, $card_value, $family, $shown, $pile_pos) = $bits =~ /^([01]{4})_([01]{4})_([01]{2})_([01])_([01]{5})/;
  my $key = $pile . "_" . $pile_pos;
  my $label = $card_values{$card_value} . $families{$family} . $shown_values{$shown};
  $hash{$key} = $label;
  printf("  dw %sb ; $label\n", $bits);
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

my $num_hidden = 6;
for (my $stack = 13; $stack >= 7; $stack--) {
	for ($i = 0; $i < $num_hidden; $i++) {
		my $val = pop @stack;
                show_card(sprintf("%04b_%s_0_%05b", $stack, $val, $i));
	}
	my $val = pop @stack;
	show_card(sprintf("%04b_%s_1_%05b", $stack, $val, $num_hidden));
	$num_hidden--;
}

my $drawn = pop @stack;
show_card(sprintf("0001_%s_1_00000", $drawn));

for (my $i = 0; $i < 23; $i++) {
	my $val = pop @stack;
	show_card(sprintf("0000_%s_0_%05b", $val, $i));
}

print "  ; Card positions. Cards with a + are shown.\n";
for (my $pile_pos = 0; $pile_pos < 23; $pile_pos++) {
  print "  ; ";
  for (my $stack = 0; $stack < 14; $stack++) {
    my $key = sprintf("%04b_%05b", $stack, $pile_pos);
    my $label = $hash{$key};
    $label = "   " if !defined ($label);
    print $label;
    print " ";
  }
  print "\n";
}

