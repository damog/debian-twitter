package Debian::Twitter::Post;

use strict;
use warnings;

use Apache2::Request ();
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
use Apache2::Const -compile => qw/:common :http/;
use File::Temp;
use Data::Dumper;

sub handler {
	my($r) = shift;

	return Apache2::Const::HTTP_BAD_REQUEST unless $r->method eq 'POST';
	return Apache2::Const::HTTP_BAD_REQUEST unless $r->headers_in->{'Content-Length'};

	my $trace;
	$r->read($trace, $r->headers_in->{'Content-Length'});

	return Apache2::Const::HTTP_BAD_REQUEST unless $trace;

	my $ft = File::Temp->new;
	open my $f, ">/tmp/caca";
	print $f $trace;
	close $f;

	open my $f, "/tmp/caca";
	my @lines = <$f>;
	close $f;

	$r->content_type('text/plain');

	$r->print(@lines);

	close $ft;

	#$r->content_type('text/plain');
	#$r->print("All good so far.\n\n");

	return Apache2::Const::OK;
}

1;
