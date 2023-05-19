pro inc_tracks,incvol,trackfile,opfile
syntx=n_params()
if syntx lt 1 then begin $
print,'Usage:'
print,'1: The inclusion volume'
print,'2: The input track file'
print,'3: The output track file'
end
vol=read_nii(incvol)
trackdat=read_track(trackfile)
niihdrtool,incvol,hdrdat=hdrdat
trmatrix=[[float(reform(hdrdat(45:56),4,3))],[[0,0,0,1]]]
itrmatrix=invert(trmatrix)
nrcoor=size(trackdat,/dimensions)
nrcoor=nrcoor(1)
tmptrackdat=[trackdat,transpose(intarr(nrcoor)+1)]
tmptrackdat=floor(transpose(tmptrackdat)#itrmatrix)
prestest=vol(tmptrackdat(*,0),tmptrackdat(*,1),tmptrackdat(*,2))
tracktest=lonarr(nrcoor)
seps=[0,where(finite(trackdat(0,*)) eq 0)]
for i=0L,n_elements(seps)-3 do if max(prestest(seps(i)+1:seps(i+1)-1)) ne 0 then tracktest(seps(i)+1:seps(i+1))=1
if total(tracktest) ne 0 then begin
optrackdat=trackdat(*,where(tracktest eq 1))
if finite(optrackdat(0,0) eq 0) then optrackdat=optrackdat(*,1:*)
optrackdat=[[optrackdat],[!VALUES.F_INFINITY,!VALUES.F_INFINITY,!VALUES.F_INFINITY]]
write_track,optrackdat,opfile,trackfile
end else print,'No tracks passing inclusion area.'
end
