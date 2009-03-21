package Debian::Twitter::Post;

use Modern::Perl;
use Net::Twitter '2.11';
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
	my $cpid = open3($in, $out, $err, "/usr/bin/gpg", "--keyring", "/usr/share/keyrings/debian-keyring.gpg", "--homedir", $r->dir_config('GnuPGHome'));

	print $in $trace;

	close $in;

	my @out = <$out>;
	my @err = <$err> if $err;

	close $out;
	close $err if $err;

	waitpid($cpid, 0);

	if($?) {
		$r->print("Invalid file or signature. Aborting.\n");
	} else {
		chomp(my $tweet = $out[0]);
		$r->print("Tweeting: `$tweet'\n");
		my $t = Net::Twitter->new( {
			username => $r->dir_config('TwitterUsername'),
			password => $r->dir_config('TwitterPassword'),
			source => 'Twitter Debian',
		});
		my $res = $t->update({ status => $tweet });
		$r->print($t->http_message, "\n");
	}

	$r->print("\n");
	return Apache2::Const::OK;
}

1;

