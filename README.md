## Convert JMdict + kanjidic2.xml + kradfile-u into SQLite database

### Content

Only words that have kanji in them go into database, but it's fairly simple to modify the script to generate full dictionary.

### Requirements

It takes about 1.4 G of memory to process files.

Debian, Ubuntu: apt-get install libxml-libxml-perl

Arch: pacman -S perl-xml-libxml

### Database structure

           .----------.       .-------------.      .------------.
           | radicals |       |    kanji    |      | kanjiwords |
           |----------|       |-------------|      |------------|
    .----->| id       |     .>| id          |<-----| kanji_id   |
    |      | radical  |     | | character   |      | word_id    |------.
    |      | type     |     | | reading_on  |      '------------'      |
    |      | meaning  |     | | reading_kun |   .------------------.   |
    |      '----------'     | | meaning     |   |      words       |   |
    |   .---------------.   | '-------------'   |------------------|   |
    |   | kanjiradicals |   |                   | id               |<--'
    |   |---------------|   |                   | kanji_reading    |
    |   | kanji_id      |---'                   | hiragana_reading |
    '---| radical_id    |                       | meaning          |
        '---------------'                       | length           |
                                                | character_count  |
                                                | common           |
                                                | irregular        |
                                                | ent_seq          |
                                                '------------------'

### Get files

kradfile-u http://www.kanjicafe.com/downloads/kradfile-u.gz

JMdict ftp://ftp.monash.edu.au/pub/nihongo/JMdict.gz

kanjidic2.xml http://www.edrdg.org/kanjidic/kanjidic2.xml.gz

kangxi_radicals are based on https://en.wikipedia.org/wiki/Kangxi_radical

```
wget http://www.kanjicafe.com/downloads/kradfile-u.gz ftp://ftp.monash.edu.au/pub/nihongo/JMdict.gz http://www.edrdg.org/kanjidic/kanjidic2.xml.gz
```

#### Unpack

`
gzip -d *gz
`

### Generate dumps

`
perl generate_dict.pl
`

### Import dumps into sqlite

```
sqlite3 dictionary.db < database_structure.sql
sqlite3 dictionary.db < import.sql 
```

### Clean

```
rm {KANJI,KANJIRADICALS,KANJIWORDS,RADICALS,WORDS}_IMPORT
```
