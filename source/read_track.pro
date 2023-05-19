function read_track,trackfile
syntx=n_params()
if syntx lt 1 then begin $
& print,'Usage:' $
& print,'Read track (tck) files from MRTrix' $
& print,'Output shows coordinates (x,y,z) of the tracks separated by NANs' $
& end
filesize=file_info(trackfile)
filesize=filesize.size
dat=bytarr(filesize)
rdbblk,trackfile,dat
lim=n_elements(dat)-1
if lim gt 10000 then lim=10000
startline=strpos(string(dat(0:lim)),'file: .')
endline=min(where(dat(startline:lim) eq 10))+startline-1
datastart=long(replace(string(dat(startline:endline)),'file: . ',''))
dat=float(dat,datastart,(filesize-datastart)/4)
dat=reform(dat,3,n_elements(dat)/3)
trinfo=[0,where(finite(dat(0,*)) eq 0)]
trinfo=trinfo(0:n_elements(trinfo)-2)
return,dat
end
