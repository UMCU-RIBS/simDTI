pro dist_to_lesion,incvol,trackfile,distfile
syntx=n_params()
if syntx lt 1 then begin $
print,'Usage:'
print,'1: The inclusion volume'
print,'2: The input track file'
print,'3: The distance to lesion volume'
end
vol=read_nii(incvol)
distvol=dblarr(size(vol,/dimensions))
cvol=lonarr(size(vol,/dimensions))
trackdat=read_track(trackfile)
niihdrtool,incvol,hdrdat=hdrdat
trmatrix=[[float(reform(hdrdat(45:56),4,3))],[[0,0,0,1]]]
itrmatrix=invert(trmatrix)
nrcoor=size(trackdat,/dimensions)
nrcoor=nrcoor(1)
tmptrackdat=[trackdat,transpose(intarr(nrcoor)+1)]
tmptrackdat=fix(floor(transpose(tmptrackdat)#itrmatrix))
prestest=vol(tmptrackdat(*,0),tmptrackdat(*,1),tmptrackdat(*,2))
seps=[0,where(finite(trackdat(0,*)) eq 0)]
cps=seps(1:n_elements(seps)-2)-seps(0:n_elements(seps)-3)-1
for i=0L,n_elements(cps)-1 do begin $
& lstream=where(prestest(seps(i)+1:seps(i+1)-1) eq 1,/NULL) $
& if lstream ne !NULL then begin $
& stream=trackdat(*,seps(i)+1:seps(i+1)-1) $
& tmpstream=tmptrackdat(seps(i)+1:seps(i+1)-1,0:2) $
& nrlv=n_elements(lstream) $
& strdist=[0,total(reform(sqrt((stream(0,1:cps(i)-1)-stream(0,0:cps(i)-2))^2+(stream(1,1:cps(i)-1)-stream(1,0:cps(i)-2))^2+(stream(2,1:cps(i)-1)-stream(2,0:cps(i)-2))^2)),/cumulative)] $
& dmatrix=fltarr(nrlv,cps(i)) $
& for j=0,nrlv-1 do dmatrix(j,*)=abs(strdist-strdist(lstream(j))) $
& ldist=min(dmatrix,dimension=1) $
& cvol(tmpstream(*,0),tmpstream(*,1),tmpstream(*,2))=cvol(tmpstream(*,0),tmpstream(*,1),tmpstream(*,2))+1 $
& distvol(tmpstream(*,0),tmpstream(*,1),tmpstream(*,2))=distvol(tmpstream(*,0),tmpstream(*,1),tmpstream(*,2))+ldist $
& end $
& end
vinc=where(cvol ne 0)
distvol(vinc)=distvol(vinc)/cvol(vinc)
distvol(where(distvol eq 0))=!VALUES.F_NAN
niihdrtool,distfile,hdrfile=incvol,scl_slope=1,fdata=distvol
end
