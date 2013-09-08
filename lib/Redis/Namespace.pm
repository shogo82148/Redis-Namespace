package Redis::Namespace;
use strict;
use warnings;
our $VERSION = '0.01';

use Redis;

sub new {
    my $class = shift;
    my %args = @_;
    my $self  = bless {}, $class;

    $self->{redis} = $args{redis} || Redis->new(%args);
    $self->{namespace} = $args{namespace};
    return $self;
}

sub DESTROY { }

our $AUTOLOAD;
sub AUTOLOAD {
  my $command = $AUTOLOAD;
  $command =~ s/.*://;
  my $method = sub {
      my ($self, @args) = @_;
      my $redis = $self->{redis};
      return $redis->$command(@args);
  };

  # Save this method for future calls
  no strict 'refs';
  *$AUTOLOAD = $method;

  goto $method;
}

1;
__END__

=head1 NAME

Redis::Namespace -

=head1 SYNOPSIS

  use Redis::Namespace;

=head1 DESCRIPTION

Redis::Namespace is

=head1 AUTHOR

Ichinose Shogo E<lt>shogo82148@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
