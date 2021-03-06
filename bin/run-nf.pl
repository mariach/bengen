#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

# SCRIPT TASK: 
# 
# Given a table run.csv, pass everything that has to be run ( chaching! ) to nextflow.
#


my ($dir, $methods_file, $result_file, $run_file ) = @ARGV;


my %hash = ();
my %result_hash= ();

my $dhid;

open IN  ,'<', "$dir/images_docker" or die "can't open file  for reading: $!";

while( defined( my $line = <IN> ) ){		
	my @temp= split /\//, $line ; 	
	 $dhid=@temp[0];
}
close(IN);


##CREATE HASMAP TO SEE WHAT HAS ALREADY BEEN COMPUTED
#
# hash_result{Scoringfunction, Dataset, method}="true"


open IN  ,'<', "$result_file" or die "can't open file  for reading: $!";

while( defined( my $line = <IN> ) ){	

	chomp $line; 

	
	$line =~ s/$dhid\///g;

	my @splitted = split /,/, $line; 
	my $sf = $splitted[0];
	my $method = $splitted[1];
	my $db = $splitted[2];
	my $id = $splitted[3];


	my $key = $sf.",".$db.",".$method.",".$id;
	
	if (! $result_hash{$key}){
	  $result_hash{$key} ="true";
	
	}	

}

close(IN);


print Dumper \%result_hash;





# READ RUN FILE AND STORE DATAS IN HASHMAP 
#
# hash{ScoringFunction,Dataset}=method1,...,methodX



open IN  ,'<', "$run_file" or die "can't open file  for reading: $!";

while( defined( my $line = <IN> ) ){
	


	
	#prepare the parameters	
	#chomp $line; 
	my @splitted = split /,/, $line; 
	print $line ; 
	my $sf = $splitted[0];
	my $method = $splitted[1];
	my $db = $splitted[2];	
	my $id = $splitted[3];

 	
	$db=~ s/\n//g; 
	#chop $db;
	my $key = $sf.",".$db.",".$id;
	

	#key_result to look if the triplet has already been computed	
	my $key_result = $sf.",".$db.",".$method.",".$id;
	
	
	# if the triplet has not been computed --> add to hashmap 
	if ( ! $result_hash{$key_result} ){
		print $key_result; 
		if ($hash{$key}){
		  $hash{$key} =$hash{$key}.",".$method;
	
		}
		else{
	
		$hash{$key}=$method;
		
		}
	}
	

}

close(IN);


print Dumper \%hash;



	my $f; 
	open( $f, '>', "$dir/caching-infos-current-run") or die "Could not open file  $!";
	print $f Data::Dumper->Dump( [ \%result_hash ], [ qw(*cached) ] );
	print $f Data::Dumper->Dump( [ \%hash ], [ qw(*toRun) ] );
	close ($f);



## RUN NEXTFLOW AND STORE THE RESULTS  


foreach my $key ( keys %hash) { 

	#prepare parameters to use
	my @array = split /,/, $key;
	my $sf = $array[0];
	my $db = $array[1];
	my $id = $array[2];

	my $method = $hash{$key};
	#format method name --> $dhid/method 
	$method=~ s/,/\n$dhid\//g;


	#Add ALL the aligners to run into the aligners file
	my $fh;
	open( $fh, '>', "$dir/$methods_file") or die "Could not open file  $!";
	print $fh "$dhid/".$method;
	close ($fh);

	#Run Nextflow
	
	my $command = "nextflow -q run $dir/alnscore.nf -resume --dataset ".$db." --score ".$sf." --newBase ".$dir." --id ".$id;


	


	my $output = `$command`;

	chomp $output; 
	$output=~s/WARN: It seems you never run this project before -- Option `-resume` is ignored\n//;
	
	#Save the results into the results file
	my $f; 
	open( $f, '>>', "$result_file") or die "Could not open file  $!";
	print $f $output;
	close ($f);

	print $output;

 }

