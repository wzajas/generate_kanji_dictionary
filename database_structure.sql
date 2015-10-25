CREATE TABLE kanji (
 id integer,
 character varchar(1),
 reading_on varchar(255),
 reading_kun varchar(255),
 meaning varchar(255)
);
CREATE TABLE kanjiradicals (
 kanji_id integer,
 radical_id integer,
 foreign key (kanji_id) references kanji(id),
 foreign key (radical_id) references radicals(id)
);
CREATE TABLE radicals (
 id integer,
 radical varchar(1),
 type varchar(1),
 meaning varchar(255));
CREATE TABLE words (
 id integer,
 kanji_reading varchar(255),
 hiragana_reading varchar(255),
 meaning varchar(255),
 length integer,
 character_count integer,
 common integer,
 irregular integer,
 ent_seq integer
);
CREATE TABLE kanjiwords (
 kanji_id integer,
 word_id varchar(255),
 foreign key (kanji_id) references kanji(id),
 foreign key (word_id) references words(id)
);

CREATE INDEX idx1 on words(id);
CREATE INDEX idx2 on kanjiwords(kanji_id);
CREATE INDEX idx3 on kanjiwords(word_id);
CREATE INDEX idx4 on kanjiwords(kanji_id,word_id);
CREATE INDEX idx5 on words(ent_seq);
