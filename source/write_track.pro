pro write_track,trackdat,trackfile,example
syntx=n_params()
if syntx lt 1 then begin $
& print,'Script for writing mrtrix trackfiles:' $
& print,'The track data' $
& print,'The name of the outputfile' $
& print,'The name of the trackfile to use as template.'
& end

filesize=file_info(example)
filesize=filesize.size
dat=bytarr(filesize)
rdbblk,example,dat
lim=n_elements(dat)-1
if lim gt 10000 then lim=10000
startline=strpos(string(dat(0:lim)),'file: .')
endline=min(where(dat(startline:lim) eq 10))+startline-1
datastart=long(replace(string(dat(startline:endline)),'file: . ',''))
hdr=dat(0:datastart-1)
tmphdr=string(hdr)
start=strpos(tmphdr,'count:')+6
ende=min(where(hdr(start:*) eq 10))+start
nrtracks=n_elements(where(finite(trackdat(0,*)) eq 0))-1
hdradd=byte(trim(nrtracks))
byteslost=(ende-start-1)-n_elements(hdradd)
if byteslost ne 0 then hdradd=[bytarr(byteslost)+byte(32),hdradd]
hdrdat=[hdr(0:start),hdradd,hdr(ende:*)]
get_lun,unit
openw,unit,trackfile
writeu,unit,hdrdat,trackdat
close,unit
free_lun,unit
end
