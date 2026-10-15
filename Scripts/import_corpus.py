#!/usr/bin/env python3
"""Rebuild the offline library from pinned public-domain source snapshots.

Uses only Python's standard library unless --download needs to extract the Rig
Veda PDF (pypdf). Existing checked-in TXT snapshots make offline rebuilds possible.
The script fails rather than silently publishing a structurally incomplete text.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / 'SourcesArchive'
OUT = ROOT / 'Ananta' / 'Resources' / 'library.json'
SOURCES = {
    'vishnu-66208.txt': 'https://www.gutenberg.org/cache/epub/66208/pg66208.txt',
    'yajur-keith.zip': 'https://www.radha.name/sites/default/files/documents/1249/Yajur%20Veda%20-%20transl.%20by%20Keith%201914.zip',
    'white-yajur-griffith.html': 'https://www.globalgreyebooks.com/online-ebooks/ralph-t-h-griffith_texts-of-the-white-yajurveda_complete-text.html',
    'upanishads-muller-1.html': 'https://www.globalgreyebooks.com/online-ebooks/friedrich-max-muller_upanishads-part-1_complete-text.html',
    'atharva-griffith.pdf': 'https://rootshunt.com/aryans/zoroastrianandaryans/vedsinenglish/atharvved/hymns-of-the-atharv-ved.pdf',
    'four-vedas.pdf': 'https://muugumuugu.github.io/bOOkshelF/literature/Four%20Vedas%20-%20English%20Translation.pdf',
    'yoga-2526.txt': 'https://www.gutenberg.org/cache/epub/2526/pg2526.txt',
    'upanishads-3283.txt': 'https://www.gutenberg.org/cache/epub/3283/pg3283.txt',
    'ramayana-24869.txt': 'https://www.gutenberg.org/cache/epub/24869/pg24869.txt',
    **{f'mahabharata-{n}.txt': f'https://www.gutenberg.org/cache/epub/{n}/pg{n}.txt' for n in range(15474,15478)},
    'rigveda-griffith.pdf': 'https://www.mystika.cz/texty/rgveda-eng.pdf',
}
PD = 'Public-domain historical translation in the USA. Edition and transcription limitations apply; see source colophon.'
GUIDE = 'Original Hindu App catalog description; linked editions retain their own rights. No translated text bundled.'
ST = 'https://archive.sacred-texts.com/hin/'
GRETIL = 'https://gretil.sub.uni-goettingen.de/gretil.html'
TAMIL = 'https://www.projectmadurai.org/pmworks.html'

def roman(s):
    values = dict(I=1,V=5,X=10,L=50,C=100,D=500,M=1000)
    if s.isdigit(): return int(s)
    return sum(-values[c] if i+1<len(s) and values[c]<values[s[i+1]] else values[c] for i,c in enumerate(s))

def clean(s):
    s = re.sub(r'\[\d+\]', '', s)
    s = re.sub(r'\(\d+\)', '', s)
    s = re.sub(r'(?m)^<\d+>\s*$', '', s)
    s = re.sub(r'\[\(Bhagavad Gita[^\n]*\)\]', '', s)
    s = re.sub(r'\(\[This where is the Bhagavad Gita proper starts.*?\]\)', '', s, flags=re.S)
    return s.strip()

def text_source(name):
    s = (ARCHIVE / name).read_text(encoding='utf-8-sig')
    if '*** START' in s:
        s = re.split(r'\*\*\* START[^\n]*\n', s, maxsplit=1)[1]
        s = re.split(r'\*\*\* END[^\n]*', s, maxsplit=1)[0]
    return s.strip()

def chunks(s, maximum=1350):
    """Keep every word; group paragraphs or split long ones on whitespace."""
    paragraphs = [re.sub(r'[ \t]+', ' ', x.strip()) for x in re.split(r'\n\s*\n',clean(s)) if x.strip()]
    output=[]; current=''
    for paragraph in paragraphs:
        # Print line-wrapping is not a semantic verse boundary. Retain paragraph breaks.
        paragraph = re.sub(r'\s*\n\s*',' ',paragraph)
        parts=[]
        while len(paragraph)>maximum:
            cut=paragraph.rfind(' ',0,maximum+1)
            if cut<1: cut=maximum
            parts.append(paragraph[:cut]); paragraph=paragraph[cut:].lstrip()
        if paragraph: parts.append(paragraph)
        for part in parts:
            if current and len(current)+len(part)+2>maximum:
                output.append(current);current=''
            current = current+'\n\n'+part if current else part
    if current: output.append(current)
    assert ''.join(''.join(paragraphs).split()) == ''.join(''.join(output).split()), 'Chunking lost text'
    return output

def chapter(cid,title,summary,body,reference):
    return dict(id=cid,title=title,summary=summary,passages=[dict(id=f'{cid}-p{i:04}', reference=f'{reference} · passage {i}', text=t) for i,t in enumerate(chunks(body),1)])

def book(bid,title,subtitle,category,tradition,summary,why,translation,url,coverage,symbol,chapters,entities):
    return dict(id=bid,title=title,subtitle=subtitle,category=category,tradition=tradition,summary=summary,whyRead=why,translation=translation,sourceURL=url,license=GUIDE if coverage=='Catalog guide' else PD,coverage=coverage,symbol=symbol,chapters=chapters,relatedEntityIDs=entities)

PARVAS = ['Adi','Sabha','Vana','Virata','Udyoga','Bhishma','Drona','Karna','Shalya','Sauptika','Stri','Shanti','Anushasana','Ashvamedhika','Ashramavasika','Mausala','Mahaprasthanika','Svargarohana']
GITA_TITLES = ['Arjuna’s dilemma','Self and discernment','Action without attachment','Knowledge and action','Renunciation and action','The discipline of meditation','Knowing the divine','The imperishable','Knowledge and devotion','Divine manifestations','The universal form','The path of devotion','The field and its knower','The three qualities','The supreme person','Divine and destructive qualities','Three kinds of faith','Freedom through renunciation']

def mahabharata():
    books={}; allchapters=[]; gitachapters=[]
    section_counts=[]
    for number in range(15474,15478):
        s=text_source(f'mahabharata-{number}.txt')
        starts=list(re.finditer(r'(?m)^BOOK (\d+)\s*$',s))
        for index,start in enumerate(starts):
            bn=int(start[1]); body=s[start.end():starts[index+1].start() if index+1<len(starts) else len(s)]
            body=re.split(r'(?m)^FOOTNOTES\s*$',body,maxsplit=1)[0]
            sections=list(re.finditer(r'(?m)^[ \t]*(?:SECTION )?([IVXLCDM]+|[0-9]+)(?:-([IVXLCDM]+))?[ \t]*$',body))
            assert sections, f'No sections for Mahabharata book {bn}'
            nums=[roman(x[1]) for x in sections]
            assert len(set(nums))==len(nums), f'Duplicate section in book {bn}'
            section_counts.append((bn,len(sections)))
            books[bn]=[]
            for i,m in enumerate(sections):
                sn=roman(m[1]); content=body[m.end():sections[i+1].start() if i+1<len(sections) else len(body)]
                cid=f'mahabharata-{bn:02}-{sn:03}'
                c=chapter(cid,f'{bn}. {PARVAS[bn-1]} · Section {sn}'+(f'–{roman(m[2])}' if m[2] else ''),f'Book {bn}: {PARVAS[bn-1]} Parva. Ganguli’s historical prose translation. Reading passages are app subdivisions, not Sanskrit verse numbers.',content,f'Mahabharata {bn}.{sn}')
                assert c['passages']
                books[bn].append(c);allchapters.append(c)
                if bn==6 and 25<=sn<=42:
                    gn=sn-24
                    gitachapters.append(chapter(f'bhagavad-gita-{gn:02}',f'{gn}. {GITA_TITLES[gn-1]}','Ganguli’s translation. Paragraph references identify reading passages; this edition does not number each Sanskrit verse.',content,f'Bhagavad Gita, chapter {gn}'))
    assert sorted(books)==list(range(1,19))
    assert len(gitachapters)==18
    # Snapshot section counts prevent accidentally shipping truncated downloads.
    expected=[235,79,313,72,199,124,200,96,65,18,27,363,168,92,39,8,3,6]
    actual=[len(books[n]) for n in range(1,19)]
    assert actual==expected, f'Mahabharata counts changed: {actual}; review upstream source before changing assertion'
    gita=book('bhagavad-gita','Bhagavad Gita','A conversation at the edge of a battlefield','Epics','Shared across many Hindu traditions; central to Vaishnava traditions','Arjuna’s crisis becomes a dialogue with Krishna about action, the self, devotion, and liberation. All 18 chapters of Ganguli’s translation are bundled. Different Vedanta schools interpret its teaching differently.','A compact entry into the questions of duty, identity, and devotion that recur throughout Hindu literature.','Kisari Mohan Ganguli, 1883–1896','https://www.gutenberg.org/ebooks/15475','Complete translation','sun.max',gitachapters,['krishna','arjuna','vyasa','sanjaya','dhritarashtra'])
    maha=book('mahabharata','Mahabharata','Family, power, and the difficulty of dharma','Epics','Itihasa; many Hindu traditions','The struggle between the Pandavas and Kauravas includes philosophical dialogues, pilgrimages, legends, and the consequences of war. All 18 parvas from this Ganguli digital edition are included. The source has several numbering gaps and an explicitly marked missing-text passage, retained here. This is not the modern critical edition and does not include the Harivamsha appendix.','Follow people facing choices with no painless answer. Read the Gita first, then return to its larger narrative setting.','Kisari Mohan Ganguli, 1883–1896','https://www.gutenberg.org/ebooks/15474','Full source edition','book.closed',allchapters,['krishna','arjuna','draupadi','yudhishthira','bhima','karna','vyasa','bhishma','duryodhana'])
    return gita,maha

def yoga():
    s=text_source('yoga-2526.txt')
    starts=list(re.finditer(r'(?m)^BOOK ([IVX]+)[ \t]*$',s))
    assert len(starts)==4
    titles=['Samadhi · concentration','Sadhana · practice','Vibhuti · capacities','Kaivalya · freedom']
    chapters=[]; counts=[]
    for i,m in enumerate(starts):
        body=s[m.end():starts[i+1].start() if i+1<len(starts) else len(s)]
        sutras=list(re.finditer(r'(?m)^(\d+)\.? ',body))
        counts.append(len(sutras))
        ps=[]
        for j,x in enumerate(sutras):
            sn=int(x[1]); segment=body[x.end():sutras[j+1].start() if j+1<len(sutras) else len(body)]
            paras=re.split(r'\n\s*\n',segment.strip(),maxsplit=1)
            # Separate translated aphorism from Johnston’s interpretive commentary.
            ps.append(dict(id=f'yoga-sutras-{i+1}-{sn:02}-sutra',reference=f'Yoga Sutras {i+1}.{sn} · translation',text=re.sub(r'\s+',' ',paras[0]).strip()))
            if len(paras)>1:
                for k,t in enumerate(chunks(paras[1]),1):
                    ps.append(dict(id=f'yoga-sutras-{i+1}-{sn:02}-comment-{k}',reference=f'Johnston’s commentary on {i+1}.{sn} · {k}',text=t))
        chapters.append(dict(id=f'yoga-sutras-{i+1}',title=f'{i+1}. {titles[i]}',summary='Translated aphorisms are labeled separately from Charles Johnston’s commentary, which reflects his Theosophical interpretation.',passages=ps))
    assert counts==[51,55,55,34], counts
    return book('yoga-sutras','Yoga Sutras','How the mind settles','Philosophy','Classical Yoga; diverse later interpretations','Patanjali’s aphorisms investigate mental activity, disciplined practice, and freedom. This edition includes all 195 aphorisms in its numbering, plus Charles Johnston’s commentary. Other editions count 196.','Understand the eight limbs of yoga and why posture is only one part of a wider discipline. Johnston’s metaphysical vocabulary is one interpretation, not a neutral glossary.','Charles Johnston, 1912','https://www.gutenberg.org/ebooks/2526','Complete translation','circle.dotted',chapters,['patanjali'])

def upanishads():
    s=text_source('upanishads-3283.txt')
    positions=[]
    for name in ['Isa','Katha','Kena']:
        matches=list(re.finditer(r'(?mi)^[ \t]*'+name+r'-Upanishad[ \t]*$',s))
        assert len(matches)==3
        positions.append(matches[1].start())
    chapters=[]
    for i,title in enumerate(['Isha Upanishad','Katha Upanishad','Kena Upanishad']):
        body=s[positions[i]:positions[i+1] if i+1<len(positions) else len(s)]
        chapters.append(chapter(f'upanishads-{i+1}',title,'Complete translated work with Paramananda’s commentary interleaved. Roman numerals in the text belong to the source edition.',body,title+' · translation and commentary'))
    return book('upanishads','Three Upanishads','Isha · Katha · Kena','Upanishads','Vedic; especially influential in Vedanta','Three complete Upanishads in Swami Paramananda’s translation, with his commentary. They explore the self, knowledge, mortality, and ultimate reality. This is a selection from the wider Upanishadic corpus, not all Upanishads.','Begin with Katha: a young seeker asks the lord of death what survives dying. Compare its questions with Isha’s wholeness and Kena’s inquiry into knowing.','Swami Paramananda, early twentieth century','https://www.gutenberg.org/ebooks/3283','Selected translation','sparkles',chapters,['nachiketa','yama','agni','indra','parvati'])

def rigveda():
    s=text_source('rigveda-griffith.txt')
    s=re.sub(r'(?m)^<\d+>\s*$','',s)
    starts=list(re.finditer(r'(?m)^\[(\d\d)-(\d\d\d)\]([^\n]*)',s))
    counts=[0]*10; chapters=[]
    for i,m in enumerate(starts):
        bn=int(m[1]); hn=int(m[2])
        if hn==0: continue
        counts[bn-1]+=1
        body=s[m.end():starts[i+1].start() if i+1<len(starts) else len(s)]
        body=body.replace('http://www.sanskritweb.net','').strip()
        deity=re.sub(r'^\s*HYMN\s+[IVXLCDM]+[.,]?\s*','',m[3]).strip().rstrip('.')
        chapters.append(chapter(f'rig-veda-{bn:02}-{hn:03}',f'{bn}.{hn} · {deity}',f'Mandala {bn}, hymn {hn}. Griffith’s 1896 translation. Source transcription omits diacritics and contains occasional scanning errors.',body,f'Rig Veda {bn}.{hn}'))
    assert counts==[191,43,62,58,87,75,104,103,114,191],counts
    assert len(chapters)==1028
    return book('rig-veda','Rig Veda','1,028 hymns to a living cosmos','Vedas','Vedic; preserved through distinct recitation lineages','All 1,028 hymn units across ten mandalas in Griffith’s historical translation. Fire, dawn, storm, speech, and cosmic order are addressed through ritual poetry. This digital witness lacks diacritics and has known transcription errors; it is not a critical Sanskrit edition.','Meet Agni, Indra, Ushas, and Varuna in early Vedic poetry. Try 1.1, 10.90, and 10.129, then compare how later traditions develop their themes.','Ralph T. H. Griffith, 1896; digital transcription by Ulrich Stiehl, 2005','https://archive.sacred-texts.com/hin/rigveda/index.htm','Complete translation','flame',chapters,['agni','indra','varuna','ushas','soma','saraswati','purusha'])

def ramayana():
    s=text_source('ramayana-24869.txt')
    start=re.search(r'(?m)^BOOK I\.\(6\)',s).start()
    s=s[start:s.index('\nAPPENDIX.',start)]
    starts=list(re.finditer(r'(?m)^BOOK ([IVX]+)\.(?:\(\d+\))?[ \t]*$',s))
    assert len(starts)==6
    titles=['Bala','Ayodhya','Aranya','Kishkindha','Sundara','Yuddha']
    chapters=[];counts=[]
    for i,m in enumerate(starts):
        body=s[m.end():starts[i+1].start() if i+1<len(starts) else len(s)]
        cantos=list(re.finditer(r'(?m)^Canto ([IVXLCDM]+)\.([^\n]*)$',body))
        counts.append(len(cantos))
        for j,c in enumerate(cantos):
            n=roman(c[1]);label=clean(c[2]).strip().rstrip('.')
            text=body[c.end():cantos[j+1].start() if j+1<len(cantos) else len(body)]
            chapters.append(chapter(f'ramayana-{i+1}-{n:03}',f'{i+1}.{n} · {label}',f'{titles[i]} Kanda. Griffith’s verse rendering contains omissions; Uttara Kanda is not included.',text,f'Ramayana, {titles[i]} Kanda, canto {n}'))
    assert len(chapters)>400,counts
    return book('ramayana','Ramayana','Exile, devotion, and the journey home','Epics','Itihasa; central to many Vaishnava and regional traditions','Griffith’s historical verse rendering of the first six books, including Rama’s exile, Sita’s captivity, Hanuman’s journey, and the war in Lanka. The translator omits passages and condenses material; Uttara Kanda is not bundled. Many regional Ramayanas tell the story differently.','Learn the narrative before exploring its difficult ethical questions and the voices of Sita, Hanuman, and other participants.','Ralph T. H. Griffith, 1870–1874; first six books, with translator omissions','https://www.gutenberg.org/ebooks/24869','Selected translation','leaf',chapters,['rama','sita','hanuman','lakshmana','ravana','valmiki','bharata','vibhishana'])

# Additional historical editions; each source is bounded before parsing so modern
# site navigation, comments, marketing, and footnotes cannot enter reading text.
from html.parser import HTMLParser
import zipfile
class PlainHTML(HTMLParser):
    def __init__(self):super().__init__();self.parts=[];self.skip=0
    def handle_starttag(self,tag,attrs):
        if tag in ('script','style','sup'):self.skip+=1
        elif tag in ('p','h1','h2','h3','h4','h5','h6'):self.parts.append('\n\n')
        elif tag=='br':self.parts.append('\n')
    def handle_endtag(self,tag):
        if tag in ('script','style','sup') and self.skip:self.skip-=1
        elif tag in ('p','h1','h2','h3','h4','h5','h6'):self.parts.append('\n\n')
    def handle_data(self,data):
        if not self.skip:self.parts.append(data)
    def get(self):return re.sub(r'\n[ \t]*\n(?:[ \t]*\n)+','\n\n',''.join(self.parts)).strip()
def html_text(s):
    p=PlainHTML();p.feed(s);return p.get()

def vishnu_purana():
    s=text_source('vishnu-66208.txt')
    s=s.split('\n[1] ')[0]
    starts=list(re.finditer(r'(?m)^PART ([IVX]+)[.:][ \t]*$',s))[-6:]
    assert len(starts)==6
    chapters=[];counts=[]
    for i,m in enumerate(starts):
        body=s[m.end():starts[i+1].start() if i+1<len(starts) else len(s)]
        sections=list(re.finditer(r'(?m)^SECTION ([IVXLC]+)\.[ \t]*$',body));counts.append(len(sections))
        for j,x in enumerate(sections):
            text=body[x.end():sections[j+1].start() if j+1<len(sections) else len(body)]
            note='Part '+str(i+1)+' of Dutt’s 1896 prose edition, based on H. H. Wilson. '
            if roman(x[1])!=j+1:note+='The source misprints this heading as '+x[1]+'; the app uses its sequential position. '
            chapters.append(chapter(f'vishnu-purana-{i+1}-{j+1:02}',f'{i+1}.{j+1} · Part {i+1}, chapter {j+1}',note,text,f'Vishnu Purana {i+1}.{j+1}'))
    assert counts==[22,16,18,24,38,8],counts
    return book('vishnu-purana','Vishnu Purana','Cosmic cycles, Vishnu, and the story of Krishna','Puranas','Vaishnava','All six parts and 126 chapters of Manmatha Nath Dutt’s 1896 prose edition, based on H. H. Wilson. Narratives explore creation, cosmic time, genealogies, religious practice, Krishna, and dissolution. This historical source has spelling and numbering irregularities.','Read Book 1 for creation and the churning of the ocean, Book 2 for sacred cosmography, and Book 5 for Krishna’s narrative. These are theological representations, not physical astronomy.','Manmatha Nath Dutt, 1896, based on H. H. Wilson','https://www.gutenberg.org/ebooks/66208','Full source edition','sparkles',chapters,['vishnu','krishna','brahma','lakshmi','shiva'])

def black_yajur():
    chapters=[];counts=[]
    with zipfile.ZipFile(ARCHIVE/'yajur-keith.zip') as z:
        for n in range(1,8):
            s=z.read(f'yv{n:02}.htm').decode('latin-1')
            s=s[s.upper().index('<H1'):s.upper().index('</BODY>')]
            heads=list(re.finditer(r'<H3[^>]*>(.*?)</H3>',s,re.I|re.S));counts.append(len(heads))
            for j,m in enumerate(heads):
                title=html_text(m[1]).strip().rstrip('.')
                body=html_text(s[m.end():heads[j+1].start() if j+1<len(heads) else len(s)])
                chapters.append(chapter(f'yajur-veda-{n}-{j+1:03}',title,'Taittiriya Samhita, Kanda '+str(n)+'. Keith’s 1914 translation; this is one Black Yajurveda recension.',body,'Taittiriya Samhita '+title))
    assert counts==[145,73,53,81,120,66,106],counts
    return book('yajur-veda','Yajur Veda · Taittiriya','The Black Yajurveda’s ritual collection','Vedas','Taittiriya recension of the Black Yajurveda','The seven kandas of the Taittiriya Samhita in A. B. Keith’s 1914 translation. Ritual formulas and prose explanations appear together. This is one major recension, not every Yajurvedic text, Brahmana, or Aranyaka.','See how speech, offering, and interpretation fit together in Vedic ritual. Compare with the White Yajurveda to understand why recension matters.','Arthur Berriedale Keith, 1914','https://original.sacred-texts.com/hin/yv/index.htm','Full source edition','flame',chapters,['agni','indra','prajapati','soma'])

def white_yajur():
    s=(ARCHIVE/'white-yajur-griffith.html').read_text()
    s=s[:s.index('</article>')]
    heads=list(re.finditer(r'<h2>Book ([IVXLC]+)</h2>',s));assert len(heads)==40
    chapters=[]
    for i,m in enumerate(heads):
        body=s[m.end():heads[i+1].start() if i+1<len(heads) else len(s)]
        body=re.sub(r'<p class="return-to-top">.*?</p>','',body,flags=re.S)
        chapters.append(chapter(f'white-yajur-veda-{i+1:02}',f'Book {i+1}','Griffith’s 1899 translation of the White Yajurveda Samhita. Historical source spelling is retained.',html_text(body),f'White Yajur Veda {i+1}'))
    return book('white-yajur-veda','White Yajur Veda','Forty books of sacrificial formulas','Vedas','Vajasaneyi Samhita; White Yajurveda','All forty books of Griffith’s 1899 translation of the White Yajurveda. The ritual formulas form a different textual arrangement from the Taittiriya Samhita. Book 40 contains the Isha Upanishad in this edition’s wording.','Compare two Yajurvedic recensions and see an Upanishadic teaching within its larger Vedic setting.','Ralph T. H. Griffith, 1899','https://www.globalgreyebooks.com/online-ebooks/ralph-t-h-griffith_texts-of-the-white-yajurveda_complete-text.html','Full source edition','sun.max',chapters,['agni','indra','prajapati'])

def atharva():
    s=text_source('atharva-griffith.txt');s=re.sub(r'(?m)^\d+[ \t]*$','',s)
    heads=list(re.finditer(r'(?m)^BOOK (\d+)[ \t]*$',s));assert len(heads)==20
    chapters=[];counts=[]
    for i,m in enumerate(heads):
        body=s[m.end():heads[i+1].start() if i+1<len(heads) else len(s)]
        hymns=list(re.finditer(r'(?m)^HYMN ([IVXLC]+)[ \t]*$',body));counts.append(len(hymns))
        for j,h in enumerate(hymns):
            text=body[h.end():hymns[j+1].start() if j+1<len(hymns) else len(body)]
            number=roman(h[1]);first=re.sub(r'\s+',' ',text.strip().split('\n')[0])[:100]
            chapters.append(chapter(f'atharva-veda-{i+1:02}-{j+1:03}',f'{i+1}.{number} · {first}','Griffith’s 1895–1896 translation. Source hymn numbering has gaps and duplicates; the app retains supplied numbering and gives each reading unit its own stable ID.',text,f'Atharva Veda {i+1}.{number}'))
    assert counts==[35,32,31,39,31,141,117,10,10,10,10,5,4,2,18,9,1,4,71,143],counts
    return book('atharva-veda','Atharva Veda','Household life, protection, and cosmic inquiry','Vedas','Atharvavedic traditions; Griffith’s historical translation','Twenty books from Griffith’s 1895–1896 translation, imported from a digital witness with 723 hymn headings. This witness has gaps and duplicated hymn labels, so it is presented as a source edition rather than a verified critical text.','Encounter everyday hopes beside reflection on Earth, the human person, and the support of existence. Healing charms are historical religious texts, not medical instructions.','Ralph T. H. Griffith, 1895–1896; digital witness 2019','https://archive.sacred-texts.com/hin/av/index.htm','Full source edition','leaf',chapters,['prithvi','agni','indra','purusha'])

def samaveda():
    s=text_source('four-vedas.txt')
    start=s.rindex('HYMNS OF THE SAMAVEDA');end=s.index('HYMNS OF THE ATHARVA',start)
    s=s[start:end]
    s=re.sub(r'(?m)^Hymns of the (?:Sama|Atharva) Veda[^\n]*\n','',s)
    s=re.sub(r'(?m)^\d+[ \t]*$','',s)
    starts=list(re.finditer(r'(?m)^BOOK ([IVX]+)[ \t]*$',s));assert len(starts)==15
    chapters=[]
    for i,m in enumerate(starts):
        part=1 if i<6 else 2;num=i+1 if i<6 else i-5
        body=s[m.end():starts[i+1].start() if i+1<len(starts) else len(s)]
        body=body.replace('PART SECOND','')
        chapters.append(chapter(f'sama-veda-{part}-{num:02}',f'Part {part} · Book {num}','Griffith’s historical translation. English text does not reproduce the melodic performance of Samavedic chanting.',body,f'Sama Veda {part}.{num}'))
    assert [roman(m[1]) for m in starts]==list(range(1,7))+list(range(1,10))
    return book('sama-veda','Sama Veda','Poetry arranged for sacred song','Vedas','Samavedic traditions','Both parts of Griffith’s historical translation: six books in the first part and nine in the second. Much of its poetry also occurs in the Rig Veda, rearranged for liturgical singing. The digital witness retains historical spellings and occasional transcription errors.','Listen for repeated invocations to Agni, Indra, and Soma while noticing how text and ritual arrangement differ from the Rig Veda. Melody itself requires a living recitation tradition.','Ralph T. H. Griffith, nineteenth century; digital witness labels 1895','https://archive.sacred-texts.com/hin/sv.htm','Full source edition','music.note',chapters,['agni','indra','soma'])

def muller_upanishads():
    s=(ARCHIVE/'upanishads-muller-1.html').read_text();s=s[:s.index('<h3>Footnotes</h3>')]
    starts=list(re.finditer(r'<h2>(.*?)</h2>',s,re.S));wanted={
        'Khandogya-Upanishad':('chandogya-upanishad','Chandogya Upanishad','Eight chapters of teachings, stories, and contemplative correspondences.'),
        'Kaushitaki-Upanishad':('kaushitaki-upanishad','Kaushitaki Upanishad','Dialogues about breath, consciousness, and the journey beyond death.'),
        'Aitareya-Aranyaka':('aitareya-upanishad','Aitareya Upanishad','The Aitareya Upanishad within the second Aranyaka: chapters four through six.')}
    results=[]
    for i,m in enumerate(starts):
        key=html_text(m[1])
        if key not in wanted:continue
        bid,title,summary=wanted[key];body=s[m.end():starts[i+1].start() if i+1<len(starts) else len(s)]
        if bid=='aitareya-upanishad':
            body=body[body.index('<h3>Second Aranyaka</h3>'):body.index('<h3>Third Ara')]
            body=html_text(body)
            body=body[body.index('Fourth Adhyaya.'):body.index('Seventh Adhyaya.')]
            sections=list(re.finditer(r'(?m)^[ \t]*(Fourth|Fifth|Sixth) Adhyaya\.[^\n]*',body))
            # Fourth Adhyaya has three khandas; keep each numbered source unit.
            assert len(sections)==5,len(sections)
            boundary=body.index('Adoration to the Highest Self. Hari, Om!')
            introduction=chapter(bid+'-editor-introduction','Müller’s editorial introduction','Historical editorial interpretation, not scripture.',body[:boundary],'Müller’s editorial introduction to Aitareya')
            translated=chapter(bid+'-translation','Aitareya Upanishad · translation','Translated scripture begins with the invocation.',body[boundary:],'Aitareya Upanishad · translation')
            chapters=[dict(id=bid+'-text',title='Aitareya Upanishad · the second Aranyaka, chapters 4–6',summary='Müller’s historical editorial introduction is labeled separately from his translation. Surrounding ritual Aranyaka material is excluded.',passages=introduction['passages']+translated['passages'])]
            summary+=' Müller’s opening editorial interpretation is retained and labeled separately from scripture.'
        else:
            sections=list(re.finditer(r'<h3>(.*?)</h3>',body,re.S));expected=8 if bid=='chandogya-upanishad' else 4;assert len(sections)==expected
            chapters=[chapter(f'{bid}-{j+1:02}',html_text(x[1]),'Müller’s 1879 translation; source internal section and verse numbers are retained.',html_text(body[x.end():sections[j+1].start() if j+1<len(sections) else len(body)]),title+' '+str(j+1)) for j,x in enumerate(sections)]
        results.append(book(bid,title,summary,'Upanishads','Vedic; interpreted by multiple Vedanta schools',summary+' The full translated work is bundled in F. Max Müller’s 1879 historical edition, without the volume’s scholarly endnotes.','Read the dialogues slowly and compare how different Vedanta traditions interpret their language of self and ultimate reality.','F. Max Müller, 1879','https://www.globalgreyebooks.com/online-ebooks/friedrich-max-muller_upanishads-part-1_complete-text.html','Complete translation','sparkles',chapters,['atman','brahman']))
    assert len(results)==3
    return results

# Original short catalog annotations. Empty chapters explicitly mean guide-only.
def catalog():
    rows=[]
    def add(bid,title,subtitle,category,tradition,summary,why,url=GRETIL,entities=()):
        rows.append(book(bid,title,subtitle,category,tradition,summary,why,'Translation not bundled',url,'Catalog guide',{'Vedas':'flame','Upanishads':'sparkles','Epics':'book.closed','Puranas':'sparkle','Devotion':'heart','Philosophy':'circle.dotted','Ritual':'sun.max'}.get(category,'book'),[],list(entities)))
    add('sama-veda','Sama Veda','The Veda of melody','Vedas','Vedic','A collection of verses arranged for liturgical singing, many shared with the Rig Veda. Its musical realization belongs to living recitation traditions.','See how a hymn becomes song and how sound carries ritual meaning.',ST+'sv.htm',['agni','indra','soma'])
    add('yajur-veda','Yajur Veda','Words and actions of sacrifice','Vedas','Vedic','A family of ritual collections transmitted in White and Black Yajurvedic traditions. These include distinct Samhitas rather than one interchangeable edition.','Understand the relationship between spoken formulas, ritual action, and later philosophical inquiry.',ST+'yaj/index.htm',['agni','prajapati'])
    add('atharva-veda','Atharva Veda','Life, healing, and cosmic reflection','Vedas','Vedic','Hymns and formulas concerning household life, protection, healing, kingship, and speculative questions. Historical healing verses are religious literature, not clinical advice.','Encounter the range of human concerns preserved alongside Vedic cosmology.',ST+'av/index.htm',['prithvi','agni'])
    add('shatapatha-brahmana','Shatapatha Brahmana','Ritual explained through narrative','Vedas','White Yajurveda','An extensive Brahmana interpreting ritual procedures through stories, correspondences, and reflection. It includes an early telling of Manu’s flood.','Explore the link between Vedic ritual, cosmology, and the stories developed in later texts.',ST+'sbr/index.htm',['manu','prajapati','agni'])
    add('aitareya-brahmana','Aitareya Brahmana','Rigvedic ritual interpretation','Vedas','Rigveda','A Brahmana concerned with sacrificial ritual, priestly roles, and accompanying narratives.','Read after introductory Vedic material to understand its ritual setting.')
    principal=[('isha','Isha','Wholeness and action'),('kena','Kena','What powers knowing?'),('katha','Katha','Nachiketa questions death'),('prashna','Prashna','Six inquiries into life'),('mundaka','Mundaka','Higher and lower knowledge'),('mandukya','Mandukya','Om and states of consciousness'),('taittiriya','Taittiriya','Learning, self, and bliss'),('aitareya','Aitareya','Consciousness and creation'),('chandogya','Chandogya','Teaching through image and dialogue'),('brihadaranyaka','Brihadaranyaka','The self in searching dialogues'),('shvetashvatara','Shvetashvatara','Rudra, devotion, and liberation'),('kaushitaki','Kaushitaki','Breath and the path beyond death'),('maitri','Maitri','Self, mind, and contemplative practice')]
    for bid,title,sub in principal:
        bundled=bid in ['isha','kena','katha']
        add(bid+'-upanishad',title+' Upanishad',sub,'Upanishads','Vedic; interpreted by multiple Vedanta schools',f'A major Upanishadic work exploring {sub.lower()}. '+('A complete Paramananda translation is available inside the bundled Three Upanishads collection.' if bundled else 'This guide links to a source collection; a translation is not yet bundled.'),'Compare its questions with other Upanishads, allowing different philosophical schools to offer different readings.',ST+('sbe01/index.htm' if bid in ['isha','kena','aitareya','chandogya','kaushitaki'] else 'sbe15/index.htm'),['yama','nachiketa'] if bid=='katha' else [])
    puranas=[
        ('brahma','Brahma','Creation, sacred places, and devotion'),('padma','Padma','Sacred geography and religious practice'),('vishnu','Vishnu','Cosmic cycles, dynasties, and Vishnu'),('shiva','Shiva','Shiva’s manifestations and worship'),('bhagavata','Bhagavata','Krishna and the life of devotion'),('narada','Narada','Devotion, ritual, and sacred learning'),('markandeya','Markandeya','Cycles of time and the Goddess'),('agni','Agni','An encyclopedic sacred compilation'),('bhavishya','Bhavishya','Layered religious and social traditions'),('brahma-vaivarta','Brahma Vaivarta','Krishna, Radha, and divine transformation'),('linga','Linga','Shiva and the symbolism of the linga'),('varaha','Varaha','Vishnu’s boar form and sacred places'),('skanda','Skanda','Pilgrimage, sacred places, and Shaiva narratives'),('vamana','Vamana','Vishnu’s dwarf form and wider traditions'),('kurma','Kurma','Vishnu’s tortoise form and theological dialogue'),('matsya','Matsya','Flood narratives, creation, and ritual'),('garuda','Garuda','Ritual, cosmology, and the afterlife'),('brahmanda','Brahmanda','The cosmic egg and sacred narratives')]
    for bid,title,sub in puranas:
        tradition='Vaishnava, Shaiva, Shakta, and other strands vary by work and recension'
        if bid in ['vishnu','bhagavata','garuda','varaha','vamana','kurma','matsya','brahma-vaivarta']: tradition='Vaishnava; includes wider traditions'
        if bid in ['shiva','linga','skanda']: tradition='Shaiva; includes wider traditions'
        url=ST+'vp/index.htm' if bid=='vishnu' else ST+'gp/index.htm' if bid=='garuda' else GRETIL
        add(bid+'-purana',title+' Purana',sub,'Puranas',tradition,f'{sub}. One of the works named in common lists of eighteen Mahapuranas. Contents, divisions, and sectarian emphasis vary across recensions; such lists are not perfectly uniform.','Read its narrative and theological setting before treating any passage as a statement shared by every Hindu tradition.',url,['vishnu','krishna'] if bid in ['vishnu','bhagavata'] else ['shiva'] if bid in ['shiva','linga','skanda'] else [])
    add('devi-bhagavata','Devi Bhagavata Purana','The Goddess as ultimate reality','Puranas','Shakta','A major Shakta Purana portraying Devi as supreme and containing the Devi Gita. Its place in Purana classifications differs by tradition.','Balance Vishnu- and Shiva-centered narratives with a Goddess-centered theological world.',ST+'db/index.htm',['devi','durga','lakshmi','saraswati'])
    add('devi-mahatmya','Devi Mahatmya','The Goddess defeats chaos','Puranas','Shakta','A thirteen-chapter narrative within the Markandeya Purana, also known as Durga Saptashati or Chandi. It recounts the Goddess’s victories and praise.','Discover Durga, Kali, and the relation between divine power and the restoration of order.',GRETIL,['devi','durga','kali','mahishasura'])
    add('devi-gita','Devi Gita','Wisdom spoken by the Goddess','Puranas','Shakta','A philosophical and devotional dialogue embedded in the Devi Bhagavata Purana.','Explore knowledge, practice, and devotion with Devi as teacher.',ST+'dg/index.htm',['devi'])
    add('harivamsha','Harivamsha','The lineage of Hari','Epics','Vaishnava','A supplement associated with the Mahabharata, expanding genealogies and narratives of Krishna. It is distinct from the eighteen parvas bundled here.','Continue from the Mahabharata into Krishna’s broader narrative world.',GRETIL,['krishna','vishnu','balarama'])
    add('ramcharitmanas','Ramcharitmanas','Rama’s story in Awadhi','Devotion','Rama bhakti','Tulsidas’s devotional retelling of the Rama story in Awadhi, influential in North Indian worship and performance. It is a distinct work, not simply a translation of Valmiki.','Compare how language, devotion, and the storyteller’s purpose reshape a familiar narrative.',GRETIL,['rama','sita','hanuman','tulsidas'])
    add('kamba-ramayanam','Kamba Ramayanam','The Rama story in Tamil','Epics','Tamil literary and Vaishnava traditions','Kamban’s Tamil Iramavataram develops the Rama story with its own poetic and theological imagination.','Meet a major regional Ramayana on its own literary terms.',TAMIL,['rama','sita','hanuman'])
    philosophy=[
        ('brahma-sutras','Brahma Sutras','Concise arguments of Vedanta','Vedanta','Aphorisms attributed to Badarayana that organize inquiry into Brahman. Shankara, Ramanuja, Madhva, and others interpret them in significantly different ways.',ST+'sbe34/index.htm'),
        ('samkhya-karika','Samkhya Karika','Consciousness and nature','Samkhya','Ishvarakrishna’s verses set out a system of purusha, prakriti, and the principles through which experience unfolds.',GRETIL),
        ('nyaya-sutras','Nyaya Sutras','Reasoning and valid knowledge','Nyaya','A foundational text on the means of knowledge, inference, debate, and liberation.',GRETIL),
        ('vaisheshika-sutras','Vaisheshika Sutras','Categories of reality','Vaisheshika','A philosophical investigation of substances, qualities, action, and other categories.',GRETIL),
        ('mimamsa-sutras','Mimamsa Sutras','Interpreting sacred injunctions','Purva Mimamsa','Jaimini’s aphorisms investigate Vedic interpretation, ritual action, and dharma.',GRETIL),
        ('vivekachudamani','Vivekachudamani','Discrimination and liberation','Advaita Vedanta','A teaching poem traditionally attributed to Shankara; authorship is debated. It explores discernment of the self and liberation.',ST+'cw/index.htm'),
        ('ashtavakra-gita','Ashtavakra Gita','A radical nondual dialogue','Advaita traditions','A dialogue of Ashtavakra and Janaka on freedom and the self, using a strongly nondual voice.',GRETIL),
        ('avadhuta-gita','Avadhuta Gita','The song of the free sage','Nondual and Dattatreya traditions','Verses traditionally attributed to Dattatreya emphasizing nondual awareness and freedom from identification.',GRETIL),
        ('yoga-vasishtha','Yoga Vasistha','Philosophy through nested stories','Nondual traditions','An extensive dialogue between Rama and Vasistha using stories to investigate mind, appearance, and liberation. Several versions circulate.',GRETIL),
        ('hatha-yoga-pradipika','Hatha Yoga Pradipika','Body, breath, and liberation','Hatha Yoga','A medieval synthesis of hatha practices attributed to Svatmarama. Practice traditions and modern yoga classes differ from the historical text.',ST+'hyp/index.htm'),
        ('shiva-sutras','Shiva Sutras','Recognition of consciousness','Kashmir Shaiva traditions','Aphorisms associated with Vasugupta that introduce a nondual Shaiva understanding of consciousness and liberation.',GRETIL),
        ('vijnana-bhairava','Vijnana Bhairava Tantra','Contemplative doorways','Shaiva Tantra','A dialogue of Bhairava and the Goddess presenting many contemplative approaches within its tantric setting.',GRETIL),
        ('narada-bhakti-sutras','Narada Bhakti Sutras','The character of devotion','Bhakti','Aphorisms attributed to Narada exploring loving devotion and the life it shapes.',GRETIL),
    ]
    for bid,title,sub,trad,summary,url in philosophy:
        add(bid,title,sub,'Philosophy',trad,summary,'Read with attention to its school and the questions it is trying to answer; compare rather than flatten differences.',url,['shiva'] if bid in ['shiva-sutras','vijnana-bhairava'] else [])
    for bid,title,sub,trad,summary,entities in [
        ('tirukkural','Tirukkural','Virtue, public life, and love','Tamil ethical literature','Tiruvalluvar’s 1,330 couplets on virtue, public life, and love are shared across religious communities. It should not be represented as belonging exclusively to Hinduism.',[]),
        ('tevaram','Tevaram','Songs to Shiva in sacred places','Tamil Shaiva bhakti','Hymns of Appar, Sambandar, and Sundarar forming the first seven books of the Tirumurai. Poetry, place, and temple worship are closely connected.',['shiva']),
        ('tiruvacakam','Tiruvacakam','The heart turns toward Shiva','Tamil Shaiva bhakti','Manikkavacakar’s devotional poems express longing, surrender, and transformation.',['shiva']),
        ('tirumantiram','Tirumantiram','Yoga and Shaiva wisdom','Tamil Shaiva traditions','A work attributed to Tirumular interweaving yoga, ethics, devotion, and Shaiva thought.',['shiva']),
        ('divya-prabandham','Nalayira Divya Prabandham','Four thousand Tamil hymns','Sri Vaishnava','The collected hymns of the Alvars form a central Tamil scriptural and liturgical corpus in Sri Vaishnava tradition.',['vishnu','krishna','andal']),
        ('tiruppavai','Tiruppavai','Andal’s thirty songs','Sri Vaishnava','Andal’s thirty Tamil verses, included in the Divya Prabandham, are especially recited in the month of Margazhi.',['andal','krishna']),
        ('periya-puranam','Periya Puranam','Lives of the sixty-three Nayanmars','Tamil Shaiva bhakti','Sekkizhar’s poetic accounts of Shiva’s devotees form the twelfth Tirumurai.',['shiva']),
    ]:
        add(bid,title,sub,'Devotion',trad,summary,'Read the poem alongside its language, place, music, and living community.',TAMIL,entities)
    add('gita-govinda','Gita Govinda','Krishna and Radha in lyric poetry','Devotion','Vaishnava bhakti','Jayadeva’s Sanskrit lyrical poem depicts Krishna and Radha through longing and reunion and has deep connections with music and dance.','See how devotional love speaks through poetry, performance, and emotion.',GRETIL,['krishna','radha'])
    add('hanuman-chalisa','Hanuman Chalisa','Forty verses of praise','Devotion','Rama and Hanuman bhakti','A widely recited Awadhi hymn traditionally attributed to Tulsidas, praising Hanuman’s devotion, courage, and service.','Meet devotion as a daily practice of remembrance.',GRETIL,['hanuman','rama','tulsidas'])
    add('shaiva-agamas','Shaiva Agamas','Temple, ritual, knowledge, and practice','Ritual','Shaiva traditions','A family of scriptures rather than a single book, with differing canons and recensions. These guide theology, temple worship, initiation, and practice.','Understand how temple religion draws upon texts beyond the Vedas and epics.',GRETIL,['shiva'])
    add('pancharatra-agamas','Pancharatra Samhitas','Vaishnava temple traditions','Ritual','Pancharatra Vaishnava','A large family of texts concerning Vishnu’s manifestations, theology, ritual, and temple worship.','Discover the textual foundations of living Vaishnava ritual.',GRETIL,['vishnu','lakshmi'])
    add('shakta-tantras','Shakta Tantras','The Goddess and sacred power','Ritual','Shakta traditions','Diverse textual traditions centered on the Goddess, mantra, ritual, and liberation. They do not form a single uniform canon.','Approach individual works in the context of their lineages and modes of interpretation.',GRETIL,['devi','kali','durga'])
    add('manusmriti','Manusmriti','A historical text of dharma','Ritual','Dharmashastra','A Brahmanical normative text addressing social order, duties, law, and ritual. Its prescriptions are historically situated, often contested, and are not a universal description of Hindu life or present law.','Study it critically alongside other dharma texts, lived practices, and critiques of caste and gender hierarchy.',ST+'manu.htm',[])
    return rows

def download():
    ARCHIVE.mkdir(parents=True,exist_ok=True)
    for name,url in SOURCES.items():
        p=ARCHIVE/name
        if not p.exists():
            print('Downloading',name)
            request=urllib.request.Request(url,headers={'User-Agent':'AnantaCorpus/1.0 (public-domain educational corpus)'})
            with urllib.request.urlopen(request,timeout=90) as response:p.write_bytes(response.read())
    for stem,expected_pages in [('rigveda-griffith',506),('atharva-griffith',591),('four-vedas',1446)]:
        if not (ARCHIVE/(stem+'.txt')).exists():
            from pypdf import PdfReader
            pdf=PdfReader(ARCHIVE/(stem+'.pdf'))
            assert len(pdf.pages)==expected_pages
            (ARCHIVE/(stem+'.txt')).write_text('\n'.join(p.extract_text() for p in pdf.pages),encoding='utf-8')

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--download',action='store_true');args=parser.parse_args()
    if args.download: download()
    manifest=ROOT/'Scripts'/'corpus_sha256.json'
    if not manifest.exists():
        manifest=ARCHIVE/'SHA256SUMS.json'
    if manifest.exists():
        for name,digest in json.loads(manifest.read_text()).items():
            assert hashlib.sha256((ARCHIVE/name).read_bytes()).hexdigest()==digest, f'Source snapshot changed: {name}'
    gita,maha=mahabharata()
    bundled=[gita,upanishads(),yoga(),ramayana(),maha,rigveda(),vishnu_purana(),black_yajur(),white_yajur(),atharva(),samaveda()]+muller_upanishads()
    replaced={b['id'] for b in bundled}
    result=bundled+[b for b in catalog() if b['id'] not in replaced]
    ids=set(); cids=set();pids=set();words=0;passage_count=0
    for b in result:
        assert b['id'] not in ids;ids.add(b['id'])
        assert bool(b['chapters']) == (b['coverage']!='Catalog guide')
        for c in b['chapters']:
            assert c['id'] not in cids;cids.add(c['id'])
            for p in c['passages']:
                assert p['id'] not in pids;pids.add(p['id'])
                assert p['text'].strip();passage_count+=1;words+=len(p['text'].split())
                assert 'PROJECT GUTENBERG' not in p['text'].upper()
    OUT.parent.mkdir(parents=True,exist_ok=True)
    OUT.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(dict(titles=len(result),bundled=sum(bool(b['chapters']) for b in result),chapters=len(cids),passages=passage_count,words=words,bytes=OUT.stat().st_size),indent=2))
    for b in result:
        if not b['chapters']: continue
        print(b['id'],len(b['chapters']),sum(len(c['passages']) for c in b['chapters']),b['coverage'])
    hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(ARCHIVE.glob('*')) if p.is_file() and p.suffix in ['.txt','.pdf','.html','.zip']}
    (ARCHIVE/'SHA256SUMS.json').write_text(json.dumps(hashes,indent=2)+'\n')

if __name__=='__main__':main()
