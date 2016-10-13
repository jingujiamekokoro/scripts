package Scripts::Windy::Util::MPQ;

use 5.012;
use Exporter;
use Scripts::scriptFunctions;
use utf8;
use Encode qw/_utf8_on _utf8_off/;
use MPQ;
use Scripts::Windy::Constants;
no warnings 'experimental';
#use Data::Dumper;
our @ISA = qw/Exporter/;
our @EXPORT = qw/isGroupMsg msgText msgGroup msgGroupId
msgGroupHas msgSenderIsGroupAdmin msgStopping msgSender
uid uName isAt isAtId findUserInGroup isPrivateMsg
group invite friend $nextMessage $atPrefix $atSuffix
parseRichText $mainConf msgPosStart msgPosEnd
msgReceiver receiverName replyToMsg outputLog getAdminList isMsg/;
our @EXPORT_OK = qw//;

our $nextMessage = "\n\n";
our $atPrefix = "[\@";
our $atSuffix = "]";
our $mainConf = "windy-conf/main.conf";
my @privMsg = map $Events{$_}, 'friend-msg', 'sess-msg';
my @multMsg = map $Events{$_}, 'group-msg','discuss-msg';

sub isGroupMsg
{
    my ($windy, $msg) = @_;
    $msg->{type} == $Events{'group-msg'};
}

sub msgSender
{
    my ($windy, $msg) = @_;
    $msg->{subject};
}
sub msgReceiver
{
    my ($windy, $msg) = @_;
    $msg->{receiver};
}
sub isPrivateMsg
{
    my ($windy, $msg) = @_;
    $msg->{type} ~~ @privMsg;
}

sub parseRichText
{
    my ($windy, $msg) = @_;
    my $match = $windy->{_db}->{_match};
    my $text = $msg->{content};
    _utf8_on($text);
    my $id = msgReceiver($windy, $msg);
    isAt($windy, $msg) = $text =~ /\Q$atPrefix$id$atSuffix\E/;
    msgText($windy, $msg) = $text;
    my ($pre, $post) = ($match->{preMatch}, $match->{postMatch});
    $text =~ $pre; msgPosStart($windy, $msg) = length $&;
    $text =~ $post; msgPosEnd($windy, $msg) = length $&;
    msgText($windy, $msg);
}

sub replyToMsg
{
    my ($windy, $msg, $content) = @_;
    if (not $msg->isMessage) {
        my $ret;
        if ($content eq int $content) {
            $ret = $content;
        } elsif (defined $EventRet{$content}) {
            $ret = $EventRet{$content};
        } else {
            $ret = $EventRet{pass};
        }
        return $ret;
    }
    $content or return $EventRet{pass};
    my $sendTo = ($msg->{type} ~~ @multMsg) ? '' : msgSender($windy, $msg);
    
    MPQ::SendMsg(msgReceiver($windy, $msg),
                 $msg->{type}, 0, $msg->{source}, $sendTo,
                 term $_) for split $nextMessage, $content; # to euc-cn
    $EventRet{done};
}


sub msgPosStart : lvalue
{
    my ($windy, $msg) = @_;
    $msg->{_pos_start};
}

sub msgPosEnd : lvalue
{
    my ($windy, $msg) = @_;
    $msg->{_pos_end};
}

sub msgText : lvalue
{
    my $windy = shift;
    my $msg = shift;
    $msg->{__rich_text};
}

sub msgGroup
{
    my ($windy, $msg) = @_;
    isGroupMsg(@_) and $msg->{source};
}

sub msgGroupId
{
    my ($windy, $msg) = @_;
    isGroupMsg(@_) and $msg->{source};
}

sub friend
{
    my ($windy, $msg, $f) = @_;
    $f;
    #$msg->{_client}->search_friend(qq => $f);
}

sub group
{
    my ($windy, $msg, $g) = @_;
    $g;
    #$msg->{_client}->search_group(gnumber => $g);
}

sub invite
{
    my ($windy, $msg, $group, $person) = @_;
    return unless $group and $person;
    not MPQ::GroupInvitation(msgReceiver($windy, $msg), $person, $group);
}

sub msgGroupHas
{
    my ($windy, $msg, $id) = @_;
    isGroupMsg(@_);# and $msg->group->search_group_member(qq => $id); # 这条可能会。很。慢。嗯。
}

sub msgStopping : lvalue
{
    my ($windy, $msg) = @_;
    $msg->{__stopping__};
}

sub getAdminList
{
    my ($windy, $msg, $group) = @_;
    split "\n", MPQ::GetAdminList(msgReceiver($windy, $msg), $group);
}
sub msgSenderIsGroupAdmin
{
    my ($windy, $msg) = @_;
    isGroupMsg($windy, $msg) or return;
    my @adminList = getAdminList($windy, $msg, $msg->{source});
    msgSender($windy, $msg) ~~ @adminList;
}

sub uid
{
    shift;
}

sub uName
{
    $atPrefix.shift.$atSuffix;
}

sub receiverName
{
    my $windy = shift;
    my $msg = shift;
    utf8(uName(msgReceiver($windy, $msg)));
}

sub isAt : lvalue
{
    my $windy = shift;
    my $msg = shift;
    $msg->{__is_at};
}

sub isAtId
{
    my ($windy, $msg, $id) = @_;
    msgText($windy, $msg) =~ /\Q$atPrefix\E\Q$id$atSuffix\E/;
}

sub findUserInGroup
{
    my $windy = shift;
    my $uid = shift;
    my $group = shift;
    #$group->search_group_member(qq => $uid);
}

sub outputLog
{
    MPQ::OutPut(term(@_));
}

sub isMsg
{
    my ($windy, $msg) = @_;
    $msg->isMessage;
}
1;
