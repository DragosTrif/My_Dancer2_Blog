package Login::Login;
#use Dancer2;
#my $schema = schema 'moblo';


sub user_exists{
	my ( $username, $password ) = @_;

	my $user = $schema->resultset('User')->find({ username => $username
            });

	 return (
        defined $user && passphrase($password)
    );

	#my $user = $self->app->db->resultset('User')->search({ username => $username })->first;
}

1;