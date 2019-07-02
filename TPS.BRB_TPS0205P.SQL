CREATE OR REPLACE PROCEDURE TPS.BRB_TPS0205P

 (P_JOB IN Number
 ,P_NUM_FIC_RECUP IN varchar2
 )
 IS


/**************************************************************************************************
Auteur   : mElasri
Date     : 17/06/2019
Fonction : Récuperation du contenu du fichier REFERENCE_PIECE_A_REMONTER dans ref_piece_amortie
Appele par : BRB_TPS0198P
***************************************************************************************************/


Cursor C_instance is
       SELECT name
       FROM      sys.v_$database;

Cursor C_Param is
       SELECT repertoire,separateur,suffixe_dat,suffixe_log,base_script
       FROM      ADM_INT_PARAM;





WParam          C_Param%Rowtype;
Wfile2          UTL_FILE.FILE_TYPE;
Wfile_tst       UTL_FILE.FILE_TYPE;
Winstance       Varchar2(30);
v_fic_fa        UTL_FILE.FILE_TYPE;
v_col_fa        Varchar2(15000):=  'INSERT INTO ref_piece_amortie (
                                            LANCEMENT,
                                            REF_PIECE, 
                                            DATE_DEBUT ,
                                            CREATED_BY,
                                            CREATION_DATE, 
                                             LAST_UPDATED_BY,
                                             LAST_UPDATE_DATE 
                                             )VALUES (';

v_valeur_champ      Varchar2(250);
v_insert            Varchar2(1);
v_mess_erreur       Varchar2(200);
v_ligne_fa          Varchar2(4000);
v_insert_ligne      Varchar2(4000);
vnb_lig             number:= 0;
vnb_lig_i           number:= 0;
v_pos_pipe          number:= 0;
v_num_champ         number:= 0;
v_req_val           Varchar2(4000);
v_lancement_number    ref_piece_amortie.LANCEMENT %TYPE:= 0;
v_ref_piece    ref_piece_amortie.REF_PIECE %TYPE:= 0;
v_date_debut_lancement     VARCHAR2(20) ;
trash                ref_piece_amortie.LANCEMENT %TYPE:= 0;



TYPE counter_type IS RECORD (
    value  number := 0 );
TYPE lancement_type IS TABLE OF   counter_type INDEX BY BINARY_INTEGER;
lancement_tab lancement_type ;
i number:=0 ;

ERREUR                       exception;
foreignK_error         exception;
date_debut_diff     exception;


cursor c1(w_lancement_number number) is Select L.ID
                    From LANCEMENT L
                    Where L.ID = w_lancement_number;

cursor c2 (w_lancement_number number,w_ref_piece varchar2)
 is Select R.LANCEMENT
                    From  REF_PIECE_AMORTIE R
                    Where (R.LANCEMENT = v_lancement_number)  AND (R.REF_PIECE = TRIM(v_ref_piece)  );


Function tst_fichier(zfichier in varchar2) return boolean is
    Wfile_tst            UTL_FILE.FILE_TYPE;
      Begin
         Wfile_tst := BRB$FILE.Open_File(WParam.repertoire,zfichier,'r');
         BRB$FILE.Close_File(Wfile_tst);
         return true;
         Exception When UTL_FILE.INVALID_OPERATION Then
         return false;
      End;
Begin



         Open  C_instance;
         Fetch C_instance into Winstance;
         Close C_Instance;

         Open  C_Param;
         Fetch C_Param into WParam;
         Close C_Param;

         Wfile2 := BRB$FILE.Open_File(WParam.repertoire,'tps0205_' || P_Job || '.' || WParam.suffixe_log);

         BRB$FILE.ADD_LINE(Wfile2,'*********************************************************************************************');
         BRB$FILE.ADD_LINE(Wfile2,'* Intégration du fichier '||P_NUM_FIC_RECUP ||' dans table ref_piece_amortie - procédure BRB_TPS0205P     *');
         BRB$FILE.ADD_LINE(Wfile2,'*********************************************************************************************');
         BRB$FILE.ADD_LINE(Wfile2,'Instance   : ' || Winstance);
         BRB$FILE.ADD_LINE(Wfile2,'Commencé à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));




         if not tst_fichier(P_NUM_FIC_RECUP) then
              v_mess_erreur := 'FICHIER '||Wparam.repertoire||'/'||P_NUM_FIC_RECUP||' INEXISTANT';
              raise erreur;
         end if;


        v_fic_fa := UTL_FILE.FOPEN(WParam.repertoire,P_NUM_FIC_RECUP,'r');
        UTL_FILE.GET_LINE(v_fic_fa,v_ligne_fa);
        UTL_FILE.GET_LINE(v_fic_fa,v_ligne_fa);

        BEGIN


            LOOP


                vnb_lig := vnb_lig + 1;

                BEGIN

                    LOOP

                          v_pos_pipe      := nvl(INSTR(v_ligne_fa, ';', 1, 1),0);
                          v_num_champ := v_num_champ + 1;
                          if v_pos_pipe = 0 then
                                         v_valeur_champ  := v_ligne_fa;
                          else
                                        v_valeur_champ  := SUBSTR(v_ligne_fa,1,v_pos_pipe-1);
                          end if;

                          if v_num_champ <> 4 then


                                             if v_num_champ = 3 then
                                                        v_valeur_champ := '''' ||TRIM(v_valeur_champ) || '''';
                                                        v_date_debut_lancement := v_valeur_champ;
                                                        v_valeur_champ := 'to_date('|| v_valeur_champ|| ',''dd/mm/yyyy'')' ;
                                              elsif v_num_champ = 2 then
                                                        v_valeur_champ := '''' ||   TRIM(v_valeur_champ) || '''';
                                                        v_ref_piece :=   TRIM(v_valeur_champ);
                                              else
                                                        v_valeur_champ := TRIM(v_valeur_champ);
                                              end if ;

                                          if v_num_champ = 1 then
                                                       v_req_val := v_req_val || v_valeur_champ;
                                                       v_lancement_number:= nvl(TRIM(v_valeur_champ),0);

                                          else
                                                        v_req_val := v_req_val || ',' || v_valeur_champ;
                                          end if;

                          end if;


                          EXIT WHEN v_pos_pipe = 0;
                          v_ligne_fa  := SUBSTR(v_ligne_fa,v_pos_pipe + 1,LENGTH(v_ligne_fa) - v_pos_pipe + 1 );

                    END LOOP;

                    if v_lancement_number <> 0 then

                                                -- Verifier si lancement exisite deja dans la table lancement details
                                                open c1(v_lancement_number);
                                                fetch c1 into trash ;

                                                If c1%NOTFOUND  Then
                                                close c1;
                                               v_req_val := v_req_val || ',''' || user || ''',''' || sysdate || ''','''  || user || ''',''' || sysdate || '''';
                                                v_insert_ligne := v_col_fa  || v_req_val || ')';

                                                  raise foreignK_error ;
                                                else
                                                close c1;
                                                end if;
                                                
                                --  Verifier si lancement exisite deja dans la table  REF_CLIENT_AMORTI mais avec une date different

                                                open c2(v_lancement_number , v_ref_piece) ;
                                                fetch c2 into trash ;
                                                If c2%FOUND and v_lancement_number <> 0  Then
                                                close c2;
                                                        v_req_val := v_req_val || ',''' || user || ''',''' || sysdate || ''','''  || user || ''',''' || sysdate || '''';
                                                         v_insert_ligne := v_col_fa  || v_req_val || ')';


                                                 raise date_debut_diff;
                                                else
                                                close c2;
                                                end if;
                                          
 
                                                if LENGTH(v_req_val) >= 3  then

                                                        v_req_val := v_req_val || ',''' || user || ''',''' || sysdate || ''','''  || user || ''',''' || sysdate || ''''; 
                                                        v_insert_ligne := v_col_fa  || v_req_val || ')'; 
                                                        
                                                        execute immediate(v_insert_ligne); 
                                                        commit;
                                                           
                                                         vnb_lig_i := vnb_lig_i + 1;        
                                                    
                                                   --- la , chaque index du tableau  lancement_tab represent un numero de lancemen , donc pour chaque numero de lancement on va mettre le nombre de ligne qui le represent
                                                    if lancement_tab.exists(v_lancement_number) then
                                                                lancement_tab(v_lancement_number).value := lancement_tab(v_lancement_number).value + 1 ;
                                                    else
                                                                 lancement_tab(v_lancement_number).value := 1 ;
                                                    end if ;
    
                                             END IF ;
                    end if ;

                    v_req_val := null;
                    v_num_champ := 0;

                exception
                      when dup_val_on_index then
                        BRB$FILE.ADD_LINE(Wfile2,'Impossible de récupérer la ligne : ' || vnb_lig);
                        BRB$FILE.ADD_LINE(Wfile2,'Message : La ligne existe deja dans la table REFERENCE_PIECE_A_REMONTER' );
                       BRB$FILE.ADD_LINE(Wfile2,'Requete ' || v_insert_ligne);
                        v_req_val := null;
                        v_num_champ := 0;
                     when  date_debut_diff then
                         BRB$FILE.ADD_LINE(Wfile2,'Impossible de récupérer la ligne : ' || vnb_lig);
                         BRB$FILE.ADD_LINE(Wfile2,'Message : La ligne existe deja avec une date debut different dans la table REFERENCE_PIECE_A_REMONTER' );
                         BRB$FILE.ADD_LINE(Wfile2,'Requete ' || v_insert_ligne);
                         v_req_val := null;
                         v_num_champ := 0;
                      when foreignK_error then
                        BRB$FILE.ADD_LINE(Wfile2,'Impossible de récupérer la ligne : ' || vnb_lig);
                        BRB$FILE.ADD_LINE(Wfile2,'Message : La clé primaire n existe pas  dans la table LANCEMENT_DETAILS' );
                        BRB$FILE.ADD_LINE(Wfile2,'Requete ' || v_insert_ligne);
                        v_req_val := null;
                        v_num_champ := 0;
                        
                      When others Then
                        BRB$FILE.ADD_LINE(Wfile2,'Impossible de récupérer la ligne : ' || vnb_lig);
                        BRB$FILE.ADD_LINE(Wfile2,'Message '  || substr(SQLERRM, 1, 200) );
                        BRB$FILE.ADD_LINE(Wfile2,'Requete ' || v_insert_ligne);
                        v_req_val := null;
                        v_num_champ := 0;

                END;
               UTL_FILE.GET_LINE(v_fic_fa,v_ligne_fa);
            END LOOP;


        exception
            When NO_DATA_FOUND Then
                BRB$FILE.ADD_LINE(Wfile2,'Femeture fichier à la ligne : ' || vnb_lig);
                  UTL_FILE.FCLOSE (v_fic_fa);

        end;

    -- dans cette boucle , il y  un tableau s'appel lancement_tab , ce tab contient des index qui represents lancement_tab , et chaque index il contient nombre de lignes qui le represent

            i := nvl(lancement_tab.FIRST,0);


            WHILE i <> 0 LOOP
                 BRB$FILE.ADD_LINE(Wfile2,'nombre de lignes integrées pour le lancement N° : ' || i || ' :  ' || lancement_tab(i).value);
                i := nvl(lancement_tab.NEXT(i),0);  -- Get next element of array
                EXIT WHEN i = 0 ;
            END LOOP;


             BRB$FILE.ADD_LINE(Wfile2,'Nombre de lignes integrées : ' || vnb_lig_i);
             BRB$FILE.ADD_LINE(Wfile2,'Terminé  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
             BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
             BRB$FILE.ADD_LINE(Wfile2,'*  Fin transfert BRB_TPS0205P                                                              *');
             BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
             BRB$FILE.Close_File(Wfile2);

     Exception
        When ERREUR then
               BRB$FILE.ADD_LINE(Wfile2,v_mess_erreur);
               BRB$FILE.ADD_LINE(Wfile2,'Terminé en ERREUR  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
               BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
               BRB$FILE.ADD_LINE(Wfile2,'*  Fin transfert BRB_TPS0205P                                                              *');
               BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
               BRB$FILE.Close_File(Wfile2);
End;
/
