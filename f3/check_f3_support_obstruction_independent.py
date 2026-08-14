#!/usr/bin/env python3
# Independent bit-packed replay of the coordinate-only certificates.
import json,sys
from pathlib import Path

def tgt(a,b,c):
 i,j=divmod(a,4);q,k=divmod(b,4);return int(j==q and c==4*k+i)
def cert(M,coords):
 ids={};z=0
 for q in range(3):
  for r,row in enumerate(M[q]):
   for i,x in enumerate(row):
    if x:ids[q,r,i]=z;z+=1
 acc=0;rhs=0
 for a,b,c in map(tuple,coords):
  terms=[]
  for r in range(len(M[0])):
   if M[0][r][a]*M[1][r][b]*M[2][r][c]:terms.append(r)
  k=len(terms)
  if k==0:
   assert tgt(a,b,c)==1;rhs^=1;continue
  n=(tgt(a,b,c)-k)%3
  assert 0<=n<=k<=4 and n+3>k
  rhs^=n&1
  for r in terms:
   acc^=1<<ids[0,r,a];acc^=1<<ids[1,r,b];acc^=1<<ids[2,r,c]
 assert acc==0 and rhs==1
for src,base,dist in [sys.argv[1:4]]:
 d=json.load(open(src));M=[d['U'],d['V'],d['W']];B=json.load(open(base));D=json.load(open(dist));bc=[e['coordinate'] for e in B['equations']];cert(M,bc);emap={tuple(x['edit'][:3]):x for x in D['edit_certificates']}
 for q in range(3):
  for r in range(len(M[0])):
   for i in range(16):
    hit=any(x[q]==i and all(M[o][r][x[o]] for o in range(3) if o!=q) for x in bc)
    if hit:
     old=M[q][r][i];M[q][r][i]^=1;cert(M,emap[q,r,i]['equations']);M[q][r][i]=old
 print('VALID independent replay',Path(src).name)
