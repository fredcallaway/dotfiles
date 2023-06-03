https://api.semanticscholar.org/graph/v1/paper/cb13b1b6a37e4080d8c13c5f33694b5aae90abcf/references?fields=title,authors

from semanticscholar import SemanticScholar
sch = SemanticScholar()

%time paper = sch.get_paper('10.1146/annurev.soc.23.1.263', fields=['references'])

len(paper.references)

paper.references

paper.references
https://api.semanticscholar.org/graph/v1/paper/10.1146/annurev.soc.23.1.263

# %% --------

import requests

requests.
https://api.semanticscholar.org/graph/v1/paper/10.1146/annurev.soc.23.1.263/references?limit=1000

# %% --------
%%time 
r = requests.get(
    'https://api.semanticscholar.org/graph/v1/paper/10.1146/annurev.soc.23.1.263/references',
    params={
        'limit': '500',
        'fields': 'authors,year,title,externalIds'
    },
)

# %% --------

papers = [x['citedPaper'] for x in r.json()['data']]

P = str(papers)

