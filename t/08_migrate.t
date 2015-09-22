use strict;
use version 0.77;
use Test::More;
use Redis;
use Test::RedisServer;
use Test::TCP;

use Redis::Namespace;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

my $redis_server1 = Test::RedisServer->new;
my $server = Test::TCP->new(
    code => sub {
        my ($port) = @_;
        my $redis = Test::RedisServer->new(
            auto_start => 0,
            conf       => { port => $port },
        );
        $redis->exec;
    },
);
my $redis_server2 = Test::RedisServer->new;
my $redis1 = Redis->new( $redis_server1->connect_info );
my $redis2 = Redis->new( server => 'localhost:' . $server->port);
my $ns1 = Redis::Namespace->new(redis => $redis1, namespace => 'ns');
my $ns2 = Redis::Namespace->new(redis => $redis2, namespace => 'ns');

$ns1->set('hogehoge', 'foobar');
$ns1->migrate('localhost', $server->port, 'hogehoge', 0, 60);
is $ns2->get('hogehoge'), 'foobar';

done_testing;
