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

subtest 'list' => sub {
    my $list = 'test-list';
    ok($ns->rpush($list => "r$_"), 'rpush') foreach (1 .. 3);
    ok($ns->lpush($list => "l$_"), 'lpush') foreach (1 .. 2);

    cmp_ok($ns->type($list), 'eq', 'list', 'type');
    cmp_ok($redis->type("ns:$list"), 'eq', 'list', 'type');
    cmp_ok($ns->llen($list), '==', 5, 'llen');
    cmp_ok($redis->llen("ns:$list"), '==', 5, 'llen');

    is_deeply([$ns->lrange($list, 0, 1)], ['l2', 'l1'], 'lrange');

    ok($ns->ltrim($list, 1, 2), 'ltrim');
    cmp_ok($ns->llen($list), '==', 2, 'llen after ltrim');

    cmp_ok($ns->lindex($list, 0), 'eq', 'l1', 'lindex');
    cmp_ok($ns->lindex($list, 1), 'eq', 'r1', 'lindex');

    ok($ns->lset($list, 0, 'foo'), 'lset');
    cmp_ok($ns->lindex($list, 0), 'eq', 'foo', 'verified');

    ok($ns->lrem($list, 1, 'foo'), 'lrem');
    cmp_ok($ns->llen($list), '==', 1, 'llen after lrem');

    cmp_ok($ns->lpop($list), 'eq', 'r1', 'lpop');

    ok(!$ns->rpop($list), 'rpop');

    $redis->flushall;
};

subtest 'Commands operating on sets' => sub {
    my $set = 'test-set';

    ok($ns->sadd($set, 'foo'), 'sadd');
    ok(!$ns->sadd($set, 'foo'), 'sadd');
    cmp_ok($ns->scard($set), '==', 1, 'scard');
    ok($ns->sismember($set, 'foo'), 'sismember');

    cmp_ok($ns->type($set), 'eq', 'set', 'type is set');
    cmp_ok($redis->type("ns:$set"), 'eq', 'set', 'type is set');

    ok($ns->srem($set, 'foo'), 'srem');
    ok(!$ns->srem($set, 'foo'), 'srem again');
    cmp_ok($ns->scard($set), '==', 0, 'scard');

    $ns->sadd('test-set1', $_) foreach ('foo', 'bar', 'baz');
    $ns->sadd('test-set2', $_) foreach ('foo', 'baz', 'xxx');

    my $inter = [sort('foo', 'baz')];

    is_deeply([sort $ns->sinter('test-set1', 'test-set2')], $inter, 'sinter');

    ok($ns->sinterstore('test-set-inter', 'test-set1', 'test-set2'), 'sinterstore');

    cmp_ok($ns->scard('test-set-inter'), '==', $#$inter + 1, 'cardinality of intersection');

    is_deeply([$ns->sdiff('test-set1', 'test-set2')], ['bar'], 'sdiff');
    ok($ns->sdiffstore(qw( test-set-diff test-set1 test-set2 )), 'sdiffstore');
    is($ns->scard('test-set-diff'), 1, 'cardinality of diff');

    my @union = sort qw( foo bar baz xxx );
    is_deeply([sort $ns->sunion(qw( test-set1 test-set2 ))], \@union, 'sunion');
    ok($ns->sunionstore(qw( test-set-union test-set1 test-set2 )), 'sunionstore');
    is($ns->scard('test-set-union'), scalar(@union), 'cardinality of union');

    my $first_rand = $ns->srandmember('test-set-union');
    ok(defined $first_rand, 'srandmember result is defined');
    ok(scalar grep { $_ eq $first_rand } @union, 'srandmember');
    my $second_rand = $ns->spop('test-set-union');
    ok(defined $first_rand, 'spop result is defined');
    ok(scalar grep { $_ eq $second_rand } @union, 'spop');
    is($ns->scard('test-set-union'), scalar(@union) - 1, 'new cardinality of union');

    my @test_set3 = sort qw( foo bar baz );
    $ns->sadd('test-set3', $_) foreach @test_set3;
    is_deeply([sort $ns->smembers('test-set3')], \@test_set3, 'smembers');

    $ns->smove(qw( test-set3 test-set4 ), $_) foreach @test_set3;
    is($ns->scard('test-set3'), 0, 'repeated smove depleted source');
    is($ns->scard('test-set4'), scalar(@test_set3), 'repeated smove populated destination');
    is_deeply([sort $ns->smembers('test-set4')], \@test_set3, 'smembers');
};

done_testing;

