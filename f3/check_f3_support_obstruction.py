#!/usr/bin/env python3
import argparse,hashlib,itertools,json
from pathlib import Path

def target(a,b,c):
 i,j=divmod(a,4);j2,k=divmod(b,4);return int(j==j2 and c==4*k+i)
def mapping(M):
 out={};n=0
 for q in range(3):
  for r in range(len(M[0])):
   for i,x in enumerate(M[q][r]):
    if x:out[(q,r,i)]=n;n+=1
 return out
def equation(M,xyz,bit):
 a,b,c=xyz;mons=[]
 for r in range(len(M[0])):
  if M[0][r][a] and M[1][r][b] and M[2][r][c]:
   mons.append([bit[(0,r,a)],bit[(1,r,b)],bit[(2,r,c)]])
 k=len(mons)
 if k==0:
  if target(a,b,c):return set(),1,k,None
  raise ValueError('coordinate gives no necessary contradiction equation')
 n=(target(a,b,c)-k)%3
 if not (k<=4 and n<=k and n+3>k):raise ValueError(('not unique negative count',xyz,k,n))
 for signs in itertools.product((0,1),repeat=k):
  val=sum(1 if s==0 else -1 for s in signs)%3
  if val==target(a,b,c):assert sum(signs)==n and (sum(signs)&1)==(n&1)
 mask=set()
 for mon in mons:
  for v in mon:
   if v in mask:mask.remove(v)
   else:mask.add(v)
 return mask,n&1,k,n
def check_coord_certificate(M,coords):
 bit=mapping(M);mask=set();rhs=0
 for xyz in coords:
  m,y,_,_=equation(M,tuple(xyz),bit)
  mask.symmetric_difference_update(m);rhs^=y
 if mask or rhs!=1:raise AssertionError((len(mask),rhs))
 return len(bit),len(coords)
def affects(M,edit,coords):
 q,r,i=edit
 for xyz in coords:
  if xyz[q]!=i:continue
  o=[0,1,2];o.remove(q)
  if M[o[0]][r][xyz[o[0]]] and M[o[1]][r][xyz[o[1]]]:return True
 return False
def main():
 ap=argparse.ArgumentParser();ap.add_argument('source');ap.add_argument('base');ap.add_argument('distance1');a=ap.parse_args()
 raw=Path(a.source).read_bytes();d=json.loads(raw);M=[d['U'],d['V'],d['W']]
 B=json.load(open(a.base));D=json.load(open(a.distance1))
 assert hashlib.sha256(raw).hexdigest()==B['source_sha256']==D['source_sha256']
 basecoords=[e['coordinate'] for e in B['equations']]
 bit=mapping(M)
 for e in B['equations']:
  m,y,k,n=equation(M,tuple(e['coordinate']),bit)
  assert sorted(m)==e['variable_ids'];assert y==e['rhs_parity'];assert k==e['support_count'];assert n==e['required_negative_count']
 check_coord_certificate(M,basecoords)
 certs={tuple(x['edit'][:3]):x for x in D['edit_certificates']}
 affected=0;total=0
 for q in range(3):
  for r in range(len(M[0])):
   for i in range(16):
    total+=1;old=M[q][r][i]
    if not affects(M,(q,r,i),basecoords):continue
    affected+=1;entry=certs[(q,r,i)];assert entry['edit']==[q,r,i,old,1-old]
    M[q][r][i]=1-old
    check_coord_certificate(M,entry['equations'])
    M[q][r][i]=old
 assert total==D['total_possible_single_edits'];assert affected==D['affected_single_edits']==len(certs)
 print(f'VALID: base support and all {total} single-entry support edits are obstructed over F3; {affected} edits required dedicated certificates, the others preserve the base contradiction.')
if __name__=='__main__':main()
