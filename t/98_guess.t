use strict;
use Test::More;
use Redis;
use Test::RedisServer;

eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';

use Redis::Namespace;
%Redis::Namespace::COMMANDS = (); # clear commands list for test.

my $redis_server = Test::RedisServer->new;
my $redis = Redis->new( $redis_server->connect_info );

my $version = $redis->info->{redis_version};
eval { $redis->command_count } or plan skip_all => "guess option requires the COMMAND command, but your redis server seems not to support it. your redis version is $version";

my $ns = Redis::Namespace->new(redis => $redis, namespace => 'ns', guess => 1);

subtest 'get and set' => sub {
    ok($ns->set(foo => 'bar'), 'set foo => bar');
    ok(!$ns->setnx(foo => 'bar'), 'setnx foo => bar fails');
    cmp_ok($ns->get('foo'), 'eq', 'bar', 'get foo = bar');
    cmp_ok($redis->get('ns:foo'), 'eq', 'bar', 'foo in namespace');
    $redis->flushall;
};

subtest 'mget and mset' => sub {
    ok($ns->mset(foo => 'bar', hoge => 'fuga'), 'mset foo => bar, hoge => fuga');
    is_deeply([$ns->mget('foo', 'hoge')], ['bar', 'fuga'], 'mget foo hoge = hoge, fuga');
    is_deeply([$redis->mget('ns:foo', 'ns:hoge')], ['bar', 'fuga'], 'foo, hoge in namespace');
    $redis->flushall;
};

subtest 'GEORADIUS' => sub {
    my $version = version->parse($redis->info->{redis_version});
    eval {
        $redis->geoadd('ns:Sicily', 13.361389, 38.115556, "Palermo", 15.087269, 37.502669, "Catania");
    } or skip_all => "your redis server seems not to support GEO commands, your redis version is $version";

    is_deeply([$ns->georadius(Sicily => 15, 37, 200, "km", "ASC")], ["Catania", "Palermo"], "GEORADIUS");

    # STORE key
    $ns->georadius(Sicily => 15, 37, 200, "km", STORE => "result");
    is_deeply([$redis->zrange('ns:result', 0, -1)], ["Palermo", "Catania"]);

    # STOREDIST key
    $ns->georadius(Sicily => 15, 37, 200, "km", STOREDIST => "result");
    is_deeply([$redis->zrange('ns:result', 0, -1)], ["Catania", "Palermo"]);

    $redis->flushall;
};

done_testing;
