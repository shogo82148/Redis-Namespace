# NAME

Redis::Namespace - a wrapper of Redis.pm that namespaces all Redis calls

# SYNOPSIS

    use Redis;
    use Redis::Namespace;
    
    my $redis = Redis->new;
    my $ns = Redis::Namespace(redis => $redis, namespace => 'fugu');
    
    $ns->set('foo', 'bar');
    # will call $redis->set('fugu:foo', 'bar');
    
    my $foo = $ns->get('foo');
    # will call $redis->get('fugu:foo');

# DESCRIPTION

Redis::Namespace is a wrapper of Redis.pm that namespaces all Redis calls.
It is useful when you have multiple systems using Redis differently in your app.

# AUTHOR

Ichinose Shogo <shogo82148@gmail.com>

# SEE ALSO

- [Redis](http://redis.io/)
- [Redis.pm](https://github.com/melo/perl-redis)
- [redis-namespace](https://github.com/resque/redis-namespace)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
