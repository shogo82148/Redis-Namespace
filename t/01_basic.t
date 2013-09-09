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

subtest 'mget and mset' => sub {
    ok($ns->mset(foo => 'bar', hoge => 'fuga'), 'mset foo => bar, hoge => fuga');
    is_deeply([$ns->mget('foo', 'hoge')], ['bar', 'fuga'], 'mget foo hoge = hoge, fuga');
    is_deeply([$redis->mget('ns:foo', 'ns:hoge')], ['bar', 'fuga'], 'foo, hoge in namespace');
    $redis->flushall;
};

subtest 'incr and decr' => sub {
    is($ns->incr('counter'), 1, 'incr');
    is($ns->get('counter'), 1, 'count = 1');
    is($redis->get('ns:counter'), 1, 'count in namespace');

    is($ns->incrby('counter', 3), 4, 'incrby');
    is($ns->get('counter'), 4, 'count = 4');
    is($redis->get('ns:counter'), 4, 'count in namespace');

    is($ns->decr('counter'), 3, 'decr');
    is($ns->get('counter'), 3, 'count = 3');
    is($redis->get('ns:counter'), 3, 'count in namespace');

    is($ns->decrby('counter', 3), 0, 'decrby');
    is($ns->get('counter'), 0, 'count = 0');
    is($redis->get('ns:counter'), 0, 'count in namespace');

    $redis->flushall;
};

subtest 'exists and del' => sub {
    ok(!$ns->exists('key'), 'not exists');
    $redis->set('ns:key', 'foo');
    ok($ns->exists('key'), 'exists');

    ok($ns->del('key'), 'del');
    ok(!$ns->del('key'), 'not del');
    ok(!$redis->exists('ns:key'), 'key in namespace');
    $redis->flushall;
};

subtest 'type' => sub {
    $redis->set('ns:string', 'foo');
    $redis->lpush('ns:list', 'hoge');
    $redis->sadd('ns:set', 'piyo');
    $redis->zadd('ns:zset', 0, 'piyo');
    $redis->hset('ns:hash', 'homu', 'fuga');

    cmp_ok($ns->type('string'), 'eq', 'string', 'string type');
    cmp_ok($ns->type('list'), 'eq', 'list', 'list type');
    cmp_ok($ns->type('set'), 'eq', 'set', 'set type');
    cmp_ok($ns->type('zset'), 'eq', 'zset', 'zset type');
    cmp_ok($ns->type('hash'), 'eq', 'hash', 'hash type');
    cmp_ok($ns->type('none'), 'eq', 'none', 'none type');
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

