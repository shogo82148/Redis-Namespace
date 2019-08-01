requires 'perl', '5.010000';
requires 'Redis';

on 'test' => sub {
   requires 'JSON';
   requires 'Furl';
   requires 'Test::More';
   requires 'Test::Exception';
   requires 'Test::Deep';
   requires 'Test::Fatal';
   requires 'Test::TCP';
   requires 'File::Temp';
   requires 'Test::RedisServer';
   requires 'Test::Kwalitee';
   requires 'Test::Kwalitee::Extra';
};
