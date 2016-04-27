use strict;
use warnings;

use MyDatabase 'db_handle';

my $dbh = db_handle('moblo.db');
my $posts =<<"SQL";

CREATE TABLE IF NOT EXISTS posts(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	author TEXT,
	title  TEXT,
	content TEXT,
	date_published VARCHAR(30),
	author_id INTEGER,
	FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
	
	

);
SQL
$dbh->do($posts);


my $users =<<"SQL";

CREATE TABLE IF NOT EXISTS users(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	pw_hash TEXT,
	username TEXT UNIQUE,
	fullname TEXT
);
SQL
$dbh->do($users);


my $comments =<<"SQL";

CREATE TABLE IF NOT EXISTS comments(
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	post_id INTEGER,
	user_id INTEGER,
	created_at VARCHAR(30),
	content TEXT,
	FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE ON UPDATE CASCADE
	FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
);
SQL
$dbh->do($comments);



