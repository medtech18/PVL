CREATE OR REPLACE PROCEDURE TPS.BRB_TPS0204P
 (P_JOB IN Number
 ,P_NUM_FIC_RECUP IN varchar2
 ,P_PERIODE_CIBLE  IN Number 
 )
 IS

/**************************************************************************************************
Auteur   : mElasri
Date     : 17/06/2019
Fonction : Récuperation du contenu du fichier Transnav dans table GP_CA_Reel
Appele par : BRB_TPS0204P
***************************************************************************************************/


Cursor C_instance is
       SELECT name
       FROM      sys.v_$database;

Cursor C_Param is
       SELECT repertoire,separateur,suffixe_dat,suffixe_log,base_script
       FROM      ADM_INT_PARAM;

-- Recherche max ID 
Cursor c_ctrl is
Select periode
From GP_CA_Reel
Where periode = P_PERIODE_CIBLE;
r_ctrl c_ctrl %ROWTYPE;
      


WParam          C_Param%Rowtype;
Wfile2          UTL_FILE.FILE_TYPE;
Wfile_tst       UTL_FILE.FILE_TYPE;
Winstance       Varchar2(30);
v_fic_fa        UTL_FILE.FILE_TYPE;
v_col_fa        Varchar2(15000):=  'INSERT INTO GP_CA_REEL (
                                                ID,
                                                ORIGINE,
                                                ETAB_FAC,
                                                SITE_FAB,
                                                PERIODE, 
                                                CODE_PROD, 
                                                DESG_PROD, 
                                                CODE_PROD_CLI,
                                                FAMILLE_PIECE, 
                                                VEH_SERIE,
                                                GRP_HGRP, 
                                                OEM_DIRECT,
                                                GRP_CLI_FAC, 
                                                ENTR_CLI_FAC,
                                                CODE_CLI_FAC,          
                                                NOM_CLI_FAC, 
                                                CODE_PAYS_CLI_FAC, 
                                                PAYS_CLI_FAC, 
                                                CODE_CLI_LIV, 
                                                NOM_CLI_LIV, 
                                                CODE_PAYS_CLI_LIV, 
                                                PAYS_CLI_LIV, 
                                                FONCTION_PIECE , 
                                                SEC_ACH_PIECE, 
                                                TYPE_FACT,
                                                DEVISE, 
                                                PRIX_U, 
                                                PRIX_U_H_AMO, 
                                                QUANTITE, 
                                                VALEUR_FAC, 
                                                VALEUR_FAC_HORS_AMO, 
                                                CREATED_BY,
                                                CREATION_DATE,
                                                LAST_UPDATED_BY,
                                                LAST_UPDATE_DATE
                                                                
                                         )VALUES (SEQ_ID_CA.nextval,''USA'''; 
                                                                                            
                                
v_valeur_champ  Varchar2(250);  
v_insert        Varchar2(1); 
v_mess_erreur   Varchar2(200);                        
v_ligne_fa      Varchar2(4000);
v_insert_ligne  Varchar2(4000);
vnb_lig         number:= 0;
vnb_lig_i       number:= 0;
v_pos_pipe      number:= 0;
v_num_champ     number:= 0;
v_req_val       Varchar2(4000);
v_socppa        Varchar2(3);
ok              number:= 0 ; -- valeur boolean , elle false en 0 , et true en 1

ERREUR          exception;


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

     Wfile2 := BRB$FILE.Open_File(WParam.repertoire,'tpsTEST_' || P_Job || '.' || WParam.suffixe_log);

     BRB$FILE.ADD_LINE(Wfile2,'*********************************************************************************************');
     BRB$FILE.ADD_LINE(Wfile2,'* Intégration du fichier '||P_NUM_FIC_RECUP ||' dans table GP_CA_Reel - procédure BRB_TPS0204P     *');
     BRB$FILE.ADD_LINE(Wfile2,'*********************************************************************************************');  
     --BRB$FILE.ADD_LINE(Wfile2,'Période cible  : ' || P_PERIOD_CIBLE); -- ??? 
     BRB$FILE.ADD_LINE(Wfile2,'Instance   : ' || Winstance);
     BRB$FILE.ADD_LINE(Wfile2,'Commencé à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));




     if not tst_fichier(P_NUM_FIC_RECUP) then
          v_mess_erreur := 'FICHIER '||Wparam.repertoire||'/'||P_NUM_FIC_RECUP||' INEXISTANT';
          raise erreur;
     end if;
      
     /*
     Open  c_ctrl;
     Fetch c_ctrl Into r_ctrl;
     If c_ctrl %FOUND Then
        Close c_ctrl;


        commit;
        Close c_ctrl;
     End if;
    
     */
  
        
        DELETE from GP_CA_Reel
        where PERIODE = P_PERIODE_CIBLE and ORIGINE = 'USA';
        commit;
        dbms_output.put_line(SQL%ROWCOUNT  ||'rows were deleted');
        
    
        v_fic_fa := UTL_FILE.FOPEN(WParam.repertoire,P_NUM_FIC_RECUP,'r');

        
        
      
        BEGIN
                          
            LOOP 
 <<NOT_ROW>>           
       
                UTL_FILE.GET_LINE(v_fic_fa,v_ligne_fa);
                vnb_lig := vnb_lig + 1; 
            
                if nvl(INSTR(v_ligne_fa, trim(P_PERIODE_CIBLE), 1, 1),0) = 0 then -- si on trouve pas la periode cible sur la ligne on saute vers [not row] pour passer a la ligne suivante
                
                goto NOT_ROW ;
                    
                end if;
            
            
                BEGIN
                   
              
                    LOOP
                        
                          v_pos_pipe      := nvl(INSTR(v_ligne_fa, ';', 1, 1),0);                                                   
                          v_num_champ := v_num_champ + 1;
                          if v_pos_pipe = 0 then
                             v_valeur_champ  := v_ligne_fa;
                          else
                             v_valeur_champ  := SUBSTR(v_ligne_fa,1,v_pos_pipe-1);
                          end if;
                          
                          if v_num_champ <> 33  then   
                                                        
                             if (v_num_champ not in  (3,31)) AND (v_num_champ < 26) then 
                             
                             v_valeur_champ := REPLACE (v_valeur_champ, '"', '');
                             v_valeur_champ := '''' ||   v_valeur_champ || '''';

                             elsif (v_num_champ <= 30) AND (v_num_champ >= 26) then
                                   
                                   v_valeur_champ := REPLACE(v_valeur_champ, ',', '.');  
                                   v_valeur_champ := REPLACE(v_valeur_champ, '$', '');   
                                   v_valeur_champ := REPLACE(v_valeur_champ, '¿', '');  
                                   v_valeur_champ := REPLACE(v_valeur_champ, '?', '');  
                                   v_valeur_champ := REPLACE (v_valeur_champ, ' ', '');
                                   
                                   
                             end if; 

                                  if v_num_champ not in (10,31,32,33) then
                                    v_req_val := v_req_val || ',' || v_valeur_champ;
                                  end if;
                      
                               
                          end if;  
                          EXIT WHEN v_pos_pipe = 0;  
                          v_ligne_fa  := SUBSTR(v_ligne_fa,v_pos_pipe + 1,LENGTH(v_ligne_fa) - v_pos_pipe + 1 ); 
                                    
                    END LOOP;
                    
                    v_req_val := v_req_val || ',''' || user || ''',''' || sysdate || ''','''  || user || ''',''' || sysdate || '''';
                    v_insert_ligne := v_col_fa  || v_req_val || ')';  
                    vnb_lig_i := vnb_lig_i + 1;
                    execute immediate(v_insert_ligne);
                    commit;  
                    v_req_val := null;
                    v_num_champ := 0;
                exception
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
        BRB$FILE.ADD_LINE(Wfile2,'Nombre de lignes integrées : ' || vnb_lig_i);
          
     
     BRB$FILE.ADD_LINE(Wfile2,'Terminé  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
     BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
     BRB$FILE.ADD_LINE(Wfile2,'*  Fin transfert BRB_TPS0204P                                                              *');
     BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
     BRB$FILE.Close_File(Wfile2);
     
     Exception
        When ERREUR then
               BRB$FILE.ADD_LINE(Wfile2,v_mess_erreur);
               BRB$FILE.ADD_LINE(Wfile2,'Terminé en ERREUR  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
               BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
               BRB$FILE.ADD_LINE(Wfile2,'*  Fin transfert BRB_TPS0204P                                                              *');
               BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
               BRB$FILE.Close_File(Wfile2);
End;
/
