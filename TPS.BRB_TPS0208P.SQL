CREATE OR REPLACE PROCEDURE TPS.BRB_TPS0208P
 (P_JOB IN Number)
 IS

/**************************************************************************************************
Auteur   : mElasri
Date     : 17/06/2019
Fonction : Récuperation du contenu du fichier ca_sap dans table TEMP_CA_GP_PREV
Appele par : BRB_TPS0208P
***************************************************************************************************/


Cursor C_instance is
       SELECT name
       FROM      sys.v_$database;

Cursor C_Param is
       SELECT repertoire,separateur,suffixe_dat,suffixe_log,base_script
       FROM      ADM_INT_PARAM;
       
       
  CURSOR C_chiffreAFF_PREV
  IS
    (select 
                                TYPE_FACT,       
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
                                CODESOC   ,
                                PRIX_U,
                                SUM(QTE1) AS QTE1 ,
                                SUM(CA1)  AS CA1 ,
                                DEVISE,
                                VEHICULE,
                                'SAP'
 from  TEMP_CA_GP_PREV   , SOCDIVEXP  
 where SITE_FAB  = CODESOC (+)
group by TYPE_FACT,
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
                    DEVISE,
                    VEHICULE,
                    CODESOC ) ;

WParam          C_Param%Rowtype;
Wfile2          UTL_FILE.FILE_TYPE;
Wfile_tst       UTL_FILE.FILE_TYPE;
Winstance       Varchar2(30);
v_fic_fa        UTL_FILE.FILE_TYPE;
v_insert        Varchar2(1); 
v_mess_erreur   Varchar2(200);                        
v_ligne_fa      Varchar2(4000);
v_insert_ligne  Varchar2(4500);
vnb_lig         number:= 0;
vnb_lig_i       number:= 0;
v_seq_ID number:= 0;
v_req_val       Varchar2(1500) :=   ' INSERT INTO  GP_CA_REEL ( ID,
                         TYPE_FACT,
                         PERIODE, 
                          CODE_CLI_PO,
                          NOM_CLI_PO,
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
                            QUANTITE, 
                            VALEUR_FAC, 
                            DEVISE, 
                            VEH_SERIE,
                            ORIGINE ,
                             CREATED_BY,
                             CREATION_DATE,
                             LAST_UPDATED_BY,
                              LAST_UPDATE_DATE
                             ) VALUES(';
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
     BRB$FILE.ADD_LINE(Wfile2,'* Intégration du fichier ' ||'XXXX' ||' dans table TEMP_CA_GP_PREV - procédure BRB_TPS0208P    *');
     BRB$FILE.ADD_LINE(Wfile2,'*********************************************************************************************');  
     BRB$FILE.ADD_LINE(Wfile2,'Instance   : ' || Winstance);
     BRB$FILE.ADD_LINE(Wfile2,'Commencé à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
        
     
        BEGIN
                      FOR ligne IN C_chiffreAFF_PREV
                      LOOP
                      
                      EXIT WHEN vnb_lig_i  >10 ;
                      
                        select  SEQ_ID_CA.nextval
                        into v_seq_ID
                        FROM dual;

                        
                      v_insert_ligne  :=  v_req_val ||  v_seq_ID  || ','
                                                                                        ||'''' || ligne.TYPE_FACT     ||''''|| ','
                                                                                                   ||      ligne.PERIODE     ||  ','
                                                                                        ||'''' || ligne.CODE_CLI_PO   ||''''|| ','
                                                                                        ||'''' || ligne.NOM_CLI_DO    ||''''|| ','
                                                                                        ||'''' || ligne.GRP_CLI_FAC   ||''''|| ','
                                                                                        ||'''' || ligne.ENTR_CLI_FAC  ||''''|| ','
                                                                                        ||'''' || ligne.CODE_CLI_FAC  ||''''|| ','
                                                                                        ||'''' || ligne.NOM_CLI_FAC   ||''''|| ','
                                                                                        ||'''' || ligne.CODE_CLI_LIV  ||''''|| ','
                                                                                        ||'''' || ligne.NOM_CLI_LIV   ||''''|| ','
                                                                                        ||'''' || ligne.CODE_PROD     ||''''|| ','
                                                                                        ||'''' || ligne.CODE_PROD_CLI ||''''|| ','
                                                                                        ||'''' || ligne.DESG_PROD     ||''''|| ','
                                                                                        ||'''' || ligne.CODESOC             ||''''|| ','
                                                                                                  || ligne.PRIX_U             ||          ','
                                                                                                  || ligne.QTE1                   ||        ','
                                                                                                  ||   ligne.CA1                    ||         ','
                                                                                        ||'''' || ligne.DEVISE        ||''''|| ','
                                                                                        ||'''' || ligne.VEHICULE      ||''''|| ','
                                                                                                  || '''SAP''' ||  ',''' || user || ''',''' || sysdate || ''','''  || user || ''',''' || sysdate || ''')'; 
                                                                                                  
                                                                                                  
                     INSERT INTO  GP_CA_REEL ( ID,
                                                                 TYPE_FACT,
                                                                 PERIODE, 
                                                                  CODE_CLI_PO,
                                                                  NOM_CLI_PO,
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
                                                                    QUANTITE, 
                                                                    VALEUR_FAC, 
                                                                    DEVISE, 
                                                                    VEH_SERIE,
                                                                    ORIGINE ,
                                                                     CREATED_BY,
                                                                     CREATION_DATE,
                                                                     LAST_UPDATED_BY,
                                                                      LAST_UPDATE_DATE
                                                                      
                             ) VALUES(                   SEQ_ID_CA.nextval ,
                                                                    ligne.PERIODE,
                                                                    ligne.CODE_CLI_PO  ,
                                                                    ligne.NOM_CLI_DO ,   
                                                                    ligne.GRP_CLI_FAC  , 
                                                                    ligne.ENTR_CLI_FAC  ,
                                                                    ligne.CODE_CLI_FAC  ,
                                                                     ligne.NOM_CLI_FAC   ,
                                                                     ligne.CODE_CLI_LIV  ,
                                                                     ligne.NOM_CLI_LIV  , 
                                                                     ligne.CODE_PROD     ,
                                                                      ligne.CODE_PROD_CLI ,
                                                                      ligne.DESG_PROD   ,  
                                                                      ligne.CODESOC       ,
                                                                      ligne.PRIX_U     ,
                                                                      ligne.QTE1       ,
                                                                      ligne.CA1      ,
                                                                       ligne.DEVISE       , 
                                                                       ligne.VEHICULE   ,  
                                                                       user ,
                                                                       sysdate ,
                                                                        user ,
                                                                        sysdate ); 
                                                                        
                                                                        
                                          dbms_OUTPUT.PUT_LINE( vnb_lig_i);

                     
                     vnb_lig_i  := vnb_lig_i +1 ;
                                                          
                      END LOOP;
                      
                      
                             BRB$FILE.ADD_LINE(Wfile2,'Nombre de lignes integrées : ' || vnb_lig_i); 
                             BRB$FILE.ADD_LINE(Wfile2,'Terminé  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
                             BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
                             BRB$FILE.ADD_LINE(Wfile2,'*  Fin transfert des donné de la table    TEMP_CA_GP_PREV     dans GP_CA_REEL                                         *');
                             BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
                                              
                      
                    exception
                          When others Then
                            BRB$FILE.ADD_LINE(Wfile2,'Impossible de récupérer la ligne : ' || vnb_lig);
                            BRB$FILE.ADD_LINE(Wfile2,'Message '  || substr(SQLERRM, 1, 200) );
                            BRB$FILE.ADD_LINE(Wfile2,'Requete ' || v_insert_ligne);
              end;
              
 end;
/
