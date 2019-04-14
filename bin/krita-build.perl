#!/usr/bin/env perl

=head1 Krita build script
=cut
=head2 Preparation

Install MinGW & MSYS

Install CMake, either through `pacman -S mingw-w64-x86_64-cmake` or by yourself (you need to manually add it to PATH)

Install Python 3.6

Download and unpack krita-deps.zip

Fetch the source code of krita
=cut
=head2 Editing configurations

Turn to `Config Part' and edit the directories as needed

Create the directories specified by `$kritaBuildDir`
=cut
=head2 Running the script

You should have received a copy of the Perl interpreter from MSYS

Invoke the script with:

    <msysDir>/usr/bin/perl.exe <path-to>/krita-build.perl ARGS

In the following lines I will use `<krita-build>` to denote `<mingwDir>/usr/bin/perl.exe <path-to>/krita-build.perl`.

First, modify some hardcoded paths in krita-deps:

    <krita-build> prepare

Then, run cmake:

    <krita-build> cmake

Then, compile the sources:

    <krita-build> build

Finally, install:

    <krita-build> install

`install` will also trigger `build` so if you want to build AND install, `build` can be skipped to avoid re-scanning of all targets.
=cut
use strict;
use 5.010;

sub winPath
{
    my $path = shift;
    $path =~ s{/}{\\}g;
    $path;
}

sub winPathInStr
{
    my $path = shift;
    $path =~ s{/}{\\\\}g;
    $path;
}

sub unixPath
{
    my $path = shift;
    $path =~ s{\\}{/}g;
    $path;
}

### Config Part -- change as needed
# the directory extracted from krita-deps.zip
# you should have downloaded it from https://binary-factory.kde.org/job/Krita_Nightly_Windows_Dependency_Build/
my $depsDir = 'c:/Home/Programs/krita-deps/deps-install';
# the path to MinGW installation
my $mingwDir = 'c:/Home/Programs/msys64/mingw64';
# the path to your Python 3.6
my $pythonDir = 'c:/Home/Programs/python3'; # krita-dep's python build does not seem to consider PYTHONPATH
# the directory to install krita
my $kritaInstallDir = 'c:/Home/Programs/krita-testing';
# krita source directory
my $kritaSrcDir = 'c:/Home/Code/krita';
# the directory to build krita
my $kritaBuildDir = 'c:/Home/Code/krita-build';
# how many jobs can we run at the same time
my $jobs = 3;
### End config part

# Chances are MinGW has a higher version of Python, which we do not want.
$ENV{'PATH'} = (winPath "$pythonDir;$depsDir/bin;$mingwDir/bin;").$ENV{'PATH'};
$ENV{'PYTHONPATH'} = winPath "$depsDir/lib/krita-python-libs";

# Just in case you have some Boost installed...
# it will cause problems if you do not have the libraries of the correct type
# these environment variables are specified in FindBoost.cmake:40-45 (provided by CMake)
delete $ENV{'BOOST_ROOT'};
delete $ENV{'BOOSTROOT'};
delete $ENV{'BOOST_LIBRARYDIR'};
delete $ENV{'BOOST_INCLUDEDIR'};

chdir $kritaBuildDir;

my $action = $ARGV[0];
if ($action eq 'cmake') {
    # from build.cmd
    system 'cmake', $kritaSrcDir,
        "-DCMAKE_INSTALL_PREFIX=$kritaInstallDir",
        '-DBoost_DEBUG=OFF',
        "-DBOOST_INCLUDEDIR=$depsDir/include",
        "-DBOOST_ROOT=$depsDir",
        "-DBOOST_LIBRARYDIR=$depsDir/lib",
        "-DCMAKE_PREFIX_PATH=$depsDir",
        '-DBUILD_TESTING=OFF',
        '-DHAVE_MEMORY_LEAK_TRACKER=OFF',
        '-DFOUNDATION_BUILD=ON',
        '-DUSE_QT_TABLET_WINDOWS=ON',
        '-Wno-dev',
        '-G', "MinGW Makefiles",
        '-DCMAKE_BUILD_TYPE=RelWithDebInfo';
} elsif ($action eq 'build') {
    system 'mingw32-make', "-j$jobs";
} elsif ($action eq 'install') {
    system 'mingw32-make', "-j$jobs", 'install';
} elsif ($action eq 'prepare') {
    my $origDepsDir = 'C:/Packaging/KritaWS/deps-install';
    my $escapedOrigDepsDir = winPathInStr $origDepsDir;
    # change the hardcoded path in VcConfig
    my $vcConfig = "$depsDir/lib/cmake/Vc/VcConfig.cmake";
    open VCCONF, '<', $vcConfig;
    my $content = join '', <VCCONF>;
    close VCCONF;
    $content =~ s@\Q$origDepsDir\E@$depsDir@g;

    open VCCONFW, '>', $vcConfig;
    print VCCONFW $content;
    close VCCONFW;

    # ...and sipconfig.py
    my $sipConfig = "$depsDir/lib/krita-python-libs/sipconfig.py";
    my $escapedDepsDir = winPathInStr $depsDir;
    open SIPCONF, '<', $sipConfig;
    $content = join '', <SIPCONF>;
    close SIPCONF;
    $content =~ s@\Q$origDepsDir\E@$depsDir@g;
    $content =~ s@\Q$escapedOrigDepsDir\E@$escapedDepsDir@g;

    open SIPCONFW, '>', $sipConfig;
    print SIPCONFW $content;
    close SIPCONFW;

    say 'The source is prepared to build.';
} else {
    say 'Usage: krita-build.perl cmake|build|install|prepare';
}
