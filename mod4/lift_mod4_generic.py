#!/usr/bin/env python3
"""Exact first-order Z/4Z lifting test for a rank-r F2 matmul scheme.

Input JSON format: {"U": [[...]], "V": [[...]], "W": [[...]]}.
Outputs a machine-checkable contradiction certificate when inconsistent.
"""
from __future__ import annotations
import argparse, hashlib, json
from pathlib import Path
from typing import Dict, List, Tuple

D=16

def target_entry(a,b,c):
    i,j=divmod(a,4); j2,k=divmod(b,4)
    return int(j==j2 and c==k*4+i)

def decode(e):
    a,rem=divmod(e,D*D); b,c=divmod(rem,D); return [a,b,c]

def build(U,V,W):
    R=len(U); rows=[]; rhs=[]; residuals=[]
    for a in range(D):
      for b in range(D):
       for c in range(D):
        row=0; s=0
        for r in range(R):
          u,v,w=U[r][a],V[r][b],W[r][c]
          s += u*v*w
          if v&w: row ^= 1 << (r*D+a)
          if u&w: row ^= 1 << (R*D+r*D+b)
          if u&v: row ^= 1 << (2*R*D+r*D+c)
        res=s-target_entry(a,b,c)
        if res&1: raise ValueError(f'not an F2 scheme at {(a,b,c)}: residual {res}')
        rows.append(row); rhs.append((res//2)&1); residuals.append(res)
    return rows,rhs,residuals

def eliminate(rows,rhs):
    basis: Dict[int,Tuple[int,int,int]]={}; cert=None
    for e,(row,bit) in enumerate(zip(rows,rhs)):
      combo=1<<e
      while row:
        p=(row&-row).bit_length()-1
        if p not in basis:
          basis[p]=(row,bit,combo); break
        br,bb,bc=basis[p]; row^=br; bit^=bb; combo^=bc
      if row==0 and bit==1 and cert is None: cert=combo
    return basis,cert

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('input')
    ap.add_argument('-o','--output',required=True)
    args=ap.parse_args()
    data=json.loads(Path(args.input).read_text())
    U=data.get('U',data.get('u')); V=data.get('V',data.get('v')); W=data.get('W',data.get('w'))
    R=len(U); assert len(V)==len(W)==R and all(len(x)==D for M in (U,V,W) for x in M)
    rows,rhs,res=build(U,V,W); basis,cert=eliminate(rows,rhs)
    result={
      'input':args.input,'rank_terms':R,'variables':3*R*D,'equations':D**3,
      'jacobian_rank_over_F2':len(basis),'jacobian_nullity':3*R*D-len(basis),
      'nonzero_integer_residual_equations':sum(x!=0 for x in res),
      'integer_residual_min':min(res),'integer_residual_max':max(res),
      'lift_exists_mod4':cert is None,
      'variable_encoding':{'X[r,a]':'r*16+a','Y[r,b]':f'{R}*16+r*16+b','Z[r,c]':f'2*{R}*16+r*16+c'},
      'equation_encoding':'e=(a*16+b)*16+c; target output position c=k*4+i',
      'input_factor_sha256':hashlib.sha256(json.dumps({'U':U,'V':V,'W':W},separators=(',',':')).encode()).hexdigest(),
    }
    if cert is not None:
      idx=[i for i in range(D**3) if (cert>>i)&1]
      acc=0; bit=0
      for i in idx: acc^=rows[i]; bit^=rhs[i]
      result['contradiction_certificate']={
        'weight':len(idx),'equation_indices':idx,'decoded_equations':[decode(i) for i in idx],
        'coefficient_xor_is_zero':acc==0,'rhs_xor':bit,
      }
    Path(args.output).write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({k:v for k,v in result.items() if k!='contradiction_certificate'},indent=2))
    if cert is not None:
      c=result['contradiction_certificate']; print('certificate',c['weight'],c['coefficient_xor_is_zero'],c['rhs_xor'])

if __name__=='__main__': main()
