#!/usr/local/lib/miniconda3/envs/psidev/bin/python
from psiturk.models import Participant
import pandas as pd

def main():
    workers = list(set(p.workerid for p in Participant.query.all()))
    pd.Series(workers, name='workerid').to_csv('participants.csv', header=True, index=False)

if __name__ == '__main__':
    main()

