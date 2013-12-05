#!/usr/bin/env perl
# this is used to relay from NETWORK1/2/3 to MYNETWORK
# the listen channels are set as "channelname"
# dont use the # in them, not required..
# you can also have it put it to another network..there is a example listed below
# this is used to link tons of networks to your network
# something like a "spybot"
# you use these commands to setup irssi's networks
# /network add -nick nickname -user username -realname "something here" <servername>
# /server add -auto -network <servername> irc.servername.net
# /channel add -auto #channelname
use strict;
use warnings;
use Irssi;
use vars qw($VERSION %IRSSI);

$VERSION = '1.01';
%IRSSI = (
    authors     => 'black',
    contact         => '#chat@deluxe-host',
    name            => 'relay',
    description => 'sends messages from one channel to another channel on a different network',
    modules     => 'use Storable',
    license         => 'GNU General Public License v3.0',
    changed     => 'Sat Nov 16 02:34:07 EST 2013',
);
#first network
	my $network1 = "NETWORK1";
	my $listen_chan1 = "channel1";
	my $listen_chan2 = "channel2";
#second network
	my $network2 = "NETWORK2";
	my $listen_chan3 = "channel1";
	my $listen_chan4 = "channel2";
	my $listen_chan5 = "channel3";
#third network
	my $network3 = "NETWORK3";
	my $listen_chan6 = "channel1";
	my $listen_chan7 = "channel2";
#your network
	my $mynetwork = "NETWORK_TO_RELAY_TOO";
	my $output_chan1 = "#tcl";
	my $output_chan2 = "#output2";
	my $output_chan3 = "#output3";
	my $output_chan4 = "#output4";
    my $preann = "#PRE";

sub change_mode {
    my ($context, $nick, $mode) = @_;
};
Irssi::signal_add "message irc action", sub
{
    my ($server, $msg, $nick, $address, $target) = @_;
	if ($target  =~ m/#(?:$listen_chan1)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan1 * <\x0308\x02$nick\x02\x0300\@\x02\x0303$network1\x02\x0f> $msg");
    }
    elsif ($target =~ m/#(?:$listen_chan2)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan2 * <\x0308\x02$nick\x02\x0300\@\x02\x0303$network1\x02\x0f> $msg");
    }
    elsif ($target =~ m/#(?:$listen_chan3)/) {
            my $server3 = Irssi::server_find_tag($mynetwork);
            $server3->command ("msg $output_chan3 * <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f> $msg");
    }
    elsif ($target =~ m/#(?:$listen_chan4)/) {
            my $server4 = Irssi::server_find_tag($mynetwork);
            $server4->command ("msg $output_chan4 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f> $msg");
			# EXAMPLE FOR ONE NETWORK TO TWO DIFFERENT NETWORKS
	    my $server2 = Irssi::server_find_tag($network3);
            $server2->command ("msg $output_chan1 * <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f> $msg");
			# END OF EXAMPLE
    }
    elsif ($target =~ m/#(?:$listen_chan5)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan2 * <\x0308\x02$nick\x02\x0300\@\x02\x0303$network3\x02\x0f> $msg");
    }
    elsif ($target =~ m/#(?:$listen_chan6)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan4 * <\x0308\x02$nick\x02\x0300\@\x02\x0303$network3\x02\x0f> $msg");
    }
};
Irssi::signal_add "message kick", sub
{
    my ($server, $target, $nick, $kicker, $address, $reason) = @_;
	if ($target  =~ m/#(?:$listen_chan1)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan1 * <\x0308\x02$nick\x02\x0300\@\x02\x0303$network1\x02\x0f> was kicked by: $kicker reason: $reason");
    }
    elsif ($target =~ m/#(?:$listen_chan2)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan2 * <\x0308\x02$nick\x02\x0300\@\x02\x0303$network1\x02\x0f>  was kicked by: $kicker reason: $reason");
    }
    elsif ($target =~ m/#(?:$listen_chan3)/) {
            my $server3 = Irssi::server_find_tag($mynetwork);
            $server3->command ("msg $output_chan3 * <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f>  was kicked by: $kicker reason: $reason");
    }
    elsif ($target =~ m/#(?:$listen_chan4)/) {
            my $server4 = Irssi::server_find_tag($mynetwork);
            $server4->command ("msg $output_chan4 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f>  was kicked by: $kicker reason: $reason");
			my $server2 = Irssi::server_find_tag($network3);
            $server2->command ("msg $output_chan1 * <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f>  was kicked by: $kicker reason: $reason");
    }
    elsif ($target =~ m/#(?:$listen_chan5)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan2 * <\x0308\x02$nick\x02\x0300\@\x02\x0303$network3\x02\x0f>  was kicked by: $kicker reason: $reason");
    }
    elsif ($target =~ m/#(?:$listen_chan6)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan4 * <\x0308\x02$nick\x02\x0300\@\x02\x0303$network3\x02\x0f>  was kicked by: $kicker reason: $reason");
    }
};
Irssi::signal_add "message part", sub 
{ 
        my ($server,$channel,$nick,$address) = @_;

	if ($channel  =~ m/#(?:$listen_chan1)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan1 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network1\x02\x0f> *** $nick\@$address part $channel");
    }
    elsif ($channel =~ m/#(?:$listen_chan2)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan2 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network1\x02\x0f> *** $nick\@$address part $channel");
    }
    elsif ($channel =~ m/#(?:$listen_chan3)/) {
            my $server3 = Irssi::server_find_tag($mynetwork);
            $server3->command ("msg $output_chan3 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f> *** $nick\@$address part $channel");
    }
    elsif ($channel =~ m/#(?:$listen_chan4)/) {
            my $server4 = Irssi::server_find_tag($mynetwork);
            $server4->command ("msg $output_chan4 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f> *** $nick\@$address part $channel");
		    my $server2 = Irssi::server_find_tag($network3);
            $server2->command ("msg $output_chan1 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f> *** $nick\@$address part $channel");
    }
    elsif ($channel =~ m/#(?:$listen_chan5)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan2 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network3\x02\x0f> *** $nick\@$address part $channel");
    }
    elsif ($channel =~ m/#(?:$listen_chan6)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan4 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network3\x02\x0f> *** $nick\@$address part $channel");
    }
};

Irssi::signal_add "message join", sub
{
        my ($server,$channel,$nick,$address) = @_;

	if ($channel  =~ m/#(?:$listen_chan1)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan1 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network1\x02\x0f> *** $nick\@$address join $channel");
    }
    elsif ($channel =~ m/#(?:$listen_chan2)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan2 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network1\x02\x0f> *** $nick\@$address join $channel");
    }
    elsif ($channel =~ m/#(?:$listen_chan3)/) {
            my $server3 = Irssi::server_find_tag($mynetwork);
            $server3->command ("msg $output_chan3 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f> *** $nick\@$address join $channel");
    }
    elsif ($channel =~ m/#(?:$listen_chan4)/) {
            my $server4 = Irssi::server_find_tag($mynetwork);
            $server4->command ("msg $output_chan4 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f> *** $nick\@$address join $channel");
			my $server2 = Irssi::server_find_tag($network3);
            $server2->command ("msg $output_chan1 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f> *** $nick\@$address join $channel");
    }
    elsif ($channel =~ m/#(?:$listen_chan5)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan2 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network3\x02\x0f> *** $nick\@$address join $channel");
    }
    elsif ($channel =~ m/#(?:$listen_chan6)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan4 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network3\x02\x0f> *** $nick\@$address join $channel");
    }
};
Irssi::signal_add "message public", sub
{
    my ($server, $msg, $nick, $nick_addr, $target) = @_;

	if ($target  =~ m/#(?:$listen_chan1)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan1 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network1\x02\x0f> $msg");
    }
    elsif ($target =~ m/#(?:$listen_chan2)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan2 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network1\x02\x0f> $msg");
    }
    elsif ($target =~ m/#(?:$listen_chan3)/) {
            my $server3 = Irssi::server_find_tag($mynetwork);
            $server3->command ("msg $output_chan3 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f> $msg");
    }
    elsif ($target =~ m/#(?:$listen_chan4)/) {
        my $server4 = Irssi::server_find_tag($mynetwork);
            $server4->command ("msg $output_chan4 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f> $msg");
	    my $server2 = Irssi::server_find_tag($network3);
            $server2->command ("msg $output_chan1 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network2\x02\x0f> $msg");
    }
    elsif ($target =~ m/#(?:$listen_chan5)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan2 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network3\x02\x0f> $msg");
    }
    elsif ($target =~ m/#(?:$listen_chan6)/) {
            my $server2 = Irssi::server_find_tag($mynetwork);
            $server2->command ("msg $output_chan4 <\x0308\x02$nick\x02\x0300\@\x02\x0303$network3\x02\x0f> $msg");
    }
};



