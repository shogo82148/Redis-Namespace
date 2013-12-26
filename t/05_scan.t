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

sub iterate {
    my ($command, $test) = @_;
    my ($iter, $list) = (0, []);
    while(1) {
        ($iter, $list) = $command->($iter);
        for my $key(@$list) {
            $test->($key);
        }
        last if $iter == 0;
    }
}


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
    iterate sub {
        $ns->scan($_[0]);
    }, sub {
        is $ns->get($_[0]) => 'ns';
    };

    $redis->flushall;
};

done_testing;
