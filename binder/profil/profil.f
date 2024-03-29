C*$Id$
C*-----------------------------------------------------------------------------------------------------------------------*/
C*                                                                           						*/
C* PROJET:    KALIDEOS	                                                     						*/
C*                                                                           						*/
C* NOM DU MODULE    :  ProfilADAM.f                                    							*/
C*                                                                           						*/
C* DATE DE CREATION :  27/10/2000                                           						*/
C* AUTEUR :            B.LAFRANCE ()                                         						*/
C*                                                                          						*/
C* ROLE:   Adapte le profil atmospherique du modele US62                                                		*/
C*       pour une pression de surface, une quantite de vapeur d'eau                                                 	*/
C*       et une quantite d'ozone differentes.                                                  				*/
C*       Procede par ponderation du profil par le rapport des nouvelles                                                	*/
C*       valeurs sur les valeurs standards.                                                				*/
C*															*/
C*									     						*/
C* HISTORIQUE                                                                						*/
C*                                                                           						*/
C* VERSION : 1.0 : 		 					     						*/
C*       Creation du fichier                                                 						*/
C* FIN-HISTORIQUE                                                            						*/
C*----------------------------------------------------------------------------------------------------------------------*/

      Program profilADAM

      integer i
      real z6(34),p6(34),t6(34),wh6(34),wo6(34)
      real z(34),p(34),t(34),wh(34),wo(34)
      
      real Ps,uw,uo3
      real uwus,uo3us
      
      character*20 IA1,IA2,IA3
      
c
c     model: us standard 62 mc clatchey
c
      data(z6(i),i=1, 34)/
     1    0.,    1.,    2.,    3.,    4.,    5.,    6.,    7.,    8.,
     2    9.,   10.,   11.,   12.,   13.,   14.,   15.,   16.,   17.,
     3   18.,   19.,   20.,   21.,   22.,   23.,   24.,   25.,   30.,
     4   35.,   40.,   45.,   50.,   70.,  100.,99999./
      data (p6(i),i=1,34) /
     a1.013e+03,8.986e+02,7.950e+02,7.012e+02,6.166e+02,5.405e+02,
     a4.722e+02,4.111e+02,3.565e+02,3.080e+02,2.650e+02,2.270e+02,
     a1.940e+02,1.658e+02,1.417e+02,1.211e+02,1.035e+02,8.850e+01,
     a7.565e+01,6.467e+01,5.529e+01,4.729e+01,4.047e+01,3.467e+01,
     a2.972e+01,2.549e+01,1.197e+01,5.746e+00,2.871e+00,1.491e+00,
     a7.978e-01,5.520e-02,3.008e-04,0.000e+00/
      data (t6(i),i=1,34) /
     a2.881e+02,2.816e+02,2.751e+02,2.687e+02,2.622e+02,2.557e+02,
     a2.492e+02,2.427e+02,2.362e+02,2.297e+02,2.232e+02,2.168e+02,
     a2.166e+02,2.166e+02,2.166e+02,2.166e+02,2.166e+02,2.166e+02,
     a2.166e+02,2.166e+02,2.166e+02,2.176e+02,2.186e+02,2.196e+02,
     a2.206e+02,2.216e+02,2.265e+02,2.365e+02,2.534e+02,2.642e+02,
     a2.706e+02,2.197e+02,2.100e+02,2.100e+02/
      data (wh6(i),i=1,34) /
     a5.900e+00,4.200e+00,2.900e+00,1.800e+00,1.100e+00,6.400e-01,
     a3.800e-01,2.100e-01,1.200e-01,4.600e-02,1.800e-02,8.200e-03,
     a3.700e-03,1.800e-03,8.400e-04,7.200e-04,6.100e-04,5.200e-04,
     a4.400e-04,4.400e-04,4.400e-04,4.800e-04,5.200e-04,5.700e-04,
     a6.100e-04,6.600e-04,3.800e-04,1.600e-04,6.700e-05,3.200e-05,
     a1.200e-05,1.500e-07,1.000e-09,0.000e+00/
      data (wo6(i),i=1,34) /
     a5.400e-05,5.400e-05,5.400e-05,5.000e-05,4.600e-05,4.600e-05,
     a4.500e-05,4.900e-05,5.200e-05,7.100e-05,9.000e-05,1.300e-04,
     a1.600e-04,1.700e-04,1.900e-04,2.100e-04,2.400e-04,2.800e-04,
     a3.200e-04,3.500e-04,3.800e-04,3.800e-04,3.900e-04,3.800e-04,
     a3.600e-04,3.400e-04,2.000e-04,1.100e-04,4.900e-05,1.700e-05,
     a4.000e-06,8.600e-08,4.300e-11,0.000e+00/


C* Quantite de vapeur d'eau et d'ozone integree sur la colonne 
C* atmospherique pour le profil standard US62.      
      uwus  = 1.424
      uo3us = 0.344
      
      
           
C* Lecture de la pression atmospherique au sol : Ps en mb.
      call getarg(1,IA1) 
      read(IA1,'(f8.3)') Ps
      
C* Lecture de la quantite de vapeur d'eau integree sur la colonne
C* atmospherique : uw en g/cm2.
      call getarg(2,IA2) 
      read(IA2,'(f6.3)') uw
          
C* Lecture de la quantite d'ozone integree sur la colonne
C* atmospherique : uo3 en cm x atm.
      call getarg(3,IA3) 
      read(IA3,'(f6.3)') uo3
      
                  

C* Recallage de la pression atmospherique, du profil de vapeur d'eau
C* et du profil d'ozone en fonction de Ps, uw et uo3.
      
      do 1 i=1,34
         z(i)=z6(i)
         p(i)=p6(i)*Ps/p6(1)
         t(i)=t6(i)
         wh(i)=wh6(i)*uw/uwus
         wo(i)=wo6(i)*uo3/uo3us
    1 continue
    

C* Sortie des resultats
      do 2 i=1,34
         write(6,100) z(i),p(i),t(i),wh(i),wo(i)
    2 continue
         
      return
      
100   format(5(E10.4,2X))      
      end
