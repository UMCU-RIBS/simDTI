pro sim_dti_lesion_widget
spawn,'echo $HOME',homedir
homedir=homedir+'/'
lesionfiles=''
databasefile=''
labelfile=''
peakfile=''
sr=2.
filekeep=0
tckkeep=0
dists=0
endpoints=0
crossval=1
curdir=homedir
while min(strpos(lesionfiles,'.nii')) eq -1 or min(file_test(lesionfiles)) eq 0 do begin
lesionfiles=dialog_pickfile(/read,filter='*.nii',/multiple_files,title='Select nii volumes with lesions in MNI space',path=curdir)
tmpdir=file_dirname(lesionfiles(0))
if lesionfiles(0) eq '' then return
if min(strpos(lesionfiles,'.nii')) eq -1 then print,'Not all selected files are nifti files. Only select a file with a .nii extension.'
if min(file_test(lesionfiles)) eq 0 then print,'Not all selected files exist.'
curdir=file_dirname(lesionfiles(0))
end
print,'Selected lesionfiles:'
print,transpose(lesionfiles)
while strpos(databasefile,'.txt') eq -1 or file_test(databasefile) eq 0 do begin
databasefile=dialog_pickfile(/read,filter='*.txt',title='Select ascii file containing the database files',path=curdir)
tmpdir=file_dirname(databasefile)
if databasefile eq '' then return
if strpos(databasefile,'.txt') eq -1 then print,'The selected file is not an ascii file. Select a file with a .txt extension.'
if file_test(databasefile) eq 0 then print,'The selected file does not exist.'
curdir=file_dirname(databasefile)
end
print,'Selected databasefile:'
print,databasefile
base=widget_base(/row,title='Additional Settings')
proceed=widget_button(base,value='Proceed')
srs=cw_field(base,title='Search range',/all_events,/float,value=sr)
sbase=widget_base(base,/column)
filekeeps=cw_bgroup(sbase,'Keep individual simulations',/nonexclusive,set_value=filekeep)
tckkeeps=cw_bgroup(sbase,'Store simulated streamlines',/nonexclusive,set_value=filekeep)
distss=cw_bgroup(sbase,'Calculate distance to lesion',/nonexclusive,set_value=dists)
endpointss=cw_bgroup(sbase,'Store endpoints in a volume',/nonexclusive,set_value=endpoints)
crossvals=cw_bgroup(sbase,'Perform cross-validation',/nonexclusive,set_value=crossval)
sbase2=widget_base(base,/column)
labelfiles=widget_button(sbase2,value='Select a label file')
peakfiles=widget_button(sbase2,value='Select a peak file')
maskfiles=widget_button(sbase2,value='Select a mask file')
quit=widget_button(base,value='Quit')
resp=widget_event(base,/nowait)
widget_control,base,/realize
while resp.id ne proceed or sr lt 0 do begin
resp=widget_event(base)
if resp.id eq proceed then if sr lt 0 then print,'The search range should be equal to or bigger than 0'
if resp.id eq quit then begin
widget_control,base,/destroy
return
end
if resp.id eq srs then sr=resp.value
if resp.id eq filekeeps then filekeep=resp.select
if resp.id eq tckkeeps then tckkeep=resp.select
if resp.id eq distss then dists=resp.select
if resp.id eq crossvals then crossval=resp.select
if resp.id eq endpointss then endpoints=resp.select
if resp.id eq labelfiles then begin
labelfile=''
while strpos(labelfile,'.txt') eq -1 or file_test(labelfile) eq 0 do begin
labelfile=dialog_pickfile(/read,filter='*.txt',title='Select file with the text labels for ROIs',path=curdir)
tmpdir=file_dirname(labelfile)
if strpos(labelfile,'.txt') eq -1 then print,'The selected file is not an ascii file. Select a file with a .txt extension.'
if file_test(labelfile) eq 0 then print,'The selected file does not exist.'
curdir=file_dirname(labelfile)
end
print,'Selected labelfile:'
print,labelfile
end
if resp.id eq peakfiles then begin
peakfile=''
while strpos(peakfile,'.mif') eq -1 or file_test(peakfile) eq 0 do begin
peakfile=dialog_pickfile(/read,filter='*.mif',title='Select file with the peak FODs',path=curdir)
tmpdir=file_dirname(peakfile)
if strpos(peakfile,'.mif') eq -1 then print,'The selected file is not a mif-file. Select a file with a .mif extension.'
if file_test(peakfile) eq 0 then print,'The selected file does not exist.'
curdir=file_dirname(peakfile)
end
print,'Selected peakfile:'
print,peakfile
end
if resp.id eq maskfiles then begin
maskfile=''
while strpos(maskfile,'.nii') eq -1 or file_test(maskfile) eq 0 do begin
maskfile=dialog_pickfile(/read,filter='*.nii',title='Select file with containing the mask',path=curdir)
tmpdir=file_dirname(maskfile)
if strpos(maskfile,'.nii') eq -1 then print,'The selected file is not a nifti-file. Select a file with a .nii extension.'
if file_test(maskfile) eq 0 then print,'The selected file does not exist.'
curdir=file_dirname(maskfile)
end
print,'Selected mask-file:'
print,maskfile
end
end
widget_control,base,/destroy
if labelfile eq '' then labelfile=0
if peakfile eq '' then peakfile=0
for i=0,n_elements(lesionfiles)-1 do sim_dti_lesion,lesionfiles(i),databasefile,sr=sr,labelfile=labelfile,filekeep=filekeep,maskfile=maskfile,peakfile=peakfile,dists=dists,endpoints=endpoints,crossval=crossval,tckkeep=tckkeep
end
