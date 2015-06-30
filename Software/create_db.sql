create table books(id integer primary key, name text, volume integer);
create table stories(id integer primary key, name text);
create table stories_in_books(id integer primary key, story_id integer, book_id integer, page_start integer, page_end integer, foreign key(story_id) references stories(id), foreign key(book_id) references books(id));
create table movements(id integer primary key, movers text, origin_place text, origin_time text, destination_place text, destination_time text, movement_mode text, purpose text, comment text, story_id integer, foreign key(story_id) references stories(id));
create table persons(id integer primary key, name text);
create table person_movement(movement_id integer, person_id integer, foreign key(movement_id) references movements(id), foreign key(person_id) references persons(id));
