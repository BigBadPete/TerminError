# TerminError : Gérer les erreurs dans des programmes IBM  i

Une manière très simple de gérer les erreurs dans les programmes. Même moi, je comprends, c'est dire ! 

Pour tracer les abominations qui surviennent de-ci de-là, il y a la table ERR_JRN. J'ai manqué d'imagination, j'avoue... J'avais envie de l'appeler "TERMINERROR", mais franchement ce n'est pas sérieux !

On va y inscrire : 
- le code d'erreur CPF ou SQL, et pourquoi pas applicatif, à vous de voir. 
- le type d'erreur : 'CPF', 'SQL', ou ce que vous voulez 'FDM' pour "Fin du Monde" 
- une description d'erreur sur 100 caractères. N'hésitez pas à augmenter si vous avez envie de concurrencer Marcel Proust 
- le nom du programme à l'origine de l'erreur. Pratique pour aller débeuguer le fautif, n'est-ce pas ? 
- le nom du profil utilisateur. Ben, oui, il faut bien un coupable à flageller en Place de Grève... On a perdu le goût de ces grandes manifestations populaires, quel dommage, c'était convivial, on venait avec son petit bâton, son petit caillou et on passait un bon moment en famille et entre amis (Léodagan et Alexandre Astier TM) 
- l'horodatage de l'évènement. Information essentielle pour les traitements de nuit, et même les autres. 

Et qui c'est-y qui écrit dedans ? 

Un seul programme : WRTERRJRN ! Comme c'est du Free Form, il y a son prototype à inclure dans chaque RPG Free Form l'utilisant, et c'est errlog_h.rpgle. J'aurais pu lui donner un nom proche de WRTERRJRN, mais c'est pour voir si les cancres du fond de la classe suivent bien !  

Pour s'amuser avec il y a 2 programmes CL : 
- EXMONMSG1 : Il va intercepter une erreur bien précise. Là, on fait dans le détail. 
- EXMONMSG2 : Ici, c'est pour ceux qui ne font pas dans la dentelle de Bruges et usent et abusent du MONMSG CPF0000... Hé, oui, tout le monde sait que c'est mal, mais que le premier qui ne l'a jamais fait jette le 1er clavier 102 touches à la tête du pêcheur désigné à l'opprobre du brave peuple qui affute ses tomates bien mûre... 

Donc, oui, même dans ce cas, on peut arriver à donner de la visibilité là où auparavant les chaînes de nuit se plantaient sournoisement ! 

Enfin, il y a un programme RPG Free Form avec du SQL EXRPGLE qui sert lui aussi de test mais je l'espère d'exemple pour inclure les bonnes pratiques de gestion de messages SQL. Je n'ai pas la prétention d'avoir mis tous les cas, il en manque peut-être, mais c'est déjà un bon début, n'est-ce pas ? D'autant plus que j'ai rarement vu de la gestion de codes retour d'accès à la BdD, alors, hein, bon... 
