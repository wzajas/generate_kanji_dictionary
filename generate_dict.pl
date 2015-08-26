#!/usr/bin/perl -w
use utf8;
use XML::LibXML;
use strict;
use warnings;

#Avoid "Wide character in print"
use open ':std', ':encoding(UTF-8)';

#Radicals
open RADFILE, '<:encoding(UTF-8)', 'kangxi_raidcals' or die "kangxi_radicals not found\n";

my %radicals;
my $radical_idx;

while (<RADFILE>){
 chomp;
 next if /^#/;
 $radical_idx = (split / /)[0];
 my $radical = (split / /)[1];
 $radicals{$radical_idx}={ 'Radical' => $radical,
  'Type' => 'Radical',
  'Meaning' => '' 
 };
}
close RADFILE;


my $parser = XML::LibXML->new(validation => 1, load_ext_dtd => 1, complete_attributes => 1, no_blanks => 1);

my $doc = $parser->parse_file('kanjidic2.xml');

my %characters;
my $character_idx=1;

foreach my $character ($doc->findnodes('/kanjidic2/character')) {
 my ($kanji) = $character->findnodes('./literal');

 my @ja_kun = map { $_->to_literal } $character->findnodes('./reading_meaning/rmgroup/reading[@r_type="ja_kun"]');

 my @ja_on = map { $_->to_literal } $character->findnodes('./reading_meaning/rmgroup/reading[@r_type="ja_on"]');

 my @meaning = map { $_->to_literal } $character->findnodes('./reading_meaning/rmgroup/meaning[not(@m_lang)]');

 my @radicals = map { $_->to_literal } $character->findnodes('./radical/rad_value[@rad_type="classical"]');

 #Escape double quotes for sqlite import
 foreach(@meaning) {
  s/"/""/g;
 }

 $characters{$kanji->to_literal}= {
  'ID' => $character_idx++,
  'Kun' => join(', ', @ja_kun),
  'On' => join(', ', @ja_on),
  'Meaning' => join(', ', @meaning),
 };

 $characters{$kanji->to_literal}{Radicals} = \@radicals;

}

#"Parts" radicals
open RADFILE, '<:encoding(UTF-8)', 'kradfile-u' or die "kradfile-u not found\n";

while (<RADFILE>){
 chomp;
 next if /^#/;
 my @radicals = split / /, (split / : /)[1];
 my $character = (split / : /)[0];
 for (@radicals) {
  $radicals{++$radical_idx}={ 'Radical' => $_,
   'Type' => 'Part',
   'Meaning' => '' 
  };
  push(@{$characters{$character}{Radicals}}, $radical_idx);
 }
}
close RADFILE;


$doc = $parser->parse_file('JMdict');

my $word_idx=1;
my %words;

foreach my $entry ( $doc->findnodes('/JMdict/entry') ) {
 my %characterwords;
 my @meaning = ();
 my @current_words = ();
 my @hiragana = ();

 foreach my $word ( $entry->findnodes('./k_ele/keb') ) {
  push(@current_words, $word_idx);
  my %current_characters = ();
  $words{$word_idx} = { 'Word' => $word->to_literal, 'Length' => length($word->to_literal), };
  for (split(//, $word->to_literal)) {
   if(defined $characters{$_}) {
    $current_characters{$_}=1;
    $characters{$_}{Words}{$word_idx}=1;
   }
  }
  $words{$word_idx}{Character_Count} = scalar keys %current_characters;
  $word_idx++;
 }

 foreach my $reading ( $entry->findnodes('./r_ele/reb') ) {
  push(@hiragana, $reading->to_literal);
 }

 for (@current_words) {
  @{$words{$_}{Hiragana}} = @hiragana;
 }

 foreach my $gloss ( $entry->findnodes('./sense/gloss[@xml:lang="eng"]') ) {
  (my $g = $gloss->to_literal ) =~ s/"/""/g;
  for (@current_words) {
   push(@{$words{$_}{Glossary}}, $g);
  }
 }

}

for my $radical_idx (keys %radicals) {
  $radicals{$radical_idx}{Meaning} = $characters{$radicals{$radical_idx}{Radical}}{Meaning}  if defined($characters{$radicals{$radical_idx}{Radical}});
}

open RADICALS, '>', 'RADICALS_IMPORT' or die "Couldn't open RADICALS_IMPORT";
open KANJI, '>', 'KANJI_IMPORT' or die "Couldn't open KANJI_IMPORT";
open KANJIRADICALS, '>', 'KANJIRADICALS_IMPORT' or die "Couldn't open KANJIRADICALS_IMPORT";
open WORDS, '>', 'WORDS_IMPORT' or die "Couldn't open WORDS_IMPORT";
open KANJIWORDS, '>', 'KANJIWORDS_IMPORT' or die "Couldn't open KANJIWORDS_IMPORT";

for my $radical (keys %radicals) {
 print RADICALS join '|',
  $radical,
  $radicals{$radical}{Radical},
  $radicals{$radical}{Type},
  qq /"$radicals{$radical}{Meaning}"/;
 print RADICALS "\n";
}

for my $idx (keys %words ) {
  print WORDS join '|',
   $idx,
   (map { qq /"$_"/ } $words{$idx}{Word},
   join('; ',@{$words{$idx}{Hiragana}}),
   join('; ',@{$words{$idx}{Glossary}})),
   $words{$idx}{Length},
   $words{$idx}{Character_Count};
  print WORDS "\n";
}

for my $character (keys %characters) {

 print KANJI join '|',
  $characters{$character}{ID}, $character,
  map { qq /"$characters{$character}{$_}"/ } 'On', 'Kun', 'Meaning';
 print KANJI "\n";

 for (@{$characters{$character}{Radicals}}) {
  print KANJIRADICALS $characters{$character}{ID}."|".$_."\n";
 }

 for my $word_idx (keys %{$characters{$character}{Words}}) {
   print KANJIWORDS join '|',
    $characters{$character}{ID},
    $word_idx;
   print KANJIWORDS "\n";
 }
}

close RADICALS;
close KANJI;
close KANJIRADICALS;
close WORDS;
close KANJIWORDS;

