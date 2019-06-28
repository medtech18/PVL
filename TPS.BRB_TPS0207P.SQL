CREATE OR REPLACE PROCEDURE TPS.BRB_TPS0207P
 (P_JOB IN Number
 ,P_NUM_FIC_RECUP IN varchar2
 )
 IS

/**************************************************************************************************
Auteur   : mElasri
Date     : 17/06/2019
Fonction : Récuperation du contenu du fichier ca_sap dans table TEMP_CA_GP_PREV
Appele par : BRB_TPS0207P
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
v_col_fa        Varchar2(15000):=  'INSERT INTO TEMP_CA_GP_PREV (
                                                ETAPE,
                                                TYPE_FACT,
                                                NUM_FACTURE,
                                                PERIODE,
                                                CODE_CLI_PO,
                                                NOM_CLI_DO,
                                                GRP_CLI_FAC,
                                                ENTR_CLI_FAC,
                                                CODE_CLI_FAC,
                                                NOM_CLI_FAC,
                                                CODE_CLI_LIV,
                                                NOM_CLI_LIV,
                                                CODE_PROD,
                                                CODE_PROD_CLI,
                                                DESG_PROD,
                                                SITE_FAB,
                                                PRIX_U,
                                                QTE1,
                                                CA1,
                                                DEVISE,
                                                VEHICULE,
                                                CREATED_BY,
                                                CREATION_DATE,
                                                LAST_UPDATED_BY,
                                                LAST_UPDATE_DATE                                     
                                         )VALUES (''CA_SAP'''; 
                                                                                            
                                
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
     BRB$FILE.ADD_LINE(Wfile2,'* Intégration du fichier '||P_NUM_FIC_RECUP ||' dans table TEMP_CA_GP_PREV - procédure BRB_TPS0207P     *');
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
                          
                          if v_num_champ <> 35  then   
                                                      
                               if v_num_champ in  (1,2,5,30,31,23) OR ((v_num_champ >= 6   AND  v_num_champ <=20) AND v_num_champ not in (8,10,12,17)) then -- cette condition est pour limiter v_num champ en 1,2,30,31, et de 6-7 9 11 13-16 17-20
                                
                                      v_valeur_champ := REPLACE(v_valeur_champ, '¿', '');  
                                      v_valeur_champ := REPLACE(v_valeur_champ, '?', ''); 
                                      v_valeur_champ := REPLACE(v_valeur_champ, '''', '');   
                                      v_valeur_champ := '''' ||   TRIM(v_valeur_champ) || ''''; 
                                      
                                      if v_num_champ = 5 then
                                         v_valeur_champ := to_char(to_date('17/05/2019', 'dd/mm/yyyy'), 'YYYYMM');
                                      end if;
                                      
                                      v_req_val := v_req_val || ',' || v_valeur_champ;
                    
                               elsif v_num_champ  IN (27,28,29) then
                                        v_valeur_champ := TRIM(v_valeur_champ);  
                                        v_valeur_champ := REPLACE (v_valeur_champ, ' ', '');
                                        v_valeur_champ := REPLACE(v_valeur_champ, ',', '.');  
                                        v_req_val := v_req_val || ',' || v_valeur_champ;                            
                               end if ;
                          end if; 
                          
                                                    
                          EXIT WHEN v_pos_pipe = 0;  
                          v_ligne_fa  := SUBSTR(v_ligne_fa,v_pos_pipe + 1,LENGTH(v_ligne_fa) - v_pos_pipe + 1 ); 
                                    
                    END LOOP;
                    
                    
                    if LENGTH(v_req_val) > 20 then 
                    
                     v_req_val := v_req_val || ',''' || user || ''',''' || sysdate || ''','''  || user || ''',''' || sysdate || '''';
                     v_insert_ligne := v_col_fa  || v_req_val || ')';  
                     vnb_lig_i := vnb_lig_i + 1;
                     execute immediate(v_insert_ligne);
                     commit;  
                    end if ;
                    
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
     BRB$FILE.ADD_LINE(Wfile2,'*  Fin transfert BRB_TPS0207P                                                              *');
     BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
     BRB$FILE.Close_File(Wfile2);
     
     Exception
        When ERREUR then
               BRB$FILE.ADD_LINE(Wfile2,v_mess_erreur);
               BRB$FILE.ADD_LINE(Wfile2,'Terminé en ERREUR  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
               BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
               BRB$FILE.ADD_LINE(Wfile2,'*  Fin transfert BRB_TPS0207P                                                              *');
               BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
               BRB$FILE.Close_File(Wfile2);
End;
/
