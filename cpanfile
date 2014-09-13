requires 'perl', '5.008001';
requires 'Redis';
test_requires 'Test::More';
test_requires 'Test::RedisServer';

on 'test' => sub {
   requires 'Test::More';
   requires 'Test::Exception';
   requires 'File::Temp';
   requires 'Test::RedisServer';
   requires 'Test::Kwalitee';
   requires 'Test::Kwalitee::Extra';
};
