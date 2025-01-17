CREATE OR REPLACE PROCEDURE TPS.BRB_TPS0214P

 (P_JOB IN Number
 ,P_DATE_DEBUT varchar2
 ,P_DATE_FIN varchar2
 ,P_TYPE_RECHERCHE varchar2
 )
 IS



/**************************************************************************************************
Auteur   : mElasri
Date     : 29/07/2019
Fonction : Création Utilisateur ( generer liste des pieces ou client ou lancement pour une période
***************************************************************************************************/

Cursor C_instance is
       SELECT name
       FROM      sys.v_$database;

Cursor C_Param is
       SELECT repertoire,separateur,suffixe_dat,suffixe_log,base_script
       FROM      ADM_INT_PARAM;


CURSOR C0( C_DATE_DEBUT  varchar2 , C_DATE_FIN varchar2 ) IS
        select distinct  l.id , l.affaire , a.otp , c.code_client ,l.created_by ,  to_char(C.creation_date,'dd/mm/yyyy')  as creation_date
        from LANCEMENT L , 
        CLIENT_CODE_AMO C,
        AFFAIRE A
        where C.creation_date >= to_date( c_date_debut  ,'dd/mm/yyyy')    
        and  C.creation_date  <=  to_date( c_date_fin , 'dd/mm/yyyy')
        and  l.id = c.lancement 
        and l.affaire = a.affaire;

CURSOR C1( C_DATE_DEBUT  varchar2 , C_DATE_FIN varchar2 ) IS
        select distinct l.id  ,l.affaire , a.otp ,  p.ref_piece , l.created_by ,  to_char(P.creation_date,'dd/mm/yyyy')  as creation_date
        from LANCEMENT L , 
        AFFAIRE A ,
        REF_PIECE_AMORTIE P
        where P.creation_date >= to_date( c_date_debut  ,'dd/mm/yyyy') 
        and  P.creation_date <=  to_date( c_date_fin , 'dd/mm/yyyy')
        and l.affaire = a.affaire 
        and p.lancement = l.id ;

CURSOR C2( C_DATE_DEBUT  varchar2 , C_DATE_FIN varchar2 ) IS
        select distinct L.ID  ,L.AFFAIRE , A.OTP ,  to_char(l.creation_date,'dd/mm/yyyy')  as creation_date
        from LANCEMENT L , 
        AFFAIRE A
        where l.creation_date >= to_date( c_date_debut  ,'dd/mm/yyyy') 
        and l.creation_date  <=  to_date( c_date_fin , 'dd/mm/yyyy')
        and l.affaire = a.affaire  ;
        
CURSOR C3( C_DATE_DEBUT varchar2 , C_DATE_FIN varchar2 ) IS
       select MONTHS_BETWEEN(to_date( C_DATE_DEBUT   ,'mm/yyyy'),to_date(  C_DATE_FIN   ,'mm/yyyy')) from dual ;

WParam          C_Param%Rowtype;
Wfile2          UTL_FILE.FILE_TYPE;
Wfile1          UTL_FILE.FILE_TYPE;
Winstance       Varchar2(30);
v_nblignes_i    number := 0 ;
v_difference number := 0 ;

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
                 BRB$FILE.ADD_LINE(Wfile2,'*LISTE CREATION LANCEMENT - CLIENT - PIECE');
                 BRB$FILE.ADD_LINE(Wfile2,'*********************************************************************************************');
                 BRB$FILE.ADD_LINE(Wfile2,'Instance   : ' || Winstance);
                 BRB$FILE.ADD_LINE(Wfile2,'Commencé à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));


                 ecr ('##T');                          -- Les Titres fix  de l'excel
                 ecr ('Création d''utilisateur ');     -- PREMIER TITRE DE LA PAGE
                 ecr ('');                             -- DEUXIEME TITRE DE LA PAGE
                 
                 ecr ('DATE DEBUT');                   -- NOM DE PREMIER PARAMETRE QUI VA ETRE DANS UN TABLEAU
                 ecr ('DATE FIN');                     -- NOM DU  DEUXIEME PARAMETRE QUI VA ETRE DANS UN TABLEAU
                 ecr ('TYPE RECHERCHE');               -- NOM DU  TROISIEME PARAMETRE QUI VA ETRE DANS UN TABLEAU
                 ecr('CRLF');                          -- FIN

                 ecr ('##P');
                 ecr (P_DATE_DEBUT);
                 ecr (P_DATE_FIN );
                 ecr (P_TYPE_RECHERCHE);
                 ecr('CRLF'); -- FIN


                 IF TRIM(P_TYPE_RECHERCHE) =  'CLIENT' THEN
                         ecr ('##H;LANCEMENT;AFFAIRE ; OTP ;CODE CLIENT  ; CREE PAR  ; DATE DE CREATION');
                         ecr('CRLF');
                         ecr ('##L'); -- Premier Titre de l'excel
                         ecr ('25');  -- Longeur  COLONNE 1
                         ecr ('25');  -- Longeur  COLONNE 2
                         ecr ('25');  -- Longeur  COLONNE 3
                         ecr ('25');  -- Longeur  COLONNE 4
                         ecr ('25');  -- Longeur  COLONNE 5
                         ecr ('25');  -- Longeur  COLONNE 6
                         ecr('CRLF');

                  ELSIF TRIM(P_TYPE_RECHERCHE) =  'REF'  THEN
                         ecr ('##H;LANCEMENT;AFFAIRE ; OTP ;REF_PIECE   ; CREE PAR  ; DATE DE CREATION');
                         ecr('CRLF');
                         ecr ('##L'); -- Premier Titre de l'excel
                         ecr ('25');  -- Longeur  COLONNE 1
                         ecr ('25');  -- Longeur  COLONNE 2
                         ecr ('25');  -- Longeur  COLONNE 3
                         ecr ('25');  -- Longeur  COLONNE 4
                         ecr ('25');  -- Longeur  COLONNE 5
                         ecr ('25');  -- Longeur  COLONNE 6
                         ecr('CRLF');

                  ELSIF TRIM(P_TYPE_RECHERCHE) =  'LANCEMENT'  THEN
                         ecr ('##H;LANCEMENT;AFFAIRE ; OTP');
                         ecr('CRLF');
                         ecr ('##L'); -- Premier Titre de l'excel
                         ecr ('25');  -- Longeur  COLONNE 1
                         ecr ('25');  -- Longeur  COLONNE 2
                         ecr ('25');  -- Longeur  COLONNE 3
                         ecr('CRLF');

                  END IF ;

                 ecr ('##AL');-- Alignement des colonne : [ GAUCHE : 1 ] [CENTER : 2 ] [ Droit : 3 ]
                 ecr ('2');   -- Alignement  COLONNE 1
                 ecr ('2');   -- Alignement  COLONNE 2
                 ecr ('2');   -- Alignement  COLONNE 3
                 ecr ('2');   -- Alignement  COLONNE 4
                 ecr ('2');   -- Alignement  COLONNE 5
                 ecr ('2');   -- Alignement  COLONNE 6
                 ecr ('2');   -- Alignement  COLONNE 7
                 ecr ('2');   -- Alignement  COLONNE 8
                 ecr('CRLF');
                 
                IF P_DATE_FIN IS NULL OR  P_DATE_DEBUT IS NULL THEN
                       BRB$FILE.ADD_LINE(Wfile2,'ERROR : L''un des deux date est NULL');
                       ecr('##R');
                       ecr('ERRUR ! Regarder le Ficher LOG pour voir le Message D''rerreur');                         
                       ecr('CRLF');                              
                       goto DATE_ERROR ;
                END IF ;
                 
                 IF to_date(P_DATE_FIN , 'dd/mm/yyyy' )  <  to_date(P_DATE_DEBUT , 'dd/mm/yyyy' ) THEN
                      BRB$FILE.ADD_LINE(Wfile2,'ERROR : DATE FIN  est Inférieur à la date de début');
                      ecr('##R');
                      ecr('ERRUR ! Regarder le Ficher LOG  pour voir le Message D''rerreur');                         
                      ecr('CRLF');
                      goto DATE_ERROR ;
                END IF ;


                OPEN C3( to_char(to_date( P_DATE_DEBUT , 'dd/mm/yyyy' ),'mm/yyyy') ,  to_char(to_date(P_DATE_FIN, 'dd/mm/yyyy' )  ,'mm/yyyy')  )  ;  -- LA DIFFERENCE ENTRE LES DEUX DATE NE DOIT PAS DEPASSER 2 MOIS
                    fetch C3  into v_difference  ;
                CLOSE C3 ;
                  
                IF  v_difference  > 2 THEN 
                     BRB$FILE.ADD_LINE(Wfile2,'ERROR : l''écart entre la date début et la date de fin dépasse 2 Mois');
                     ecr('##R');
                     ecr('ERRUR ! Regarder le Ficher LOG pour voir le Message D''rerreur');                         
                     ecr('CRLF');
                     goto DATE_ERROR ;
                END IF ;
                   
                open C3(to_char(SYSDATE,'mm/yyyy')  ,to_char( to_date(P_DATE_DEBUT , 'dd/mm/yyyy' ) ,'mm/yyyy')  ) ;
                    fetch C3  into v_difference  ;
                CLOSE C3 ;
                                  
                IF  v_difference  > 6 THEN   -----  LA DATE DEBUT DOIT PAS AVOIR 6 MOIS DIFFERENCE AVEC LA DATE D' AUJOURDUI
                     BRB$FILE.ADD_LINE(Wfile2,'ERROR : l''écart entre la date début et la date d''Ajourd''hui dépasse 6 Mois');
                     ecr('##R');
                     ecr('ERRUR ! Regarder le Ficher LOG pour voir le Message D''rerreur');                         
                     ecr('CRLF');
                     goto DATE_ERROR ;
                 END IF ;
 
                BEGIN
                         IF TRIM(P_TYPE_RECHERCHE) =  'CLIENT'  THEN
                            FOR DATA1 IN C0( P_DATE_DEBUT ,  P_DATE_FIN   ) LOOP
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
                         ELSIF TRIM(P_TYPE_RECHERCHE) =  'REF'  THEN
                             FOR DATA1 IN C1(   P_DATE_DEBUT ,  P_DATE_FIN   ) LOOP
                                ecr('##R');
                                ecr( DATA1.ID );
                                ecr( DATA1.AFFAIRE  );
                                ecr( DATA1.OTP );
                                ecr( DATA1.REF_PIECE );
                                ecr( DATA1.CREATED_BY );
                                ecr( DATA1.CREATION_DATE);
                                ecr('CRLF');
                                v_nblignes_i  :=  v_nblignes_i  + 1 ;
                             END LOOP;
                         ELSIF TRIM(P_TYPE_RECHERCHE) =  'LANCEMENT'  THEN
                             FOR DATA1 IN C2(   P_DATE_DEBUT ,  P_DATE_FIN   ) LOOP
                                    ecr('##R');
                                    ecr( DATA1.ID );
                                    ecr( DATA1.AFFAIRE  );
                                    ecr( DATA1.OTP );
                                    ecr('CRLF');
                                    v_nblignes_i  :=  v_nblignes_i  + 1 ;
                             END LOOP;
                         END IF;
                         
            EXCEPTION
            WHEN OTHERS THEN
                   BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************' );
                   BRB$FILE.ADD_LINE(Wfile2,'Message '  || substr(SQLERRM, 1, 200) );
                   BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************' );
            END;
                                
<<DATE_ERROR>>
     BRB$FILE.ADD_LINE(Wfile2,'Nombre de lignes générées TOTAL : '|| v_nblignes_i );
     BRB$FILE.ADD_LINE(Wfile2,'');
     BRB$FILE.ADD_LINE(Wfile2,'Terminé  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
     BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
     BRB$FILE.ADD_LINE(Wfile2,'*  Fin transfert BRB_TPS0214P                                                              *');
     BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
     BRB$FILE.Close_File(Wfile1);
     BRB$FILE.Close_File(Wfile2);
                 
END;
/
