#!/usr/bin/env python3
"""Build and validate the offline FTS5 index from reviewed bundled content."""
import json
import pathlib
import sqlite3
import re
import unicodedata

ROOT = pathlib.Path(__file__).resolve().parents[1]
RESOURCES = ROOT / 'Ananta' / 'Resources'

def load(name):
    return json.loads((RESOURCES / f'{name}.json').read_text())

def main():
    books, entries, lessons = load('library'), load('knowledge'), load('lessons')
    path = RESOURCES / 'search.sqlite'
    staging = path.with_suffix('.building')
    staging.unlink(missing_ok=True)
    db = sqlite3.connect(staging)
    db.execute('PRAGMA journal_mode=OFF')
    db.execute('PRAGMA synchronous=OFF')
    db.execute("CREATE VIRTUAL TABLE search USING fts5(id UNINDEXED, kind UNINDEXED, title, subtitle, body, bookID UNINDEXED, chapterID UNINDEXED, passageID UNINDEXED, aliases, tokenize='unicode61 remove_diacritics 2', prefix='2 3 4')")
    rows = []
    for book in books:
        rows.append((book['id'], 'Book', book['title'], f"{book['category']} · {book['coverage']}", ' '.join([book['subtitle'], book['summary'], book['whyRead'], book['tradition']]), book['id'], '', ''))
        for chapter in book['chapters']:
            for passage in chapter['passages']:
                rows.append((f"passage:{book['id']}:{chapter['id']}:{passage['id']}", 'Passage', book['title'], f"{chapter['title']} · {passage['reference']}", passage['text'], book['id'], chapter['id'], passage['id']))
    for entry in entries:
        rows.append((entry['id'], 'Atlas', ' '.join([entry['name'], entry['sanskrit'], *entry['aliases']]), entry['subtitle'], ' '.join([entry['summary'], *(s['text'] for s in entry['body']), *entry['traditions']]), '', '', ''))
    for lesson in lessons:
        rows.append((lesson['id'], 'Lesson', lesson['title'], f"Lesson {lesson['number']} · {lesson['subtitle']}", ' '.join(s['text'] for s in lesson['sections']), '', '', ''))
    assert len({r[0] for r in rows}) == len(rows), 'Search IDs must be globally unique'
    spellings = {'krsna': 'krishna', 'siva': 'shiva', 'visnu': 'vishnu', 'laksmi': 'lakshmi', 'rsi': 'rishi', 'rsis': 'rishis', 'brhadaranyaka': 'brihadaranyaka', 'rta': 'rita'}
    def aliases(row):
        text = ''.join(c for c in unicodedata.normalize('NFD', ' '.join(row[2:5]).lower()) if unicodedata.category(c) != 'Mn')
        return ' '.join(sorted({spellings[word] for word in re.findall(r'\w+', text) if word in spellings}))
    db.executemany('INSERT INTO search VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', [(*row, aliases(row)) for row in rows])
    db.execute("INSERT INTO search(search) VALUES ('optimize')")
    db.commit()
    assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
    for term in ('dharma', 'Krishna', 'Kṛṣṇa', 'creation', 'self'):
        count = db.execute('SELECT count(*) FROM search WHERE search MATCH ?', (f'"{term}"*',)).fetchone()[0]
        assert count > 0, f'No search matches for {term}'
        print(f'{term}: {count:,} matches')
    counts = dict(db.execute('SELECT kind, count(*) FROM search GROUP BY kind'))
    db.close()
    staging.replace(path)
    print(json.dumps({'indexed': counts, 'size_mb': round(path.stat().st_size / 1048576, 1), 'path': str(path)}, indent=2))

if __name__ == '__main__':
    main()
