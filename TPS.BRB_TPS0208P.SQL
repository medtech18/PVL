CREATE OR REPLACE PROCEDURE TPS.BRB_TPS0208P 
 (
 P_JOB IN Number
  )
 IS

/**************************************************************************************************
Auteur   : mElasri
Date     : 02/07/2019
Fonction : Intégration des données de la table TEMP_CA_GP_PREV  dans table GP_CA_REEL
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
                                'SAP' ETAPE
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
Winstance            Varchar2(30);
v_insert                 Varchar2(1); 
v_mess_erreur   Varchar2(200);                        
v_ligne_fa             Varchar2(4000);
v_insert_ligne     Varchar2(4500);
vnb_lig_Ni            number:= 0;
vnb_lig_i               number:= 0;
v_seq_ID               number:= 0;
v_req_val              Varchar2(1500) :=   ' INSERT INTO  GP_CA_REEL ( ID,
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
                             
v_ligne           C_chiffreAFF_PREV%ROWTYPE;
      
BEGIN

     Open  C_instance;
     Fetch C_instance into Winstance;
     Close C_Instance;

     Open  C_Param;
     Fetch C_Param into WParam;
     Close C_Param;

     Wfile2 := BRB$FILE.Open_File(WParam.repertoire,'tpsTEST_' || P_Job || '.' || WParam.suffixe_log);

     BRB$FILE.ADD_LINE(Wfile2,'*********************************************************************************************');
     BRB$FILE.ADD_LINE(Wfile2,'* Intégration des données de la table TEMP_CA_GP_PREV  dans table GP_CA_REEL - procédure BRB_TPS0208P     *');
     BRB$FILE.ADD_LINE(Wfile2,'*********************************************************************************************');  
     BRB$FILE.ADD_LINE(Wfile2,'Instance   : ' || Winstance);
     BRB$FILE.ADD_LINE(Wfile2,'Commencé à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));

       OPEN  C_chiffreAFF_PREV ;

         
        LOOP
        
        BEGIN
        
            FETCH C_chiffreAFF_PREV into  v_ligne;
            EXIT WHEN C_chiffreAFF_PREV%NOTFOUND ;
            
  
             
                                                                                        select  SEQ_ID_CA.nextval
                                                                                        into v_seq_ID
                                                                                        FROM dual;

                                                                                        v_insert_ligne  :=  v_req_val ||  v_seq_ID  || ','
                                                                                                                                                        ||'''' || v_ligne.TYPE_FACT     ||''''|| ','
                                                                                                                                                                  ||v_ligne.PERIODE     ||  ','
                                                                                                                                                        ||'''' || v_ligne.CODE_CLI_PO   ||''''|| ','
                                                                                                                                                        ||'''' || v_ligne.NOM_CLI_DO    ||''''|| ','
                                                                                                                                                        ||'''' || v_ligne.GRP_CLI_FAC   ||''''|| ','
                                                                                                                                                        ||'''' || v_ligne.ENTR_CLI_FAC  ||''''|| ','
                                                                                                                                                        ||'''' || v_ligne.CODE_CLI_FAC  ||''''|| ','
                                                                                                                                                        ||'''' || v_ligne.NOM_CLI_FAC   ||''''|| ','
                                                                                                                                                        ||'''' || v_ligne.CODE_CLI_LIV  ||''''|| ','
                                                                                                                                                        ||'''' || v_ligne.NOM_CLI_LIV   ||''''|| ','
                                                                                                                                                        ||'''' || v_ligne.CODE_PROD     ||''''|| ','
                                                                                                                                                        ||'''' || v_ligne.CODE_PROD_CLI ||''''|| ','
                                                                                                                                                        ||'''' || v_ligne.DESG_PROD     ||''''|| ','
                                                                                                                                                        ||'''' || v_ligne.CODESOC             ||''''|| ','
                                                                                                                                                                  || v_ligne.PRIX_U             ||          ','
                                                                                                                                                                  || v_ligne.QTE1                   ||        ','
                                                                                                                                                                  ||   v_ligne.CA1                    ||         ','
                                                                                                                                                        ||'''' || v_ligne.DEVISE        ||''''|| ','
                                                                                                                                                        ||'''' || v_ligne.VEHICULE      ||''''|| ','
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
                                                                                                                                      
                                                                                             ) VALUES(                   v_seq_ID ,
                                                                                                                                     v_ligne.TYPE_FACT,
                                                                                                                                    v_ligne.PERIODE,
                                                                                                                                    v_ligne.CODE_CLI_PO  ,
                                                                                                                                    v_ligne.NOM_CLI_DO ,   
                                                                                                                                    v_ligne.GRP_CLI_FAC  , 
                                                                                                                                    v_ligne.ENTR_CLI_FAC  ,
                                                                                                                                    v_ligne.CODE_CLI_FAC  ,
                                                                                                                                     v_ligne.NOM_CLI_FAC   ,
                                                                                                                                     v_ligne.CODE_CLI_LIV  ,
                                                                                                                                     v_ligne.NOM_CLI_LIV  , 
                                                                                                                                     v_ligne.CODE_PROD     ,
                                                                                                                                      v_ligne.CODE_PROD_CLI ,
                                                                                                                                      v_ligne.DESG_PROD   ,  
                                                                                                                                      v_ligne.CODESOC       ,
                                                                                                                                      v_ligne.PRIX_U     ,
                                                                                                                                      v_ligne.QTE1       ,
                                                                                                                                      v_ligne.CA1      ,
                                                                                                                                       v_ligne.DEVISE       , 
                                                                                                                                       v_ligne.VEHICULE   , 
                                                                                                                                       v_ligne.ETAPE, 
                                                                                                                                       user ,
                                                                                                                                       sysdate ,
                                                                                                                                        user ,
                                                                                                                                        sysdate );
                                                                                                                                                                                                                                                                                                                                                    
                                                                                     vnb_lig_i  := vnb_lig_i +1 ;
             
        exception
        When others Then
                    BRB$FILE.ADD_LINE(Wfile2,'Impossible de récupérer la v_ligne : ' || vnb_lig_i);
                   BRB$FILE.ADD_LINE(Wfile2,'Message '  || substr(SQLERRM, 1, 200) );
                    BRB$FILE.ADD_LINE(Wfile2,'Requete ' || v_insert_ligne);     
                    vnb_lig_Ni  := vnb_lig_Ni  +1 ;
        END;                                                                                                                                             
        END LOOP;
        
        if C_chiffreAFF_PREV%ROWCOUNT = 0   then
                BRB$FILE.ADD_LINE(Wfile2,'Aucune donnéees à transférer de la table  TEMP_CA_GP_PREV vers la table GP_CA_REEL' );
        end if;       
      CLOSE C_chiffreAFF_PREV ;   
      
      
      BRB$FILE.ADD_LINE(Wfile2,'Nombre de lignes transférées : ' || vnb_lig_i);            
      BRB$FILE.ADD_LINE(Wfile2,' Nombre de lignes NON transférées: ' ||  vnb_lig_Ni);                                    
     BRB$FILE.ADD_LINE(Wfile2,'Terminé  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
     BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
     BRB$FILE.ADD_LINE(Wfile2,'*  Fin transfert BRB_TPS0208P                                                              *');
     BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
     BRB$FILE.Close_File(Wfile2);
End;
/
