package migration;
use Dancer2;
use Dancer2::Plugin::DBIC qw(schema resultset rset);
#use lib::My::Schema;
use Dancer2::Plugin::Passphrase;
use DBIx::Class::Schema::Loader qw/ make_schema_at /;
#use Dancer2::Plugin::Auth::Tiny;
use DateTime;
use Data::Dumper;

#test
#use Dancer2::Session::Memcached;
use Dancer2::Plugin::Auth::Extensible;
#use Dancer2::Plugin::Auth::Extensible::Provider::Database;
use Dancer2::Plugin::Database;
use Dancer2::Plugin::Auth::Extensible::Provider::DBIC;
use Crypt::Digest;
use Term::ReadPassword::Win32;
use Getopt::Long;
use Crypt::PBKDF2;


    #DBIx::Class::Schema::Loader->naming('v7');

our $VERSION = '0.1';
set 'session'  => 'Simple';


my $schema = My::Schema->connect('dbi:SQLite:moblo.db');
#my $schema = schema 'moblo';

sub show_posts{
	#my $id = shift;
	my @posts = $schema->resultset('Post')->all;
	my @result;
	
	
		push @result, map{ 
						{ 
							
							title => $_->title,
							content => $_->content,
							author => $_->author,
							date_published => $_->date_published,
							id => $_->id,	
		 				}
		 }@posts;	 
	  
	return @result;
}

sub show_roles{
	my @roles = $schema->resultset('Role')->all;
	my @result_roles;

	push @result_roles, map{
		{
			role => $_->role,
			id => $_->id,
		}	
	}@roles;

	return @result_roles;
}

sub show_comments{
	my @comments = $schema->resultset('Comment')->all;
	my @comment_result;

	push @comment_result, map{
		{
			id => $_->id,
			post_id  => $_->post_id,
			user_id => $_->user_id,
			created_at => $_->created_at,
			content  => $_->content,


		}
	} @comments;

	return @comment_result;
}

#sub hashing {
	#my $self = shift;
	
	#my $pbkdf2 = Crypt::PBKDF2->new(
		#hash_class => 'HMACSHA2',
	#);

	#return $pbkdf2;
#}

sub crypt_password{
	my $password = shift;

	my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
	$csh->add($password);
	my $salted = $csh->generate;

	return $salted;

	
}

get '/' => sub {
	my @results = ();
	@results = &show_posts;
	
    template 'index' ,{ results => \@results,};
};

get '/register' => sub {
	template 'user/register';
};

post '/register' => sub {
	

	my $username = params->{username};
	my $fullname = params->{fullname};
	my $password = params->{password};
	warn "The pass is |$password|\n";

	#my $password_as_arg = 
	#GetOptions(
				#'password=s' => \$password,
	#) or die "Could not parse options";
	#my  $cmd = "generate-crypted-password";
	#my $program = system( $cmd );
	#my $saved_pass;

	#if(@ARGV){
		#my $args = @ARGV;
		my $saved_pass = &crypt_password($password);  #system("sh"," $cmd","--pasword" ); 
		warn "crypted pass is |$saved_pass|\n";
	#}
	

	#my $saved_pass = passphrase($password)->generate;



	$schema->resultset('User')->create({
		username => $username, 
		fullname => $fullname,
		password => $saved_pass,#$password, #$saved_pass->rfc2307,

	});	

	redirect '/';

};

#get '/login' => sub{
	#template 'loginform' => {};

#};

post '/login' => sub {
    my $username  = params->{username};
    my $password  = params->{password}; 
    my $pass_to_check = &crypt_password($password);
    warn $pass_to_check;

     my $user = $schema->resultset('User')->search({ username => $username })->first;       

     	
    	#if($user && passphrase($password)->matches($user->password) && $username eq $user->username)
     	#{
     		#my $redir_url = param('redirect_url') || '/admin';
     	
    		#
    		#warn "The is is:\n";
    		#warn session('user')->id;
    		#redirect $redir_url;
    	#}
    	#else
    	#{
    		#"wrong user name or password "
    	#}

    	my ($success, $realm) = authenticate_user(
            $username, $password
        );

        #warn "This shuld be 1 |$success|\n";
        if ($success) {
            session logged_in_user => $success;
            session logged_in_user_realm => $realm;
            session user => $user;

             #other code here
            # redirect '/admin';
            
        } else {
             authentication failed
        } 		
    
   	   #my $user = logged_in_user;
	 #return "Hi there, $user->{username}";

};

get '/admin' => require_login  sub{
	my @results = ();
	@results = &show_posts;
	warn "The results are :|@results|\n";
	my @comments = ();
	@comments = &show_comments;
	my @comments_per_posts = ();
	my $username = logged_in_user->{id};
	warn "The role is :\n";
    warn  user_has_role $username;
	 
	template 'admin', {
		results => \@results,
		comments => \@comments,
	};
};

get '/logout' =>   sub{
	template 'logout';
};

post 'logout' =>  sub{
	my $logout = params->{"stay/leave"};

	if($logout eq 'yes')
	{
		app->destroy_session;
   		#set_flash('You are logged out.');
   		redirect '/';
	}
	else
	{
		redirect '/admin';
	}
};
#declarinag a session
#set 'session'  => 'Simple';
#storing a user name and a pass inside it
#set 'username' => 'admin';
#set 'password' => 'foo';

#pasing the forms params via the post request
#get '/loginform' => needs login => sub{
	#my $err;
	
	 
	#if(request->method() eq "POST" ){
		#if(params->{'username'} ne setting('username'))
		#{
		 	#$err = "Invalid username";
		 	#my $username = params->{'username'};
		 	#my $password = params->{'password'};
		 	#warn "the name is |$name|\n";
		#}
		#elsif(params->{'password'} ne setting('password')){
			#$err = "Invalid password";

		#}
		#else{
		 	#session 'logged_in' => true;
		 	 #template 'admin';
		 	 #return 'Only authenticated users should be able to see this page';
		#}
	#}
	#if(authenticate_user $username, $password)
	#{
		#return $content;
	#}

	#
	#template 'admin' => {};
	
	
#};

#post '/loginform' => sub{
	#t#emplate 'admin';
#};	

get '/contact' => sub{
	template 'contact';
};

get '/create_role' => sub{
	template 'create_role';
};
post '/create_role' => sub{
	my $role = params->{'role'};

	$schema->resultset('Role')->create({
		role => $role,
	});

	redirect '/admin';
};

get '/asign_role' => sub{
	my @roles_to_asign = ();
	@roles_to_asign = &show_roles;
	template 'asign_roles', {
		roles_to_asign => \@roles_to_asign,
	};
};

post '/asign_role' => sub{
	my $role =  params->{'asign_role'};
	warn "The role param is |$role|\n";
	my $role_id = $schema->resultset('Role')->search({ role => $role })->first->id;
	warn "the role id is |$role_id|\n";

	$schema->resultset('UserRole')->create({
			user_id => logged_in_user->{id},
			role_id => $role_id,

		});
	redirect '/admin';
};

get '/create_post' =>  require_role admin => sub{
	
	template 'create_post';
};

post '/create_post'=> require_role admin => sub{
	my $self = shift;
	
		my $title = params->{'title'};
		my $content = params->{'content'};
		
		

		$schema->resultset('Post')->create({
		title => $title,
		content => $content,
		author => logged_in_user,
		author_id => logged_in_user->{id},
		date_published => DateTime->now->iso8601,
		
	});

		redirect '/admin';

};

get '/post_delete/:id' => require_role admin => sub{
	my $id = param 'id';
	my @results = ();
	@results = &show_posts;
	my @post_to_delete = ();

	

	push @post_to_delete, grep{ $_->{id} == $id } @results;
	


	
	warn "The results are :|@results|\n";
	template 'delete_post', {
		results => \@post_to_delete,
	};


	
	
};

post '/post_delete/:id' => require_role admin => sub{
	my $id =  param 'id';
	my $delete = params->{'delete_post'};
	#my $cancel_delete = params->{'no'};
	
	#warn "The id is : |$id\n|";
	if($delete eq 'yes' )
	{
		$schema->resultset('Post')->find({id => $id })->delete;
		redirect '/admin';
	}
	
	redirect '/admin';

};

get '/single_post/:id' =>  sub{
	my $id = param 'id';
	my @results = ();
	@results = &show_posts;
	my @single_post = ();
	push @single_post, grep{$_->{id} == $id} @results;
	
	template 'single_post', {
		results => \@single_post,
	};
};

get '/post_edit/:id' => require_role admin => sub{
	my $id = param 'id';
	my @results = ();
	@results = &show_posts;
	my @post_to_edit = ();

	push @post_to_edit, grep{$_->{id} == $id} @results;
								


				

	template 'edit_post', {
			results => \@post_to_edit,
	};
	

};
post '/post_edit/:id' => require_role admin => sub{
	my $id = param 'id';
	#warn "the post_id is:|$id |\n";
	my $title = params->{"title"};
	#warn "the title is is:|$title |\n";
	
	my $content = params->{"content"};
	#warn "the title is is:|$content |\n";
	my $edit = $schema->resultset('Post')->find({id => $id });
	
	$edit->update({
		title => $title,
		content => $content,
	});

	redirect '/admin';	

};

get '/create_comment/:id' => require_login sub{

	

	template 'create_comment';
		
	
};
post '/create_comment/:id'=> require_login sub{
	my $id = param 'id';
	
	my $content = params->{'content'};
	$schema->resultset('Comment')->create({
		content => $content,
		post_id => $id,
		user_id => logged_in_user->{id},
		created_at => DateTime->now->iso8601,
		
	});

	# session('user')->id,
		#user_id => session('user')->id,

	redirect '/admin';

};

get '/delete_comment/:id' => require_login sub{
	my $id = param 'id';
	my @comments = ();
	@comments =  &show_comments;
	my @deleted_comments = ();

	push @deleted_comments, grep{ $_->{id} == $id } @comments;

	template 'delete_comment', {
		deleted_comments => \@deleted_comments,
	};
};


post '/delete_comment/:id' => require_login sub{
	my $id =  param 'id';
	my $delete = params->{'delete_comment'};

	if($delete eq 'yes' )
	{
		$schema->resultset('Comment')->find({id => $id })->delete;
		redirect '/admin';
	}
	
	redirect '/admin';
};

get '/edit_comment/:id' => require_login sub{
	my $id = param 'id';
	my @comments_to_edit = ();
	@comments_to_edit = &show_comments;

	my @edited_comments = ();
	push @edited_comments, grep{ $_->{id} == $id } @comments_to_edit;

	template 'edit_comment', {
		edited_comments => \@edited_comments,
	};
};

post '/edit_comment/:id' => require_login sub{
	my $id = param 'id';

	my $content = params->{"content"};
	my $edit_comment = $schema->resultset('Comment')->find({id => $id });

	$edit_comment->update({
			content => $content,
		});
	redirect '/admin';

};


true;
