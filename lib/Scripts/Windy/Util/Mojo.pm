package Scripts::Windy::Util::Mojo;

use 5.012;
use Exporter;
use Scripts::Base;
use Scripts::Windy::Util::Base;
use utf8;
use Encode qw/_utf8_on _utf8_off/;
#use Data::Dumper;
our @ISA = qw/Exporter/;
our @EXPORT = qw/isGroupMsg msgText msgGroup msgGroupId msgGroupName
isDiscussMsg msgDiscuss msgDiscussName msgDiscussId
msgGroupHas msgSenderIsGroupAdmin msgStopping msgSender
uid uName isAt isAtId findUserInGroup isPrivateMsg
group invite friend $atPrefix $atSuffix
parseRichText msgPosStart msgPosEnd
msgReceiver receiverName outputLog isMsg sendTo
msgGroupMembers setGroupCard msgTextNoAt
msgSource/;
our @EXPORT_OK = qw//;

our $atPrefix = "\tat";
our $atSuffix = "\t";
# check whether a msg is a group msg
sub isGroupMsg
{
    my $windy = shift;
    my $msg = shift;
    $msg->type eq 'group_message';
}

sub isDiscussMsg
{
    my ($windy, $msg) = @_;
    $msg->type eq 'discuss_message';
}

sub isPrivateMsg
{
    my ($windy, $msg) = @_;
    $msg->type =~ /^(?:sess|friend)_message$/;
}

sub shortenDName
{
    my $name = shift;
    _utf8_off($name);
    $name;
#    _utf8_on($name);
#    my $subset = substr $name, 0, 7;
#    _utf8_off($subset);
#    $subset;
}

sub parseRichText
{
    my ($windy, $msg) = @_;
    my $match = $windy->{_db}->{_match};
    my @raw = @{ $msg->raw_content };
    my ($text, $noAt);
    my $oName = $msg->receiver->displayname;
    _utf8_on($oName);
    my $name = shortenDName($oName =~ s/$match->{notShownInAt}//gr);
    while (@raw) {
        my $head = shift @raw;
        if ($head->{type} eq 'txt'
            and $head->{content} =~ /^\@/
            and $raw[0]->{type} eq 'txt'
            and $raw[0]->{content} eq '') {
            shift @raw;
            my $at = shortenDName($head->{content} =~ s/^\@//r);
            isAt($windy, $msg) = 1 if $at eq $name;
            $text .= $atPrefix.'@'.$at.$atSuffix;
        } else {
            $noAt .= $head->{content};
            $text .= $head->{content};
        }
    }
    _utf8_on($noAt);
    msgTextNoAt($windy, $msg) = $noAt;
    _utf8_on($text);
    msgText($windy, $msg) = $text;
    my ($pre, $post) = ($match->{preMatch}, $match->{postMatch});
    $text =~ $pre; msgPosStart($windy, $msg) = length $&;
    $text =~ $post; msgPosEnd($windy, $msg) = length $&;
    msgText($windy, $msg);
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
#    print Dumper(@_);
    my $windy = shift;
    my $msg = shift;
    $msg->{__rich_text};
}

sub msgTextNoAt : lvalue
{
    my ($windy, $msg) = @_;
    $msg->{__text_no_at};
}

sub msgGroup
{
    my ($windy, $msg) = @_;
    isGroupMsg(@_) and $msg->group;
}

sub msgDiscuss
{
    my ($windy, $msg) = @_;
    isDiscussMsg(@_) and $msg->discuss;
}

sub msgGroupId
{
    my ($windy, $msg) = @_;
    isGroupMsg(@_) and $msg->group->gnumber;
}

sub msgDiscussId
{
    my ($windy, $msg) = @_;
    isDiscussMsg(@_) and $msg->discuss->did;
}

sub msgGroupName
{
    my ($windy, $msg) = @_;
    isGroupMsg(@_) or return;
    my $name = $msg->group->gname;
    _utf8_on($name);
    $name;
}

sub msgDiscussName
{
    my ($windy, $msg) = @_;
    isDiscussMsg(@_) or return;
    my $name = $msg->discuss->dname;
    _utf8_on($name);
    $name;
}

sub friend
{
    my ($windy, $msg, $f) = @_;
    $msg->{_client}->search_friend(qq => $f);
}
sub group
{
    my ($windy, $msg, $g) = @_;
    $msg->{_client}->search_group(gnumber => $g);
}

sub invite
{
    my ($windy, $msg, $group, $person) = @_;
    return unless $group and $person;
    $group->invite_friend($person);
}

sub msgGroupHas
{
    my ($windy, $msg, $id) = @_;
    isGroupMsg(@_) and $msg->group->search_group_member(qq => $id); # 这条可能会。很。慢。嗯。
}
sub msgStopping : lvalue
{
    my ($windy, $msg) = @_;
    $msg->{__stopping__};
}

sub msgSender
{
    my ($windy, $msg) = @_;
    $msg->sender;
}

sub msgReceiver
{
    my ($windy, $msg) = @_;
    $msg->receiver;
}

sub msgSenderIsGroupAdmin
{
    my ($windy, $msg) = @_;
    if (isGroupMsg($windy, $msg)) {
        $msg->sender->role eq 'owner' or $msg->sender->role eq 'admin';
    } elsif (isPrivateMsg($windy, $msg)) {
        1;
    } else {
        0;
    }
}

sub uid
{
    shift->qq;
}

sub uName
{
    my $name = shift->displayname;
    _utf8_on($name);
    $name;
}

sub receiverName
{
    my $windy = shift;
    my $msg = shift;
    my $name = uName(msgReceiver($windy, $msg));
    _utf8_on($name);
    $name;
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
    my $user = msgGroupHas($windy, $msg, $id) or return;
    my $name = shortenDName($user->displayname);
    msgText($windy, $msg) =~ /\Q$atPrefix\E\@\Q$name$atSuffix\E/;
}

sub findUserInGroup
{
    my $windy = shift;
    my $uid = shift;
    my $group = shift;
    $group->search_group_member(qq => $uid);
}
sub outputLog
{
    1;
}
sub isMsg
{
    1;
}

sub sendTo
{
    my ($to, $text) = @_;
    $to or return;
    _utf8_off($text);
    for (split $nextMessage, $text) {
        $to->send($_);
    }
}

sub msgGroupMembers
{
    my ($windy, $msg) = @_;
    isGroupMsg(@_) and $msg->group->members;
}
sub setGroupCard
{
    my ($windy, $msg, $member, $card) = @_;
    _utf8_off($card);
    $member or return;
    $member->set_card($card);
}

sub msgSource
{
    my ($windy, $msg) = @_;
    if (isGroupMsg($windy, $msg)) {
        msgGroupId($windy, $msg);
    } elsif (isDiscussMsg($windy, $msg)) {
        msgDiscussId($windy, $msg).'D';
    } elsif (isPrivateMsg($windy, $msg)) {
        uid(msgSender($windy, $msg)).'P';
    }
}

1;
