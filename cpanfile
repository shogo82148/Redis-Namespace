requires 'Redis';

on 'test' => sub {
    requires 'Test::More';
    requires 'Test::RedisServer';
    requires 'Test::Spelling';
    requires 'Test::Perl::Critic';
};

on 'develop' => sub {
    requires 'Module::Install';
    requires 'Module::Install::CPANfile';
    requires 'Module::Install::AuthorTests';
    requires 'Module::Install::Repository';
};
