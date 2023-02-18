
source("surv.R")
source("bernoulli.R")
fonction_generation_taille_mean<-function(vector_size,model,liste_parameter,K){
  ### renvoie la g�n�ration avec des tailles diff�rentes du mod�le model (string) ayant comme param�tre la liste_parameter, 
  ### liste de param�tres avec le mod�les. 1 seul comme bernoulli et 2 pour exp() (lambda et t_star).
  vector_size<-vector_size[order(vector_size)]
  if (model=="bernoulli"){
    vecteur_realisation<-sapply(vector_size,Simuler_Nfois_n_echantillons_bern,N=K,liste_parameter[["p"]])
    return(colMeans(vecteur_realisation))
  }
  else{if(model=="surv"){
    vecteur_realisation<-sapply(vector_size,Simuler_Nfois_n_echantillons,N=K,lambda=liste_parameter[["lambda"]],t_star=liste_parameter[["t_star"]])
    return(colMeans(vecteur_realisation))
  }}
}

#################" TEST exp de la m�thode.#####
N<-100
vecteur_size<-sample(c(1:1000),N)
lamdba_test<-0.33
t_star<-6
liste_parameter<-list(lambda_test,t_star)
names(liste_parameter)<-c("lambda","t_star")
modele<-"surv"
k<-20
test_generation_taillemoy<-fonction_generation_taille_mean(vector_size=vecteur_size,model=modele,K=k,liste_parameter = liste_parameter)


#################### Plot des r�sultats en fonction de la taille.########
donnees_taille_biaismoyen<-cbind.data.frame(vecteur_size[order(vecteur_size)],test_generation_taillemoy)
colnames(donnees_taille_biaismoyen)<-c("Size","Mean_Bias")
h_DPImean<-KernSmooth::dpill(x=donnees_taille_biaismoyen$Size,y=donnees_taille_biaismoyen$Mean_Bias)
estimation_ymoy<-KernSmooth::locpoly(x=donnees_taille_biaismoyen$Size,y=donnees_taille_biaismoyen$Mean_Bias,bandwidth=h_DPImean,degree=3,gridsize = N)$y
plot(donnees_taille_biaismoyen)
lines(x=donnees_taille_biaismoyen$Size,y=estimation_ymoy,col="red")