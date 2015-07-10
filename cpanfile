requires 'perl', '5.010000';
requires 'Redis';
test_requires 'Test::More';
test_requires 'Test::RedisServer';
test_requires 'Test::Deep';
test_requires 'Test::Fatal';

on 'test' => sub {
   requires 'Test::More';
   requires 'Test::Exception';
   requires 'Test::Deep';
   requires 'Test::Fatal';
   requires 'File::Temp';
   requires 'Test::RedisServer';
   requires 'Test::Kwalitee';
   requires 'Test::Kwalitee::Extra';
};
