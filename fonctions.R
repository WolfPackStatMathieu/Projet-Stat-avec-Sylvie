#Rappel: 
#Nous sommes dans le cadre où la fonction de survie 
#suit une loi exponentielle de paramètre exp(-xi*exp(beta)). Notons epsi cette valeur. 
# donc la fonction de densité est :
#epsi*exp(-epsi*t) [fonction densité d'une loi exponentielle.]

fonction_proba<-function(beta,temps,dose){
  epsilon<-exp(dose*exp(beta))
  return(epsilon*exp((-1)*(epsilon)*temps))
}

fonction_survie<-function(beta,temps,dose){
  epsilon<-exp(dose*exp(beta))
  return(exp(-epsilon*temps))
}
#2) calcul de la vraisemblance:
fonction_vraisemblance<-function(beta,observations_time,id_dose,valeur_dose,vecteur_reponse){
  res<-1
  for (i in (1:length(observations_time))){
    #on selectionne la valeur de la dose. On a seulement l'identifiant de la dose
    #dans la base de données.
    dose<-valeur_dose[id_dose[i]]
    non_censure<-vecteur_reponse[i]
    temps<-observations_time[i]
    nouvel_element<-fonction_proba(beta,temps=temps,dose)^(I(non_censure==1)*1)*fonction_survie(beta,temps=temps,dose)^(I(non_censure==0)*1)
    res<-res*nouvel_element
  }
  return(res)
}
modele_survie_bayes<-function(target,tstar,observations_time,id_dose,valeur_dose,vecteur_reponse){
  #1) calcul de la vraisemblance.
  #On genere (beta) fois une loi normale. 
  #2) calcul de l'estimateur. Methode de l'article : 
  #On a des variables déterministes que sont X et Y. Le beta dépend de ces variables. 
  #La loi de beta sera donc donnée en sachant x et Y.
  #Pour avoir une approximation de cette loi, on utilise la vraisemblance (sachant Beta) * la loi de beta. [On suppose que beta suit une loi normale.]
  #Ce calcul renvoie aux equations 7 et 8. 
  #On calcule l'espérance de la loi de beta sachant X et Y. On doit cependant bien diviser par la constante pour 
  #avoir la loi de beta sachant x et Y. Cette constante renvoie dans notre cas à f(X,Y).
  constante<-integrate(denom_tox_bayes,-Inf,Inf,observations_time=observations_time,id_dose=id_dose,vecteur_reponse=vecteur_reponse,valeur_dose=valeur_dose)$value
  beta_hat<-integrate(num_tox_bayes,-Inf,Inf,observations_time=observations_time,id_dose=id_dose,vecteur_reponse=vecteur_reponse,valeur_dose=valeur_dose)$value/constante
  return(beta_hat)
  #3) calcul du nouveau lambda. 
  #lambda<-exp(exp(beta_hat)*valeur_dose)
  #Proba_inf_t<-1-exp(-lambda*tstar)
  #4) choix de la dose. 
  #distance_cible<-abs(Proba_inf_t,target)
  #Doses_min<-valeur_dose[which(distance_cible==min(distance_cible))]
  #Soit il n'y a qu'une seule dose disponible soit on en prend une au hasard. 
  #dose_choisi<-ifelse(length(Doses_min)==1,Doses_min,sample(Doses_min,1))
  #return(beta_hat,dose_choisi)
}
denom_tox_bayes<-function(beta,observations_time,id_dose,valeur_dose,vecteur_reponse){
  result1<-fonction_vraisemblance(beta,observations_time,id_dose,valeur_dose,vecteur_reponse)*dnorm(beta,mean=0,sd=1.34)
  return(result1)
}
num_tox_bayes<-function(beta,observations_time,id_dose,valeur_dose,vecteur_reponse){denom_tox_bayes(beta,observations_time,id_dose,valeur_dose,vecteur_reponse)*beta}


############# Modele de survie sans l'inférence bayésienne. #######
######### Trouver la valeur minimale au sein d'une fenÃªtre. #######

modele_survie_sans_hypotheses<-function(observations_time,id_dose,valeur_dose,vecteur_reponse,windows){
  vecteur_valeur_likelihood<-list()
  length(vecteur_valeur_likelihood)<-length(windows)
  vecteur_valeur_likelihood<-log(sapply(windows,fonction_vraisemblance,observations_time=observations_time,id_dose=id_dose,valeur_dose=valeur_dose,vecteur_reponse=vecteur_reponse))
  indice<-which(vecteur_valeur_likelihood==max(vecteur_valeur_likelihood))
  maximum<-windows[indice]
  if (length(maximum)>1){return(maximum[1])}
  return(maximum)
}
fonction_inverse_log<-function(beta,observations_time,id_dose,valeur_dose,vecteur_reponse){
  return((-1)*log(fonction_vraisemblance(beta,observations_time,id_dose,valeur_dose,vecteur_reponse)))
}
modele_survie_Newton<-function(observations_time,id_dose,valeur_dose,vecteur_reponse,beta_init){
  return(nlm(fonction_inverse_log,p=beta_init,observations_time=observations_time,id_dose=id_dose,valeur_dose=valeur_dose,vecteur_reponse=vecteur_reponse,hessian=FALSE))
}

modele_survie_Newton_multiple<-function(observations_time,id_dose,valeur_dose,vecteur_reponse,windows){
  matrice<-cbind.data.frame(sapply(windows,modele_survie_Newton,observations_time=observations_time,
                                   id_dose=id_dose,valeur_dose=valeur_dose,vecteur_reponse=vecteur_reponse))
  return(matrice)
}
lambda<-function(beta,x){
  return(exp(exp(beta)*x))
}
afficher_resultat<-function(beta,x_ref,probabilites_priori){
  vecteur_indice<-1:length(xref)
  y_proba<-1-exp(-lambda(beta=test_bayes,x=xref[vecteur_indice])*tstar)
  plot(x=vecteur_indice,y=probabilites_priori,main="Comparaison entre priori et post",xlab="Indice de la dose",ylab="Probabilites de LDT")
  lines(y_proba,col="blue")
}

fonction_logit<-function(beta0=0,beta1,x){
  (1+exp(beta1*x+beta0))
  return(exp(beta1*x+beta0)/(1+exp(beta1*x+beta0)))
}