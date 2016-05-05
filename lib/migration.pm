package migration;
use Dancer2;
use Dancer2::Plugin::DBIC qw(schema resultset rset);


use DBIx::Class::Schema::Loader qw/ make_schema_at /;

use DateTime;



use Dancer2::Plugin::Auth::Extensible;

use Dancer2::Plugin::Database;
use Dancer2::Plugin::Auth::Extensible::Provider::DBIC;
use Dancer2::Session::Cookie;
use Crypt::Digest;


use Crypt::PBKDF2;


    

our $VERSION = '0.1';
#set 'session'  => 'Simple';


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
	my @post_index = ();
	@post_index = &show_posts;
	
    template 'index' ,{ results => \@results,
    					post_index => \@post_index,
    			};
};

get '/register' => sub {
	template 'user/register';
};

post '/register' => sub {
	

	my $username = params->{username};
	my $fullname = params->{fullname};
	my $password = params->{password};
	warn "The pass is |$password|\n";

	
		my $saved_pass = &crypt_password($password);   
	


	$schema->resultset('User')->create({
		username => $username, 
		fullname => $fullname,
		password => $saved_pass,

	});	

	redirect '/';

};



post '/login' => sub {
    my $username  = params->{username};
    my $password  = params->{password}; 
    
    

     my $user = $schema->resultset('User')->search({ username => $username })->first;       

     	
    	

    	my ($success, $realm) = authenticate_user(
            $username, $password
        );

        
        if ($success) {
            session logged_in_user => $success;
            session logged_in_user_realm => $realm;
            session user => $user;

            
            
        } else {
             authentication failed
        } 		
    
   	 

};

get '/admin' => require_login  sub{
	my @results = ();
	@results = &show_posts;

	my @post_index = ();
	@post_index = &show_posts;
	
	my @comments = ();
	@comments = &show_comments;
	my @comments_per_posts = ();
	my $username = logged_in_user->{id};
	
	 
	template 'admin', {
		results => \@results,
		comments => \@comments,
		post_index => \@post_index,
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
   		
   		redirect '/';
	}
	else
	{
		redirect '/admin';
	}
};


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
	my $user = params->{'username'};
	
	
	my $role_id = $schema->resultset('Role')->search({ role => $role })->first->id;
	my $username = $schema->resultset('User')->search({ username => $user})->first;
	
	

	$schema->resultset('UserRole')->create({
			user_id => $username->id,
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
	


	
	
	template 'delete_post', {
		results => \@post_to_delete,
	};


	
	
};

post '/post_delete/:id' => require_role admin => sub{
	my $id =  param 'id';

	my $delete = params->{'delete_post'};
	
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

	my @post_index = ();
	@post_index = &show_posts;
	push @single_post, grep{$_->{id} == $id} @results;

	my @comments = ();
	@comments =  &show_comments;
	my @show_comments = ();

	push @show_comments, grep{ $_  } @comments;
	
	
	template 'single_post', {
		results => \@single_post,
		comments => \@show_comments,
		post_index => \@post_index,
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
	my $route = "/single_post/$id";
	
	my $title = params->{"title"};
	
	
	my $content = params->{"content"};
	
	my $edit = $schema->resultset('Post')->find({id => $id });
	
	$edit->update({
		title => $title,
		content => $content,
	});


	 
	
	redirect $route;

		

};

get '/create_comment/:id' => require_login sub{

	

	template 'create_comment';
		
	
};
post '/create_comment/:id'=> require_login sub{
	my $id = param 'id';
	my $route = "/single_post/$id";
	
	my $content = params->{'content'};
	$schema->resultset('Comment')->create({
		content => $content,
		post_id => $id,
		user_id => logged_in_user->{id},
		created_at => DateTime->now->iso8601,
		
	});

	
	redirect $route;

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
	my $post_id = params->{'delete'};
	
	my $route = "/single_post/$post_id";


	
	

	if($delete eq 'yes' )
	{
		$schema->resultset('Comment')->find({id => $id })->delete;
		
		redirect $route;
	}
	
	redirect $route;
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
	my $post_id = params->{"post_id"};
	my $route = "/single_post/$post_id";
	my $edit_comment = $schema->resultset('Comment')->find({id => $id });

	$edit_comment->update({
			content => $content,
		});
	redirect $route;

};


true;
