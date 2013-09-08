use strict;
use Test::More;
use Redis;
use Test::RedisServer;

use Redis::Namespace;

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );
my $ns = Redis::Namespace->new(redis => $redis, namespace => 'ns');

is $ns->ping, 'PONG', 'ping pong ok';

subtest 'get and set' => sub {
    ok($ns->set(foo => 'bar'), 'set foo => bar');
    ok(!$ns->setnx(foo => 'bar'), 'setnx foo => bar fails');
    cmp_ok($ns->get('foo'), 'eq', 'bar', 'get foo = bar');
    cmp_ok($redis->get('ns:foo'), 'eq', 'bar', 'foo in namespace');
    $redis->flushall;
};

subtest 'keys' => sub {
    my @keys;
    for (1..10) {
        ok($ns->set("key-$_" => $_), "set key-$_ => $_");
        $redis->set("another-ns:key-$_" => $_);
        push @keys, "key-$_";
    }
    is_deeply [sort $ns->keys('*')], [sort @keys], "keys *";
    is scalar $ns->keys('*'), 10, "count keys *";
    $redis->flushall;
};

done_testing;

