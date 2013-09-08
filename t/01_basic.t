use strict;
use Test::More;
use Redis;
use Test::RedisServer;

use Redis::Namespace;

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );
my $namespace = Redis::Namespace->new(redis => $redis, namespace => 'ns');

is $namespace->ping, 'PONG', 'ping pong ok';

subtest 'get and set' => sub {
    ok($namespace->set(foo => 'bar'), 'set foo => bar');
    ok(!$namespace->setnx(foo => 'bar'), 'setnx foo => bar fails');
    cmp_ok($namespace->get('foo'), 'eq', 'bar', 'get foo = bar');
    cmp_ok($redis->get('ns:foo'), 'eq', 'bar', 'foo in namespace');
    $redis->flushall;
};

done_testing;

