package Scripts::Windy::Web::Model::GroupMember;
use Mojo::Base 'Scripts::Windy::Web::Model::User';
use Scripts::Base;

has [qw/card joinTime lastSpeakTime level point role group/];

sub displayname
{
    my $self = shift;
    $self->card // $self->name;
}

sub isAdminOrOwner
{
    my $self = shift;
    my $role = $self->role;
    $role eq 'admin' or $role eq 'owner';
}

sub send
{
    my ($self, $text) = shift;
    my $friend = $self->client->findFriend(tencent => $self->tencent);
    if ($friend) { # then we can send friend-message
        my $tencent = $friend->tencent;
        $self->client->sendMessage
            ('friend-message',
             $tencent, # source
             $tencent, # receiver
             $text,
            );
    } else {
        $self->client->sendMessage
            ('group-sess-message',
             $self->group->number, # source
             $self->tencent, # receiver
             $text,
            );
    }
}

1;