#!/usr/bin/env python3
import argparse,json,time,multiprocessing as mp,hashlib
from pathlib import Path

def target(a,b,c):
 i,j=divmod(a,4);j2,k=divmod(b,4);return int(j==j2 and c==4*k+i)
def contradiction(M):
 bit={};n=0
 for q in range(3):
  for r,row in enumerate(M[q]):
   for i,x in enumerate(row):
    if x:bit[q,r,i]=n;n+=1
 piv={}
 for a in range(16):
  for b in range(16):
   for c in range(16):
    terms=[]
    for r in range(len(M[0])):
     if M[0][r][a] and M[1][r][b] and M[2][r][c]:terms.append(r)
    k=len(terms)
    if k==0:
     if target(a,b,c):return True
     continue
    if k>4:continue
    neg=(target(a,b,c)-k)%3
    if neg>k or neg+3<=k:continue
    m=0
    for r in terms:m^=1<<bit[0,r,a];m^=1<<bit[1,r,b];m^=1<<bit[2,r,c]
    y=neg&1
    while m:
     j=m.bit_length()-1
     if j not in piv:piv[j]=(m,y);break
     m^=piv[j][0];y^=piv[j][1]
    if not m and y:return True
 return False
def affects(M,e,coords):
 q,r,i=e
 for x in coords:
  if x[q]==i and all(M[o][r][x[o]] for o in range(3) if o!=q):return True
 return False
_G=None
def init_worker(src,dist):
 global _G
 d=json.load(open(src));D=json.load(open(dist));_G=([d['U'],d['V'],d['W']],D)
def work(fi):
 base,D=_G;M=[[row[:] for row in Q] for Q in base];bc=D['base_certificate_equations']
 firsts=[(q,r,i) for q in range(3) for r in range(len(M[0])) for i in range(16) if affects(M,(q,r,i),bc)]
 e1=firsts[fi];dc={tuple(x['edit'][:3]):x['equations'] for x in D['edit_certificates']};q,r,i=e1;M[q][r][i]^=1;coords=dc[e1];count=0;bad=[]
 for q2 in range(3):
  for r2 in range(len(M[0])):
   for i2 in range(16):
    e2=(q2,r2,i2)
    if e2==e1 or not affects(M,e2,coords):continue
    count+=1;M[q2][r2][i2]^=1
    if not contradiction(M):bad.append(e2)
    M[q2][r2][i2]^=1
 return fi,e1,count,bad
def main():
 ap=argparse.ArgumentParser();ap.add_argument('source');ap.add_argument('distance1');ap.add_argument('output');ap.add_argument('--workers',type=int,default=5);a=ap.parse_args()
 d=json.load(open(a.source));M=[d['U'],d['V'],d['W']];D=json.load(open(a.distance1));bc=D['base_certificate_equations'];firsts=[(q,r,i) for q in range(3) for r in range(len(M[0])) for i in range(16) if affects(M,(q,r,i),bc)]
 t=time.time()
 with mp.Pool(a.workers,initializer=init_worker,initargs=(a.source,a.distance1)) as pool:res=list(pool.imap_unordered(work,range(len(firsts))))
 res.sort();bad=[{'first':list(e1),'second':list(e2)} for _,e1,_,bs in res for e2 in bs]
 obj={'source':a.source,'source_sha256':hashlib.sha256(Path(a.source).read_bytes()).hexdigest(),'distance1':a.distance1,'first_edits':len(firsts),'ordered_second_edits_requiring_fresh_check':sum(x[2] for x in res),'linearly_consistent_pairs':bad,'elapsed_seconds':time.time()-t,'claim':'all support patterns at factor-entry Hamming distance at most 2 have a necessary F3 parity contradiction'}
 Path(a.output).write_text(json.dumps(obj,indent=2));print(json.dumps({k:v for k,v in obj.items() if k!='linearly_consistent_pairs'},indent=2));print('consistent_pair_count',len(bad))
 if bad:raise SystemExit(1)
if __name__=='__main__':main()
