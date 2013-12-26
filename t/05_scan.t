use strict;
use version 0.77;
use Test::More;
use Redis;
use Test::RedisServer;

use Redis::Namespace;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );
my $ns = Redis::Namespace->new(redis => $redis, namespace => 'ns');

my $redis_version = version->parse($redis->info->{redis_version});
plan skip_all => 'your redis does not support SCAN command'
    unless $redis_version >= '2.8.0';

is $ns->ping, 'PONG', 'ping pong ok';


subtest 'Empty database' => sub {
    $redis->flushall;
    my ($iter, $list) = $ns->scan(0);
    is $iter => 0, 'iteration finish';
    is scalar @$list => 0, 'empty list';
    $redis->flushall;
};


subtest 'iterate' => sub {
    # add keys for test
    $redis->flushall;
    for my $i(1..10) {
        $redis->set("ns:hoge$i", 'ns');
        $redis->set("other-ns:hoge$i", 'other-ns');
    }

    # iterate keys
    my ($iter, $list) = (0, []);
    while(1) {
        ($iter, $list) = $ns->scan($iter);
        for my $key(@$list) {
            is $ns->get($key) => 'ns';
        }
        last if $iter == 0;
    }

    $redis->flushall;
};

done_testing;
