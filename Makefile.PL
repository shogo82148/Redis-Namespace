use inc::Module::Install;
name 'Redis-Namespace';
all_from 'lib/Redis/Namespace.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
