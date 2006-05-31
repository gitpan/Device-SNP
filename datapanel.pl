# datapanel.pl
#
# Act as a SNP Slave and serve serial port requests from a DataPanel
# Implement reading and writing of SNP data as Amarok commands etc
#
# Segment Data definitions for the Linux Datapanel, as defined
# in the DataDesigner database in datadesigner/linux.DTB
#
# %Q1	     play		 Play
# %Q2	     pause		 Pause
# %Q3	     prev		 Prev
# %Q4	     next		 Next
# %Q5	     volup		 Vol -
# %Q6	     voldown		 Vol +
#
# %R1-%I16     artist		 Current song artist (max 32 bytes)
# %R17-%I32     track		 Current song name text (max 32 bytes)
# %R33-%I48     album		 Current song album text (max 32 bytes)
#
# Author: Mike McCauley (mikem@open.com.au)
# Copyright (C) 2006 Mike McCauley
# $Id: datapanel.pl,v 1.1 2006/05/31 23:30:53 mikem Exp $

use strict;
use Device::SNP;
use DCOP::Amarok::Player;

my $player;

# Override Device::SNP to implement our own read and write operations
package LinuxDataPanel;
our @ISA = ('Device::SNP::Slave');

# Here we override some functions in Device::SNP::Slave
# so we get control when the DataPanel asks for and sets data.
sub read_words
{
    my ($self, $segmentname, $offset, $length) = @_;

    if ($segmentname eq 'R' && $offset == 0)
    {
	return pack('a32', $player->artist());
    }
    elsif ($segmentname eq 'R' && $offset == 16)
    {
	return pack('a32', $player->title());
    }
    elsif ($segmentname eq 'R' && $offset == 32)
    {
	return pack('a32', $player->album());
    }
}

sub write_bits
{
    my ($self, $segmentname, $offset, $length, $data) = @_;

    if ($segmentname eq 'Q' && $offset == 0)
    {
	$player->play();
    }
    elsif ($segmentname eq 'Q' && $offset == 1)
    {
	$player->pause();
    }
    elsif ($segmentname eq 'Q' && $offset == 2)
    {
	$player->prev();
    }
    elsif ($segmentname eq 'Q' && $offset == 3)
    {
	$player->next();
    }
    elsif ($segmentname eq 'Q' && $offset == 4)
    {
	$player->volumeDown();
    }
    elsif ($segmentname eq 'Q' && $offset == 5)
    {
	$player->volumeUp();
    }
    return 1; # Success
}


package main;
my $s = new LinuxDataPanel(Portname => '/dev/ttyUSB0',
			   Debug => 0);
die "Could not create Device::SNP::LinuxDataPanel" unless $s;

$player = DCOP::Amarok::Player->new();
die "Could not create DCOP::Amarok::Player" unless $player;

# Receive commands and despatch them to the functions in LinuxDataPanel
$s->run();
