package Debian::Twitter::Post;

use Modern::Perl;
use Net::Twitter '2.11';
use IPC::Open3;
use Net::LDAP;

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

	my $gpgbin = $r->dir_config('GnuPGBin') || '/usr/bin/gpg';
	my $keyring = $r->dir_config('Keyring') || '/usr/share/keyrings/debian-keyring.gpg';
	my $gpghome = $r->dir_config('GnuPGHome') || '/tmp';

	# from this point, everything's plain
	$r->content_type("text/plain");

	my($in, $out, $err);
	my $cpid = open3($in, $out, $err, $gpgbin, "--keyring", $keyring, "--homedir", $gpghome);

	print $in $trace;

	close $in;

	my @out = <$out>;
	my @err = <$err> if $err;

	close $out;
	close $err if $err;

	waitpid($cpid, 0);

	if($?) {
		$r->print("Invalid file or signature. Aborting.\n");
		$r->print(Dumper(@out));
	} else {
		chomp(my $tweet = $out[0]);

		my $fprpid = open3($in, $out, $err, $gpgbin, "--verify", "--keyring", $keyring, "--homedir", $gpghome);
		print $in $trace;
		close $in;
		
		my $fpr;
		while(<$out>) {
			if($_ =~ /(([0-9A-F]{4} ?){5} ([0-9A-F]{4} ?){5})/) {
				chomp($fpr = $1);
				last;
			}
		}

		close $out; close $err if $err; waitpid($fprpid, 0);

		my $uid;
		if($fpr) {
			my $server = 'db.debian.org';
			
			my $ldap = Net::LDAP->new($server) or die "Couldn't make connection to ldap server: $@";
			$ldap->bind;

			$fpr =~ s/\s//g;
			my $mesg = $ldap->search(
				'base' => 'dc=debian,dc=org',
				'filter' => "(keyfingerprint=$fpr)",
				'attrs' => 'uid') or die;
	
			my ($entry) = $mesg->entries;
			$uid = $entry->get('uid')->[0];
		}

    # clean the tweet a bit
    $tweet =~ s/(^\s+|\s+$)//g;

    if($uid) {
      $tweet .= " (via $uid)"
    }

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

