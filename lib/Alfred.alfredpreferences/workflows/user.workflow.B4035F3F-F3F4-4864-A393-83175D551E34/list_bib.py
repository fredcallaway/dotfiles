import json

with open('/users/fred/lib/zotero.json') as f:
    bib = json.load(f)['items']

TYPE2ICON = {
    'journalArticle': 'article',
    'conferencePaper': 'conference',
    'preprint': 'written',
    'report': 'written',
    'thesis': 'written',
    'bookSection': 'chapter'
}

def get_icon(typ):
    name = TYPE2ICON.get(typ, typ)
    return f'icons/{name}.png'


def format_authors(item, short=False):
    try:
        if short:
            names = [a.get('lastName', '') for a in item['creators']]
        else:
            names = [a.get('firstName', '') + ' ' + a.get('lastName', '') for a in item['creators']]

        names = [n for n in names if n.strip()]
        if len(names) == 1:
            return names[0]
        if len(names) == 2:
            return ' & '.join(names)
        else:
            if len(names) > 3 and short:
                one, two = names[:2]
                last = names[-1]
                return f'{one}, {two}...{last}'
            else:
                return ', '.join(names[:-1] ) + ' & ' + names[-1]
    except:
        return 'no authors'

def format_date(item):
    try:
        if len(item['date']) == 4:
            return item['date']
        else:
            dt = item['date'].split('-', 1)[0]
            if len(dt) == 4:
                return dt
        return re.search(r'(\d{4})', item['date']).group(1)
    except:
        return 'n.d.'

def format_pub(item):
    if item['itemType'] == 'preprint':
        return 'preprint'
    for k in ['publicationTitle', 'bookTitle', 'conferenceName']:
        if k in item:
            return item[k]
    return 'unknown'

TAG_MAP = {
    '👉': 'important',
    '🤖': 'ai'
}
def format_tag(tag):
    tag = TAG_MAP.get(tag, tag).replace(' ', '-')
    return '#' + tag

def metadata(item):
    return {
        "citekey": item['citationKey'],
        "title": item['title'],
        "authors": format_authors(item),
        "short_authors": format_authors(item, short = True),
        "year": format_date(item),
        "publication":  format_pub(item) ,
        "added": item['dateAdded'],
        "modified": item['dateModified'],
        "tags": ' '.join(format_tag(x['tag']) for x in item['tags']),
        "link": item['select'],
        "type": item['itemType']
    }

def format_output(md):
    return {
        "title": md['title'],
        "match": '{citekey} @{citekey} {title} {authors} {year} {publication} {tags}'.format_map(md),
        "subtitle": '{short_authors} ({year}) {publication}'.format_map(md),
        "arg": md['citekey'],
        "icon": {"path": get_icon(md['type'])},
        # "autocomplete": "Desktop",
    }

meta = [metadata(item) for item in bib if 'citationKey' in item]
meta.sort(key=lambda x: x['added'], reverse=True)
output = {"items": [format_output(md) for md in meta]}
print(json.dumps(output))

# with open('input.json', 'w') as f:
#     json.dump(converted, f)

