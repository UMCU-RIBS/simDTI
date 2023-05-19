function read_nii,filename,ftf=ftf,ns=ns,reorient=reorient
syntx=n_params()
if syntx lt 1 then begin
print,'Returns the contents of a niftii file.'
print,'Syntax not right; parms are :'
print,'1: full filename of the to be (single) loaded nifti-file'
print,'Keword FTF forces to put the data in floating point matrix'
print,'Keyword ns ignores scaling factor'
print,'Keyword reorient transposes the image to be in scanner orientation'
return,0
ENDIF
if strpos(filename,'.gz') eq -1 then begin
niihdrtool,filename,hdrdat=hdrdat
scalefactor=hdrdat(26)
dim=hdrdat(3:hdrdat(2)+2)
if hdrdat(14) eq 2 then tempdata=reform(bytarr(dim))
if hdrdat(14) eq 4 then tempdata=reform(intarr(dim))
if hdrdat(14) eq 8 or hdrdat(14) eq 768 then tempdata=reform(lonarr(dim))
if hdrdat(14) eq 16 then tempdata=reform(fltarr(dim))
if hdrdat(14) eq 32 then tempdata=reform(dcomplexarr(dim))
if hdrdat(14) eq 64 then tempdata=reform(dblarr(dim))
if hdrdat(14) eq 512 then tempdata=reform(intarr(dim))
data=tempdata
if keyword_set(ftf) then data=float(data)
get_lun,unit
openr,unit,filename
offset=bytarr(hdrdat(25))
readu,unit,offset,tempdata
close,unit
free_lun,unit
end else begin
file_gunzip,filename,buffer=alldat,nbytes=10000000000
hdrsize=float(alldat,108,1)
hdrdat=fix(alldat,0,hdrsize/2)
scalefactor=float(hdrdat,112,1)
alldat=alldat(hdrsize:*)
dim=hdrdat(21:21+hdrdat(20)-1)
nrvox=product(dim(where(dim ne 0)),/integer)
if hdrdat(35) eq 2 then tempdata=reform(alldat,dim)
if hdrdat(35) eq 4 then tempdata=reform(fix(alldat,0,nrvox),dim)
if hdrdat(35) eq 8 or hdrdat(14) eq 768 then tempdata=reform(long(alldat,0,nrvox),dim)
if hdrdat(35) eq 16 then tempdata=reform(float(alldat,0,nrvox),dim)
if hdrdat(35) eq 32 then tempdata=reform(dcomplex(alldat,0,nrvox),dim) 
if hdrdat(35) eq 64 then tempdata=reform(double(alldat,0,nrvox),dim)
if hdrdat(35) eq 512 then tempdata=reform(fix(alldat,0,nrvox),dim)
data=tempdata
if keyword_set(ftf) then data=float(data)
end
data(where(finite(tempdata) eq 1))=tempdata(where(finite(tempdata) eq 1))
if keyword_set(ns) then scalefactor=1
if not keyword_set(ftf) then data=tempdata*scalefactor(0)
if keyword_set(ftf) then data=float(tempdata)*scalefactor(0)
if keyword_set(reorient) then begin
trmatrix=float(reform(hdrdat(45:56),4,3))
trmatrix=trmatrix(0:2,*)
for i=0,2 do trmatrix(*,i)=trmatrix(*,i)/float(hdrdat(18+i))
tmp=max(abs(trmatrix),ind,dimension=1)
rcheck=round(trmatrix(ind))
tmp=array_indices(trmatrix,ind)
data=transpose(data,reform(tmp(0,*)))
for i=0,2 do if rcheck(i) eq -1 then data=reverse(data,i+1)
end
return,data
end

