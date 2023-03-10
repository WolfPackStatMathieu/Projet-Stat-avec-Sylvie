library(dfcrm)
help(dfcrm)
source("MainFunctions_Andrillon_JBS_2020.R")
source("fonctions.R")

#######Modele de survie.######
###################################
####################

#####I) Simulation des données et import des donnees simulees.######
#####On utilise le code fourni pour générer les données. 
N=18 #Nombre de patients simulés
p<-0.33 # Valeur limite de toxicité
#Simulation des données par la fonction titesim
res <- titesim(PI=c(0.05, 0.1, 0.15, 0.33, 0.50), 
               prior=getprior(0.05, 0.25, 2, 5), 
               0.25, N, 1,
               obswin=6,restrict=1,
               rate=3,
               accrual = "poisson", seed=1234)

#Création d'un dataframe avec ces valeurs
base_tox <- data.frame(id=1:N, dose=res$level, time_arrival=res$arrival, toxicity.study.time=res$toxicity.study.time, toxicity.time=res$toxicity.time)
head(base_tox)
#Transformation des valeurs de la variable toxicity.study.time en NA si Inf
base_tox$toxicity.study.time[base_tox$toxicity.study.time==Inf] <- NA
#idem pour toxicity.time
base_tox$toxicity.time[base_tox$toxicity.time==Inf] <- NA
#On arrondit les valeurs à 2 chiffres après la virgule
base_tox$toxicity.study.time <- round(base_tox$toxicity.study.time, 2)
base_tox$toxicity.time <- round(base_tox$toxicity.time, 2)
base_tox$time_arrival <- round(base_tox$time_arrival, 2)


essai_n18 <- base_tox
essai_n18
plot(essai_n18)
#####On écrit une base de données. 
write.table(essai_n18, file="essai_n18.txt", sep="\t", row.names=F)
donnees<-read.table("essai_n18.txt",header=TRUE)

#######II) Creation des arguments. ######

#Vecteur reponse avec reponse=1 si le temps d'apparition de la toxicité est connu. 
#Le vecteur reponse vaut 0 sinon. 
#Dans notre cas, on donne 0 si le temps d'apparition  de la toxicité est NA.
vecteur_reponse<-ifelse(is.na(donnees$toxicity.time)==FALSE,1,0)
# le t star
t<-6
#Les doses administrées à chaque patient sont données par la colonne dose. 
level_dose<-donnees$dose

#la date de sortie est donnee par la colonne toxicity.study.time. 
observations_time<-ifelse(!is.na(donnees$toxicity.time),donnees$toxicity.time,t)

#Rappel: 
#Nous sommes dans le cadre où la fonction de survie 
#suit une loi exponentielle de paramètre exp(-xi*exp(beta)). Notons epsi cette valeur. 
# donc la fonction de densité est :
#epsi*exp(-epsi*t) [fonction densité d'une loi exponentielle.]



#2) calcul de la vraisemblance:
valeur_dose<-c(0.5,1,3,5,6)
id_dose<-donnees$dose
vecteur_reponse<-ifelse(is.na(donnees$toxicity.time)==FALSE,1,0)


tstar<-6
############## Si on utilise l'inference bayesienne de l'article. ######
skeleton <- getprior_exp(halfwidth=0.05, target=p, nu=4, nlevel=5, tstar=6) 
xref <-  log(-log(1-skeleton)/6)              #Set of numerical labels for the doses investigated in the trial
test_bayes<-modele_survie_bayes(p,tstar,observations_time,id_dose,valeur_dose =xref,vecteur_reponse = vecteur_reponse )
windows<-runif(10,-0.1,0)
beta_init<-(-3)

######On remarque que la valeur de beta selon l'algorithme de Newton peut beaucoup varier. Par ailleurs, la log -vraisemblance a ete choisie 
##### car la vraisemblance ne permettait pas d'avoir des iterations. En effet, la valeur du gradient Ã¯Â¿Â½tait trop faible
#### au point initial. 
fenetre<-runif(10,-20,-1)
##### Autre methode, utiliser plusieurs points initiaux. . ####
#test_beta_newton_multiple<-modele_survie_Newton_multiple(observations_time = observations_time,id_dose=id_dose,
 #                                                        valeur_dose = xref,
  #                                                       vecteur_reponse = vecteur_reponse,
   #                                                      fenetre)
### Si on utilise cette methode, on obtient des resultats tres differents du modele puissance. 
### Ces methodes ne sont donc pas convenables. 
afficher_resultat(beta=test_bayes,x_ref=x_ref,probabilites_priori = skeleton)
test_newton<-modele_survie_Newton(observations_time = observations_time,id_dose,valeur_dose = xref,vecteur_reponse = vecteur_reponse,1)