CREATE OR REPLACE PROCEDURE TPS.BRB_TPS0213P
 (P_JOB IN Number
 ,P_DATE_DEBUT  varchar2 
  ,P_DATE_FIN varchar2 
 ,P_TYPE_RECHERCHE varchar2  
 )
 IS


/**************************************************************************************************
Auteur   : mElasri
Date     : 29/07/2019
Fonction : LISTE FACTURE PAA
***************************************************************************************************/

                Cursor C_instance is
                                       SELECT name
                                       FROM      sys.v_$database;

                Cursor C_Param is
                                       SELECT repertoire,separateur,suffixe_dat,suffixe_log,base_script
                                       FROM      ADM_INT_PARAM;


                  CURSOR C0( C_DATE_DEBUT  varchar2 , C_DATE_FIN varchar2 ) IS
                                    select L.ID , L.AFFAIRE , A.OTP , C.CODE_CLIENT ,L.CREATED_BY ,  to_char(L.CREATION_DATE,'dd/mm/yyyy')  AS CREATION_DATE
                                    from LANCEMENT L  , CLIENT_CODE_AMO C  ,AFFAIRE A 
                                    where L.CREATION_DATE   >= to_date( C_DATE_DEBUT  ,'dd/mm/yyyy') AND  L.CREATION_DATE     <=  to_date( C_DATE_FIN , 'dd/mm/yyyy')  
                                    AND  L.ID = C.LANCEMENT AND L.AFFAIRE = A.AFFAIRE ;



                  CURSOR C1( C_DATE_DEBUT  varchar2 , C_DATE_FIN varchar2 ) IS
                                    select L.ID  ,L.AFFAIRE , A.OTP ,  P.REF_PIECE , L.CREATED_BY ,  to_char(L.CREATION_DATE,'dd/mm/yyyy')  AS CREATION_DATE
                                    from LANCEMENT L , AFFAIRE A ,CLIENT_CODE_AMO C , REF_PIECE_AMORTIE P
                                    where L.CREATION_DATE   >= to_date( C_DATE_DEBUT  ,'dd/mm/yyyy') AND  L.CREATION_DATE     <=  to_date( C_DATE_FIN , 'dd/mm/yyyy')  
                                    AND L.AFFAIRE = A.AFFAIRE AND P.LANCEMENT = L.ID ;
                                    

                  CURSOR C2( C_DATE_DEBUT  varchar2 , C_DATE_FIN varchar2 ) IS
                                    select L.ID  ,L.AFFAIRE , A.OTP ,  to_char(L.CREATION_DATE,'dd/mm/yyyy')  AS CREATION_DATE
                                    from LANCEMENT L , AFFAIRE A 
                                    where L.CREATION_DATE   >= to_date( C_DATE_DEBUT  ,'dd/mm/yyyy') AND  L.CREATION_DATE     <=  to_date( C_DATE_FIN , 'dd/mm/yyyy')  
                                    AND L.AFFAIRE = A.AFFAIRE  ;
                                    
                                                  
                WParam          C_Param%Rowtype;
                Wfile2          UTL_FILE.FILE_TYPE;
                Wfile1          UTL_FILE.FILE_TYPE;
                Winstance            Varchar2(30);
                v_nblignes_i number := 0 ;
                
                
procedure ecr(zchar varchar2) is
    Begin
        if zchar = 'CRLF' then
            BRB$FILE.ADD_DATA (Wfile1,chr(13)||chr(10),0);
            UTL_FILE.FFLUSH (Wfile1);
        else
            BRB$FILE.ADD_DATA (Wfile1,zchar,0,';');
        end if;
    End;
    
BEGIN

                 Open  C_instance;
                 Fetch C_instance into Winstance;
                 Close C_Instance;

                 Open  C_Param;
                 Fetch C_Param into WParam;
                 Close C_Param;

                 Wfile2 := BRB$FILE.Open_File(WParam.repertoire,'tps0214_'|| P_Job || '.' || WParam.suffixe_log);
                Wfile1 := BRB$FILE.Open_File(WParam.repertoire,'tps0214_' || P_Job || '.' || WParam.suffixe_dat);

                 BRB$FILE.ADD_LINE(Wfile2,'*********************************************************************************************');
                 BRB$FILE.ADD_LINE(Wfile2,'*LISTE FACTURE PAA*');
                 BRB$FILE.ADD_LINE(Wfile2,'*********************************************************************************************');
                 BRB$FILE.ADD_LINE(Wfile2,'Instance   : ' || Winstance);
                 BRB$FILE.ADD_LINE(Wfile2,'Commencé à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
                 
                                  
                 ecr ('##T');                                   -- Les Titres fix  de l'excel
                 ecr (' Liste Factures PPA');     --PREMIER TITRE DE LA PAGE 
                 ecr ('');                                          -- DEUXIEME TITRE DE LA PAGE
                 ecr ('DATE_DEBUT');                      --   NOM DE PREMIER PARAMETRE QUI VA ETRE DANS UN TABLEAU
                 ecr ('DATE_FIN');                         --   NOM DU  DEUXIEME PARAMETRE QUI VA ETRE DANS UN TABLEAU
                 ecr ('');                                 --   NOM DU  TROISIEME PARAMETRE QUI VA ETRE DANS UN TABLEAU
                 ecr('CRLF');                 -- FIN           
                       
                 ecr ('##P');
                 ecr (P_DATE_DEBUT);
                 ecr (P_DATE_FIN );
                 ecr ('');
                 ecr('CRLF'); -- FIN


                 IF TRIM(TYPE_RECHERCHE) =  'CLIENT' THEN        
                         ecr ('##H;LANCEMENT;AFFAIRE ; OTP ;CODE CLIENT  ; CREE PAR  ; DATE DE CREATION');
                         ecr('CRLF');
                         
                         ecr ('##L'); -- Premier Titre de l'excel
                         ecr ('25');  -- Longeur  COLONNE 1
                         ecr ('25');  -- Longeur  COLONNE 2
                         ecr ('25'); -- Longeur  COLONNE 3
                         ecr ('25'); -- Longeur  COLONNE 4
                         ecr ('25'); -- Longeur  COLONNE 5
                         ecr ('25'); -- Longeur  COLONNE 6
                         ecr('CRLF');
                 
                  ELSIF TRIM(TYPE_RECHERCHE) =  'REF'  THEN
                         ecr ('##H;LANCEMENT;AFFAIRE ; OTP ;REF_PIECE   ; CREE PAR  ; DATE DE CREATION');
                         ecr('CRLF');
                         
                          ecr ('##L'); -- Premier Titre de l'excel
                         ecr ('25');  -- Longeur  COLONNE 1
                         ecr ('25');  -- Longeur  COLONNE 2
                         ecr ('25'); -- Longeur  COLONNE 3
                         ecr ('25'); -- Longeur  COLONNE 4
                         ecr ('25'); -- Longeur  COLONNE 5
                         ecr ('25'); -- Longeur  COLONNE 6
                         ecr('CRLF');
                 
                  ELSIF TRIM(TYPE_RECHERCHE) =  'LANCEMENT'  THEN
                         ecr ('##H;LANCEMENT;AFFAIRE ; OTP');
                         ecr('CRLF');
                         
                         ecr ('##L'); -- Premier Titre de l'excel
                         ecr ('25');  -- Longeur  COLONNE 1
                         ecr ('25');  -- Longeur  COLONNE 2
                         ecr ('25'); -- Longeur  COLONNE 3
                         ecr('CRLF');
                 
                  END IF ;

                 

                  ecr ('##AL'); -- Alignement des colonne : [ GAUCHE : 1 ] [CENTER : 2 ] [ Droit : 3 ]
                 ecr ('2');  -- Alignement  COLONNE 1
                 ecr ('2');  -- Alignement  COLONNE 2
                 ecr ('2'); -- Alignement  COLONNE 3
                 ecr ('2'); -- Alignement  COLONNE 4
                 ecr ('2'); -- Alignement  COLONNE 5
                 ecr ('2'); -- Alignement  COLONNE 6
                 ecr ('2'); -- Alignement  COLONNE 7
                 ecr ('2'); -- Alignement  COLONNE 8
                 ecr('CRLF');
                 


                BEGIN
                              
                         IF TRIM(TYPE_RECHERCHE) =  'CLIENT'  THEN
                            
                                    FOR DATA1 IN C1(   P_DATE_DEBUT ,  P_DATE_FIN   ) LOOP
                                                            ecr('##R');
                                                            ecr( DATA1.ID );
                                                            ecr( DATA1.AFFAIRE   );
                                                            ecr( DATA1.OTP );
                                                            ecr( DATA1.CODE_CLIENT );
                                                            ecr( DATA1.CREATED_BY );
                                                             ecr( DATA1.CREATION_DATE);
                                                            ecr('CRLF');         
                                                            v_nblignes_i  :=  v_nblignes_i  + 1 ;          
                                     END LOOP;

                         ELSIF TRIM(TYPE_RECHERCHE) =  'REF'  THEN
                                     FOR DATA1 IN C2(   P_DATE_DEBUT ,  P_DATE_FIN   ) LOOP
                                                            ecr('##R');
                                                            ecr( DATA1.ID );
                                                            ecr( DATA1.AFFAIRE  );
                                                            ecr( DATA1.OTP );
                                                            ecr( DATA1.REF_PIECE );
                                                            ecr( DATA1.CREATED_BY );
                                                             ecr( DATA1.CREATION_DATE);
                                                            v_nblignes_i  :=  v_nblignes_i  + 1 ;          
                                     END LOOP;

                         ELSIF TRIM(TYPE_RECHERCHE) =  'LANCEMENT'  THEN
                                     FOR DATA1 IN C2(   P_DATE_DEBUT ,  P_DATE_FIN   ) LOOP
                                                            ecr('##R');
                                                            ecr( DATA1.ID );
                                                            ecr( DATA1.AFFAIRE  );
                                                            ecr( DATA1.OTP );
                                                            v_nblignes_i  :=  v_nblignes_i  + 1 ;          
                                     END LOOP;
                         END IF;

                END;

                  BRB$FILE.ADD_LINE(Wfile2,'nombre de lignes générées TOTAL : '|| v_nblignes_i );
                 BRB$FILE.ADD_LINE(Wfile2,'');
                 BRB$FILE.ADD_LINE(Wfile2,'Terminé  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
                 BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
                 BRB$FILE.ADD_LINE(Wfile2,'*  Fin transfert BRB_TPS0214P                                                              *');
                 BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
                 BRB$FILE.Close_File(Wfile1);
                 BRB$FILE.Close_File(Wfile2);
         END;
/
