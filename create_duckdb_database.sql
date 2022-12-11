create table users as select * from read_parquet('/Volumes/Extreme SSD/stackoverflow/users/users*');
create table posts_questions as select * from read_parquet('/Volumes/Extreme SSD/stackoverflow/posts_questions/post_questions*') where creation_date >= '2021-12-01';
create table posts_answers as select * from read_parquet('/Volumes/Extreme SSD/stackoverflow/posts_answers/posts_answers*') where creation_date >= '2021-12-01';
create table post_history as select * from read_parquet('/Volumes/Extreme SSD/stackoverflow/post_history/post_history*') where creation_date >= '2021-12-01';
create table comments as select * from read_parquet('/Volumes/Extreme SSD/stackoverflow/comments/comments*') where creation_date >= '2021-12-01';
create table votes as select * from read_parquet('/Volumes/Extreme SSD/stackoverflow/votes/votes*') where creation_date >= '2021-12-01';

create view users as select * from read_parquet('users/users*');
create view posts_questions as select * from read_parquet('posts_questions/post_questions*');
create view posts_answers as select * from read_parquet('posts_answers/posts_answers*');
create view post_history as select * from read_parquet('post_history/post_history*');
create view comments as select * from read_parquet('comments/comments*');
create view votes as select * from read_parquet('votes/votes*');

create or replace view users as select * from read_parquet('/Users/ergestxheblati/Documents/data_projects/stackoverflow/parquet_files/users.parquet');
create or replace view posts_questions as select * from read_parquet('/Users/ergestxheblati/Documents/data_projects/stackoverflow/parquet_files/post_questions.parquet');
create or replace view posts_answers as select * from read_parquet('/Users/ergestxheblati/Documents/data_projects/stackoverflow/parquet_files/posts_answers.parquet');
create or replace view post_history as select * from read_parquet('/Users/ergestxheblati/Documents/data_projects/stackoverflow/parquet_files/post_history.parquet');
create or replace view comments as select * from read_parquet('/Users/ergestxheblati/Documents/data_projects/stackoverflow/parquet_files/comments.parquet');
create or replace view votes as select * from read_parquet('/Users/ergestxheblati/Documents/data_projects/stackoverflow/parquet_files/votes.parquet');
