use strict;
use Test::More;
use Redis;
use Test::RedisServer;

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );

is $redis->ping, 'PONG', 'ping pong ok';

done_testing;

