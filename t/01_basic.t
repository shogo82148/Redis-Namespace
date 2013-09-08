use strict;
use Test::More;
use Redis;
use Test::RedisServer;

use Redis::Namespace;

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );
my $namespace = Redis::Namespace->new(redis => $redis, namespace => 'ns');

is $namespace->ping, 'PONG', 'ping pong ok';

done_testing;

