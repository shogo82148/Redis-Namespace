requires 'Redis';
test_requires 'Test::More';
test_requires 'Test::RedisServer';

on 'develop' => sub {
    requires 'Module::Install';
    requires 'Module::Install::CPANfile';
    requires 'Module::Install::AuthorTests';
    requires 'Module::Install::Repository';
};
