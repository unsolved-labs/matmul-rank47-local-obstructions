#!/usr/bin/env python3
import argparse,json
from pathlib import Path
D=16

def target(a,b,c):
    i,j=divmod(a,4); j2,k=divmod(b,4); return int(j==j2 and c==k*4+i)

def eq(U,V,W,e):
    R=len(U); a,rem=divmod(e,D*D); b,c=divmod(rem,D); row=0;s=0
    for r in range(R):
        u,v,w=U[r][a],V[r][b],W[r][c];s+=u*v*w
        if v&w: row^=1<<(r*D+a)
        if u&w: row^=1<<(R*D+r*D+b)
        if u&v: row^=1<<(2*R*D+r*D+c)
    res=s-target(a,b,c); assert res%2==0
    return row,(res//2)&1

def main():
    ap=argparse.ArgumentParser();ap.add_argument('factors');ap.add_argument('result');a=ap.parse_args()
    d=json.loads(Path(a.factors).read_text()); U=d.get('U',d.get('u'));V=d.get('V',d.get('v'));W=d.get('W',d.get('w'))
    r=json.loads(Path(a.result).read_text()); ids=r['contradiction_certificate']['equation_indices']
    acc=bit=0
    for e in ids:
        row,b=eq(U,V,W,e);acc^=row;bit^=b
    assert acc==0 and bit==1
    print(f"VALID {Path(a.result).name}: XOR of {len(ids)} equations gives 0 = 1")
if __name__=='__main__':main()
