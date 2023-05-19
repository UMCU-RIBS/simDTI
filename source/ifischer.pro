function ifischer,zcors
syntx=n_params()
if syntx ne 1 then begin
print,'Syntax not right; parms are :'
print,'1:Correlations to be fischer transformed'
goto, EINDE
end
cors=(exp(2*zcors)-1)/(exp(2*zcors)+1)
return,cors

EINDE:
end
