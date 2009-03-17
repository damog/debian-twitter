package Debian::Twitter::Post;

use Modern::Perl;

use IPC::Open3;

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

	# from this point, everything's plain
	$r->content_type("text/plain");

	my($in, $out, $err);
	my $cpid = open3($in, $out, $err, "gpg", "--verify");

	print $in $trace;

	close $in;

	my @out = <$out>;
	my @err = <$err> if $err;

	close $out;
	close $err if $err;

	waitpid($cpid, 0);

	if($?) {
		$r->print("That doesn't seem to be a GPG-signed message. Aborting.\n");
	} else {
		$r->print("Seems cool so far.\n");
	}

	return Apache2::Const::OK;
}

1;
