CREATE OR REPLACE PROCEDURE TPS.BRB_TPS0209P (
  P_JOB IN Number ,
  P_NUM_FIC_RECUP IN varchar2 ,
  P_PERIODE_CIBLE  IN Number 
  )
  IS
  
  
/**************************************************************************************************
Auteur   : mElasri
Date     : 03/07/2019
Fonction : Récuperation du contenu du fichier ca_sap dans table TEMP_CA_GP_PREV  et l'Intégration de certains  données de la table TEMP_CA_GP_PREV  dans table GP_CA_REEL
***************************************************************************************************/
  
                Cursor C_instance is
                       SELECT name
                       FROM      sys.v_$database;

                Cursor C_Param is
                       SELECT repertoire,separateur,suffixe_dat,suffixe_log,base_script
                       FROM      ADM_INT_PARAM;
                       
                       
                WParam          C_Param%Rowtype;
                Wfile2          UTL_FILE.FILE_TYPE;
                Winstance            Varchar2(30);
                
                
              OK  BOOLEAN:= FALSE;

            BEGIN


                 Open  C_instance;
                 Fetch C_instance into Winstance;
                 Close C_Instance;

                 Open  C_Param;
                 Fetch C_Param into WParam;
                 Close C_Param;

                 Wfile2 := BRB$FILE.Open_File(WParam.repertoire,'tps0208_'|| P_Job || '.' || WParam.suffixe_log);

                 BRB$FILE.ADD_LINE(Wfile2,'*********************************************************************************************');
                 BRB$FILE.ADD_LINE(Wfile2,'*Récuperation du contenu du fichier ca_sap dans table TEMP_CA_GP_PREV  et l Intégration de certains  données de la table TEMP_CA_GP_PREV  dans table GP_CA_REEL      *');
                 BRB$FILE.ADD_LINE(Wfile2,'*********************************************************************************************');  
                 BRB$FILE.ADD_LINE(Wfile2,'Instance   : ' || Winstance);
                 BRB$FILE.ADD_LINE(Wfile2,'Commencé à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
                 BRB$FILE.ADD_LINE(Wfile2,'');
                 BRB$FILE.ADD_LINE(Wfile2,'');
                 BRB$FILE.ADD_LINE(Wfile2,'');
                BRB$FILE.Close_File(Wfile2);
              
                        BEGIN
                        
                             TPS.BRB_TPS0207P ( P_JOB, P_NUM_FIC_RECUP,OK);
                             
                             if OK then 
                                  TPS.BRB_TPS0208P ( P_JOB, P_PERIODE_CIBLE );
                             end if;
                             
                        END BRB_TPS0209P;
                        
                Wfile2 := BRB$FILE.Open_File(WParam.repertoire,'tps0208_'|| P_Job || '.' || WParam.suffixe_log , 'A');      
                 BRB$FILE.ADD_LINE(Wfile2,'');
                 BRB$FILE.ADD_LINE(Wfile2,'');
                 BRB$FILE.ADD_LINE(Wfile2,'');  
                 BRB$FILE.ADD_LINE(Wfile2,'Terminé  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
                 BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
                 BRB$FILE.ADD_LINE(Wfile2,'*  Fin transfert BRB_TPS0209P                                                              *');
                 BRB$FILE.ADD_LINE(Wfile2,'****************************************************************************************');
                 BRB$FILE.Close_File(Wfile2);
         END;
/
