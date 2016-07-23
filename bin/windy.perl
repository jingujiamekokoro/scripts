#!/usr/bin/env perl

use 5.012;
use Scripts::scriptFunctions;
use Mojo::Webqq;
use Mojo::Util qw/md5_sum/;
use Scripts::Windy;
use Time::HiRes qw/time/;
use Scripts::Windy::Util;
my $file = $accountDir.'windy';
my $uid;
if (open my $w, '<', $file) {
    chomp ($uid = <$w>);
    close $w;
} else {
    die term "打不开文件 $file: $!\n";
}
my $mailAccount = {};
if (open my $f, '<', $accountDir.'windy-mail') {
    while (<$f>) {
        chomp;
        if (/^(.+?)=(.+)$/) {
            $mailAccount->{$1} = $2;
        }
    }
    close $f;
} else {
    warn term "打不开mail文件: $!\n";
}

my $windy = Scripts::Windy->new;
my $t = Mojo::Webqq->new(
    qq => $uid,
    login_type => 'qrlogin',
    tmpdir => $configDir.'windy-cache/',
#    is_init_friend => 0,
#    is_init_group => 0,
#    is_init_discuss => 0,
#    is_init_recent => 0,
#    is_update_user => 0,
#    is_update_group => 0,
#    is_update_friend => 0,
#    is_update_discuss => 0,
    );
$t->login;
sub onReceive
{
    my ($c, $m) = @_;
    my $text = $m->content;
    my $context = ($m->type =~ /^(group|discuss)_message$/ ? " 在 ".($1 eq 'group' ? $m->group->gname.'('.$m->group->gnumber.')' : $m->discuss->dname) : '');
    $windy->logger("收到 `".$text."` 从 ".$m->sender->displayname.$context);
    my $time = time;
    my $resp = $windy->parse($m);
    if ($resp) {
        $windy->logger("送出 `".$resp."`, 在 ".( time - $time )." 秒内");
        $m->reply($_) for split "\n\n", $resp;
    }
}
#$t->load("PostQRcode",data => $mailAccount ) if %$mailAccount;
$t->on(receive_message => \&onReceive);
$t->on(receive_pic => sub {
    ### 反正这个没成功过。。。
    my ($client,$filepath,$sender)=@_;
    say "receive image: ", $filepath;
    say "sender is: ", $sender->displayname;
       });
#$t->on(receive_raw_message=>sub{
#    my ($client,$bytes,$hash) = @_;
#    print term Dumper($hash);
    #$bytes 是接收到的原始消息 json 格式数据，未做任何处理
    #$hash 是将 $bytes 进行 Mojo::JSON::decode_json 之后得到的 perl hash 结构
#});
#open STDOUT, '>>', $configDir.'windy-cache/logs.txt';
#binmode STDOUT, ':unix';
$t->run;
