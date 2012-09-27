drop table if exists musics;
drop table if exists movies;
drop table if exists books;
drop table if exists friends;
drop table if exists users;

create table users (
  id                integer auto_increment,
  email        		varchar(255) not null,  
  myspace_id        varchar(255) not null,  
  username          varchar(255) not null,  
  image_location    varchar(255) null,    
  active 			int(1) default '0' not null,
  created_at datetime default NULL,
  updated_at datetime default NULL,
  primary key (id),
  INDEX (id)
) TYPE=InnoDB;

create table friends (
  id                integer auto_increment,
  user_id			integer not null,
  myspace_id        varchar(255) not null,  
  username          varchar(255) not null,  
  created_at datetime default NULL,
  updated_at datetime default NULL,  
  foreign key (user_id) references users(id) on delete cascade,
  primary key (id),
  INDEX (id),
  INDEX (user_id)
) TYPE=InnoDB;

create table musics (
  id                integer auto_increment,
  friend_id			integer not null,
  myspace_id		integer not null,    
  name				varchar(255) not null,
  foreign key (friend_id) references friends(id) on delete cascade,
  primary key (id),
  INDEX (id),
  INDEX (friend_id),
  INDEX (name),
  INDEX (myspace_id)
) TYPE=InnoDB;

create table movies (
  id                integer auto_increment,
  friend_id			integer not null,
  myspace_id		integer not null,    
  name				varchar(255) not null,
  foreign key (friend_id) references friends(id) on delete cascade,
  primary key (id),
  INDEX (id),
  INDEX (friend_id),
  INDEX (name),
  INDEX (myspace_id)  
) TYPE=InnoDB;

create table books (
  id                integer auto_increment,
  friend_id			integer not null,
  myspace_id		integer not null,    
  name				varchar(255) not null,
  foreign key (friend_id) references friends(id) on delete cascade,
  primary key (id),
  INDEX (id),
  INDEX (friend_id),
  INDEX (name),
  INDEX (myspace_id)    
) TYPE=InnoDB;

