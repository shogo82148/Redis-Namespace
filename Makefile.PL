use inc::Module::Install;

name 'Redis-Namespace';
all_from 'lib/Redis/Namespace.pm';

tests 't/*.t';
author_tests 'xt';

auto_include;
do 'cpanfile';
WriteAll;
