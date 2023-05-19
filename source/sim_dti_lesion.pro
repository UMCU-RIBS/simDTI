pro sim_dti_lesion,lesionfile,databasefile,sr=sr,labelfile=labelfile,filekeep=filekeep,maskfile=maskfile,peakfile=peakfile,dists=dists,endpoints=endpoints,crossval=crossval,tckkeep=tckkeep
syntx=n_params()
if syntx lt 2 then begin
print,'Estimates lesion effects on connectome based on a specified database. The output is stored in the folder with the lesion file'
print,'Syntax not right; parms are :'
print,'1: The nifti volume with the lesion segmentation'
print,'2: The databasefile representing the database. Is a 3 column text-file (subject code, trackfile, nifti file with the ROIs)'
print,'Keyword sr sets the search range at the endpoints of traces (default is 0)'
print,'Keyword labelfile sets the name of the file containing the labels of the rois specified in the databasefile'
print,'Keyword filekeep sets storing the individual simulation data'
print,'Keyword tckkeep stores all the simulated streamlines in a single file'
print,'Keyword peakfile generates output for different fiber bundels for each voxel as defined in the peakfile'
print,'Keyword distfile generates a volume containing the mean distance towards the lesion for affected streamlines'
print,'Keyword endpoints generates a volume containing the endpoints of the affected streamlines'
return
endif
spawn,'nproc',nproc
spawn,'echo $USER',username
spawn,'mkdir /tmp/'+username
nproc=trim(ceil(float(nproc)*0.75))
print,'Estimate tractography damage for lesion '+lesionfile
if not keyword_set(sr) then sr=0
workdir=file_dirname(lesionfile)+'/'
cd,workdir
read_ascii_string,databasefile,database
nvs=database(0,*)
nrnv=n_elements(nvs)
les=read_nii(lesionfile)
dims=size(les,/dimensions)
evol=intarr(dims)
evol_amp=fltarr([dims,3])
filebase=replace(file_basename(lesionfile),'.nii','')
condir='/tmp/'+username+'/'+replace(file_basename(lesionfile),'.nii','')+'_simlesions/'
condir=condir(0)
spawn,'mkdir '+condir
opfiles=condir+replace(file_basename(lesionfile),'.nii','')+'_simlesion_connectome_'+nvs+'.txt'
vopfiles=condir+replace(file_basename(lesionfile),'.nii','')+'_simlesion_'+nvs+'.nii'
todfiles=condir+replace(file_basename(lesionfile),'.nii','')+'_simlesion_'+nvs+'_tod.mif'
peakfiles=condir+replace(file_basename(lesionfile),'.nii','')+'_simlesion_'+nvs+'_peaks.mif'
ampfiles=condir+replace(file_basename(lesionfile),'.nii','')+'_simlesion_'+nvs+'_amplitudes.nii'
distfiles=condir+replace(file_basename(lesionfile),'.nii','')+'_simlesion_'+nvs+'_distances.nii'
endpointsfiles=condir+replace(file_basename(lesionfile),'.nii','')+'_simlesion_'+nvs+'_endpoints.nii'
endpointstckfiles=condir+replace(file_basename(lesionfile),'.nii','')+'_simlesion_'+nvs+'_endpoints.tck'
mopfile=replace(lesionfile,'.nii','')+'_simlesion_connectome_mean.txt'
sdopfile=replace(lesionfile,'.nii','')+'_simlesion_connectome_sd.txt'
mopniifile=replace(lesionfile,'.nii','')+'_simlesion_mean.nii'
sdopniifile=replace(lesionfile,'.nii','')+'_simlesion_sd.nii'
moppeakfile=replace(lesionfile,'.nii','')+'_simlesion_mean_peaks.nii'
sdoppeakfile=replace(lesionfile,'.nii','')+'_simlesion_sd_peaks.nii'
distfile=replace(lesionfile,'.nii','')+'_simlesion_distance.nii'
endpointsfile=replace(lesionfile,'.nii','')+'_simlesion_endpoints.nii'
endpointstckfile=replace(lesionfile,'.nii','')+'_simlesion_endpoints.tck'
tmptrackfile=condir+replace(file_basename(lesionfile),'.nii','')+'_tmptrack.tck'
optxtfile=replace(lesionfile,'.nii','')+'_simlesion_reliability.txt'
cvpeakfile=replace(lesionfile,'.nii','')+'_cross_validation_peak.txt'
cvmeanfile=replace(lesionfile,'.nii','')+'_cross_validation_mean.txt'
cvconfile=replace(lesionfile,'.nii','')+'_cross_validation_connectome.txt'
nrrois=max(read_nii(database(2,0)))
if keyword_set(maskfile) then begin 
rmaskfile=condir+'r'+file_basename(maskfile)
spawn,'mrtransform '+maskfile+' '+rmaskfile+' -template '+lesionfile+' -interp nearest -quiet'
m=read_nii(rmaskfile)
end else m=intarr(dims)+1
m(where(les eq 1 and m eq 1))=2
if keyword_set(peakfile) then begin
rpeakfile=condir+'r'+file_basename(peakfile)
rpeakmaskfile=condir+'r'+replace(file_basename(peakfile),'.mif','')+'_mask.mif'
peakmasksfile=replace(peakfile,'.mif','_masks.nii')
rpeakmasksfile=condir+'r'+file_basename(peakmasksfile)
spawn,'mrtransform '+peakfile+' '+rpeakfile+' -template '+lesionfile+' -interp nearest -quiet'
spawn,'mrtransform '+replace(peakfile,'.mif','')+'_mask.mif '+rpeakmaskfile+' -template '+lesionfile+' -interp nearest -quiet'
spawn,'mrtransform '+peakmasksfile+' '+rpeakmasksfile+' -template '+lesionfile+' -interp nearest -quiet'
end
for i=0,nrnv-1 do begin
tmptrackfile=condir+replace(file_basename(lesionfile),'.nii','')+'_tmptrack_'+trim(i+1)+'.tck'
print,'Start simulating in '+nvs(i)
inc_tracks,lesionfile,database(1,i),tmptrackfile
if file_test(tmptrackfile) eq 1 then begin
spawn,'nice -n 19 tck2connectome -nthreads '+nproc+' '+tmptrackfile+' '+database(2,i)+' '+opfiles(i)+' -assignment_radial_search '+trim(sr)+' -symmetric -force -quiet'
spawn,'nice -n 19 tckmap -nthreads '+nproc+' '+tmptrackfile+' '+vopfiles(i)+' -template '+lesionfile+' -datatype uint16le -force -quiet'
if keyword_set(endpoints) then begin
spawn,'nice -n 19 tckmap -nthreads '+nproc+' '+tmptrackfile+' '+endpointsfiles(i)+' -template '+lesionfile+' -datatype uint16le -force -quiet -ends_only'
spawn,'nice -n 19 tckresample '+tmptrackfile+' '+endpointstckfiles(i)+' -endpoints -quiet -nthreads '+nproc
end
if keyword_set(peakfile) then begin
spawn,'nice -n 19 tckmap -nthreads '+nproc+' '+tmptrackfile+' '+todfiles(i)+' -template '+lesionfile+' -tod 8 -force -quiet'
spawn,'nice -n 19 sh2peaks -nthreads '+nproc+' -num 3 '+todfiles(i)+' '+peakfiles(i)+' -force -peaks '+rpeakfile+' -quiet -mask '+rpeakmaskfile
spawn,'nice -n 19 peaks2amp -nthreads '+nproc+' -quiet -force '+peakfiles(i)+' '+ampfiles(i)
spawn,'rm '+peakfiles(i)+' '+todfiles(i)
end
if keyword_set(dists) then dist_to_lesion,lesionfile,tmptrackfile,distfiles(i)
if not keyword_set(tckkeep) then spawn,'rm '+tmptrackfile
end else begin
nrrois=max(read_nii(database(2,i)))
write_ascii,opfiles(i),trim(intarr(nrrois,nrrois)),delim=' '
niihdrtool,vopfiles(i),fdata=evol,hdrfile=lesionfile,scl_slope=1.
niihdrtool,ampfiles(i),fdata=evol_amp,hdrfile=lesionfile,scl_slope=1.
end
print,'Finished simulating in '+nvs(i)
end
if keyword_set(tckkeep) then begin
print,'Start merging the simulated streamlines of each subject'
spawn,'tckedit '+condir+'*.tck '+replace(lesionfile,'.nii','')+'_simlesion.tck'
;spawn,'rm '+condir+'*.tck'
end
print,'Start reading simulation results'
connectomes=intarr(nrrois,nrrois,nrnv)
for i=0,nrnv-1 do connectomes(*,*,i)=(read_ascii(opfiles(i))).(0)
inc=where(m ne 0)
if keyword_set(peakfile) then begin
print,'Start processing peak-data'
peakmasks=read_nii(rpeakmasksfile)
nrvol=n_elements(peakmasks(0,0,0,*))
less=intarr([dims,nrvol])
for i=0,nrvol-1 do less(*,*,*,i)=les
peakmasks(where(less eq 1 and peakmasks eq 1))=2
inc=where(peakmasks ne 0)
exc=where(peakmasks(inc) ne 2)
nrvox=n_elements(inc)
lestrackpeaks=fltarr(nrvox,nrnv)
for i=0,nrnv-1 do begin
tmpvols=read_nii(ampfiles(i))
lestrackpeaks(*,i)=tmpvols(inc)
end
print,'Finished reading simulation results'
meanpeaks=fltarr([dims,nrvol])
meanpeaks(inc)=mean(lestrackpeaks,dimension=2)
sdpeaks=fltarr([dims,nrvol])
sdpeaks(inc)=stddev(lestrackpeaks,dimension=2)
print,'Writing '+moppeakfile
niihdrtool,moppeakfile,fdata=meanpeaks*peakmasks,hdrfile=lesionfile,scl_slope=1
print,'Writing '+sdoppeakfile
niihdrtool,sdoppeakfile,fdata=sdpeaks*peakmasks,hdrfile=lesionfile,scl_slope=1
if keyword_set(crossval) then begin
print,'Start calculating cross validation peaks'
corpeaks=fltarr(2,nrnv)
for i=0,nrnv-1 do begin
ref=mean(lestrackpeaks(*,where(indgen(nrnv) ne i)),dimension=2,/NAN)
corpeaks(0,i)=fischer(correlate(lestrackpeaks(*,i),ref))
corpeaks(1,i)=fischer(correlate(lestrackpeaks(exc,i),ref(exc)))
end
write_ascii,cvpeakfile,trim(string(ifischer(corpeaks)))
corpeak=ifischer(mean(corpeaks,dimension=2,/NAN))
print,'Finished calculating cross validation peaks'
optxtpeak=['R simulated lesion (inc) peak volumes:'+string(byte(9))+trim(corpeak(0)),'R simulated lesion (exc) peak volumes:'+string(byte(9))+trim(corpeak(1))]
end
end
inc=where(m ne 0)
exc=where(m(inc) ne 2)
nrvox=n_elements(inc)
lestracks=intarr(nrvox,nrnv)
for i=0,nrnv-1 do begin
tmpvol=read_nii(vopfiles(i))
lestracks(*,i)=tmpvol(inc)
end
if keyword_set(crossval) then begin
print,'Start calculating cross validation'
corvols=fltarr(2,nrnv)
for i=0,nrnv-1 do begin
ref=mean(lestracks(*,where(indgen(nrnv) ne i)),dimension=2,/NAN)
corvols(0,i)=fischer(correlate(lestracks(*,i),ref))
corvols(1,i)=fischer(correlate(lestracks(exc,i),ref(exc)))
end
write_ascii,cvmeanfile,trim(string(ifischer(corvols)))
corcons=fltarr(nrnv)
for i=0,nrnv-1 do corcons(i)=fischer(correlate(connectomes(*,*,i),mean(connectomes(*,*,where(indgen(nrnv) ne i)),dimension=3,/NAN)))
write_ascii,cvconfile,trim(string(ifischer(corcons)))
corvol=ifischer(mean(corvols,dimension=2,/NAN))
corcon=ifischer(mean(corcons,/NAN))
print,'Finished calculating cross validation'
optext=[['R simulated lesion(inc) track volume:'+string(byte(9))+trim(corvol(0))],['R simulated lesion(exc) track volume:'+string(byte(9))+trim(corvol(1))],['R simulated lesion connectome is:'+string(byte(9))+trim(corcon)]]
if keyword_set(peakfile) then optext=[[optext],[transpose(optxtpeak)]]
print,optext
print,'Writing '+optxtfile
write_ascii,optxtfile,optext
end
if keyword_set(dists) then begin
print,'Reading mean distance volumes'
for i=0,nrnv-1 do begin
if i eq 0 then distances=fltarr([size(read_nii(distfiles(i)),/dimensions),nrnv])
distances(*,*,*,i)=read_nii(distfiles(i))
end
mdistance=mean(distances,dimension=4,/NAN)
print,'Writing '+distfile
niihdrtool,distfile,fdata=mdistance,hdrfile=lesionfile,scl_slope=1
end
if keyword_set(endpoints) then begin
print,'Reading endpoints volumes'
for i=0,nrnv-1 do if file_test(endpointsfiles(i)) eq 1 then begin
if i eq 0 then endpoints=intarr([size(read_nii(endpointsfiles(i)),/dimensions),nrnv])
endpoints(*,*,*,i)=read_nii(endpointsfiles(i))
end
mendpoints=mean(endpoints,dimension=4,/NAN)
print,'Writing '+endpointsfile
niihdrtool,endpointsfile,fdata=mendpoints,hdrfile=lesionfile,scl_slope=1
end
meanles=fltarr(dims)
sdles=fltarr(dims)
meanles(inc)=mean(lestracks,dimension=2)
sdles(inc)=stddev(lestracks,dimension=2)
meancon=mean(connectomes,dimension=3)
sdcon=stddev(connectomes,dimension=3)
wrtemplate=strarr(nrrois+1,nrrois+1)
if keyword_set(labelfile) then begin
read_ascii_string,labelfile,labels
wrtemplate(1:nrrois,0)=labels(1,*)
wrtemplate(0,1:nrrois)=labels(1,*)
end else begin
wrtemplate(1:nrrois,0)=trim(indgen(nrrois)+1)
wrtemplate(0,1:nrrois)=trim(indgen(nrrois)+1)
end
wrmeancon=wrtemplate
wrmeancon(1:*,1:*)=trim(meancon)
wrsdcon=wrtemplate
wrsdcon(1:*,1:*)=trim(sdcon)
print,'Writing '+mopfile
write_ascii,mopfile,wrmeancon
print,'Writing '+sdopfile
write_ascii,sdopfile,wrsdcon
print,'Writing '+mopniifile
niihdrtool,mopniifile,fdata=meanles,hdrfile=lesionfile,scl_slope=1
print,'Writing '+sdopniifile
niihdrtool,sdopniifile,fdata=sdles,hdrfile=lesionfile,scl_slope=1
if not keyword_set(filekeep) then spawn,'rm -r '+condir
if keyword_set(filekeep) then spawn,'mv '+condir+' '+file_dirname(lesionfile)
end
