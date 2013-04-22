requires 'perl', '5.008001';

requires 'Plack';
requires 'YAML';
requires 'Text::MicroTemplate';
requires 'Pod::Usage';
requires 'parent';

on test => sub {
    requires 'Test::More', 0.98;
};

on configure => sub {
};

on 'develop' => sub {
};

