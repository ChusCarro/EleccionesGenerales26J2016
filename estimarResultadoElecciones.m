function [perc,error,dates]=estimarResultadoElecciones(fechaElecciones,...
    encuestas,encuestadores,M,partidos)

dates=[sort([encuestas.fecha]) fechaElecciones];
dateDiff=-[encuestas.fecha]'*ones(1,length(dates))+ones(length(encuestas),1)*dates;

muestra = [encuestas.muestra]';

[~,indPeor]=max(M(1:end-2));
for i=1:length(encuestas)
    encuestador=strcmp(encuestadores,encuestas(i).encuestador)==1;
    if(sum(encuestador)<1)
        encuestador(indPeor)=1;
    end
    
    X = [ones(length(dateDiff(i,:)),1)*encuestador ...
        dateDiff(i,:)'...
        ones(length(dateDiff(i,:)),1)*log(muestra(i))];
    errorEncuesta(i,:)=X*M;
end

errorEncuesta(dateDiff<0)=Inf;
pesos=exp(-errorEncuesta.^2);
%pesos=exp(-dateDiff/10).*(errorEncuesta).^-1;
%pesos=(errorEncuesta).^-2;
%pesos=1./(1-exp(-errorEncuesta));
errorEncuesta(dateDiff<0)=0;

perc=-ones(length(partidos),length(dates));
error=-ones(length(partidos),length(dates));
pesosPartido=zeros(length(partidos),length(dates));

for i=1:length(encuestas)
    for j=1:length(partidos)
        if(~isnan(encuestas(i).resultados(j)))
            validezEncuesta=dates>=encuestas(i).fecha;
            nuevoPeso=pesosPartido(j,validezEncuesta)+pesos(i,validezEncuesta);
            perc(j,validezEncuesta)=(perc(j,validezEncuesta).*pesosPartido(j,validezEncuesta)+...
                encuestas(i).resultados(j).*pesos(i,validezEncuesta))./nuevoPeso;
            error(j,validezEncuesta)=sqrt(pesosPartido(j,validezEncuesta).*error(j,validezEncuesta).^2./nuevoPeso+...
                pesos(i,validezEncuesta).*errorEncuesta(i,validezEncuesta).^2./nuevoPeso+...
                pesosPartido(j,validezEncuesta).*pesos(i,validezEncuesta).*(...
                perc(j,validezEncuesta)-encuestas(i).resultados(j)).^2./nuevoPeso.^2);
            pesosPartido(j,validezEncuesta)=nuevoPeso;
        end
    end
end
perc(perc<0)=NaN;
error(error<0)=NaN;
