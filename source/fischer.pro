function fischer,cors
syntx=n_params()
if syntx ne 1 then begin
print,'Syntax not right; parms are :'
print,'1:Correlations to be fischer transformed'
goto, EINDE
end
tcors=0.5*alog((1.+cors)/(1.-cors))
return,tcors

EINDE:
end
