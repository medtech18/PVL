CREATE OR REPLACE PROCEDURE TPS.BRB_TPS0201P

 (P_JOB IN Number,
 P_AFFAIRE IN Varchar2,
 P_OTP IN Varchar2,
 P_REF_PIECE IN Varchar2
 )
 IS


/**************************************************************************************************
Auteur   : NGC
Date     : MARS 2019
Fonction : Part amortissement par référence pièce
***************************************************************************************************/
Cursor C_instance is
	   SELECT name
	   FROM	  sys.v_$database;

Cursor C_Param is
	   SELECT repertoire,separateur,suffixe_dat,suffixe_log,base_script
	   FROM	  ADM_INT_PARAM;
       
cursor C1_SITE (w_lancement_number number,w_ref_piece varchar2)
 is Select distinct A.code_soc
                    From  AMORTISSEMENT_PIECE A
                     Where A.LANCEMENT = TRIM(w_lancement_number )  AND (A.REF_PIECE LIKE '%' || TRIM(w_ref_piece) || '%' );
                     
cursor C2_SITE (w_lancement_number number)
 is Select distinct A.code_soc
                    From  AMORTISSEMENT_PIECE A
                     Where A.LANCEMENT = TRIM(w_lancement_number ) ;
                     
                     
Cursor C_data is -- Données à traiter
select l.affaire,
A.OTP,
a.client,
'''' || r.ref_piece ref_piece,
 r.ref_piece c_ref_piece ,
to_char(r.date_debut,'DD/MM/YYYY') date_debut_ref,
to_char(r.date_fin ,'DD/MM/YYYY')  date_fin_ref ,
r.lancement, 
l.fonction,
l.amo_cache,
l.type_g,
 to_char(d.date_debut ,'DD/MM/YYYY')  date_debut_lanc,
to_char(d.date_fin  ,'DD/MM/YYYY')  date_fin_lanc,  
d.bdg_vente, 
d.bdg_vente_fact_out , 
d.bdg_vente_amortie_out, 
d.quantite, decode(d.quantite, 0, 0, round(d.bdg_vente_amortie_out/ d.quantite, 5)) part_amo,
cli.cli_1,
 to_char(cli.date_fin_1  ,'DD/MM/YYYY')    date_fin_1 ,
cli.cli_2,
 to_char(cli.date_fin_2  ,'DD/MM/YYYY')     date_fin_2,
cli.cli_3,
 to_char(cli.date_fin_3  ,'DD/MM/YYYY')     date_fin_3,
cli.cli_4,
 to_char(cli.date_fin_4  ,'DD/MM/YYYY')    date_fin_4,
cli.cli_5,
 to_char(cli.date_fin_5  ,'DD/MM/YYYY')     date_fin_5,
cli.cli_6,
 to_char(cli.date_fin_6  ,'DD/MM/YYYY')     date_fin_6,
cli.cli_7,
 to_char(cli.date_fin_7  ,'DD/MM/YYYY')     date_fin_7,
cli.cli_8,
 to_char(cli.date_fin_8  ,'DD/MM/YYYY')     date_fin_8,
cli.cli_9,
 to_char(cli.date_fin_9  ,'DD/MM/YYYY')     date_fin_9,
cli.cli_10,
 to_char(cli.date_fin_10  ,'DD/MM/YYYY')     date_fin_10,
cli.cli_11,
 to_char(cli.date_fin_11  ,'DD/MM/YYYY')     date_fin_11,
cli.cli_12,
 to_char(cli.date_fin_12  ,'DD/MM/YYYY')    date_fin_12,
cli.cli_13,
 to_char(cli.date_fin_13  ,'DD/MM/YYYY')    date_fin_13,
cli.cli_14,
 to_char(cli.date_fin_14  ,'DD/MM/YYYY')    date_fin_14,
cli.cli_15,
 to_char(cli.date_fin_15  ,'DD/MM/YYYY')    date_fin_15,
cli.cli_16,
 to_char(cli.date_fin_16  ,'DD/MM/YYYY')    date_fin_16,
cli.cli_17,
 to_char(cli.date_fin_17  ,'DD/MM/YYYY')    date_fin_17,
cli.cli_18,
 to_char(cli.date_fin_18  ,'DD/MM/YYYY')    date_fin_18,
cli.cli_19,
 to_char(cli.date_fin_19  ,'DD/MM/YYYY')    date_fin_19,
cli.cli_20,
 to_char(cli.date_fin_20  ,'DD/MM/YYYY')     date_fin_20
from ref_piece_amortie r, 
lancement l, 
lancement_detail d, 
affaire a,
(select lancement, 
max((case when num_cli = 1 then code_client end)) as cli_1,
max((case when num_cli = 1 then date_fin end)) as date_fin_1,
max((case when num_cli = 2 then  code_client end)) as cli_2, 
max((case when num_cli = 2 then date_fin end)) as date_fin_2,
max((case when num_cli = 3 then  code_client end)) as cli_3,
max((case when num_cli = 3 then date_fin end)) as date_fin_3, 
max((case when num_cli = 4 then  code_client end)) as cli_4,
max((case when num_cli = 4 then date_fin end)) as date_fin_4, 
max((case when num_cli = 5 then  code_client end)) as cli_5,
max((case when num_cli = 5 then date_fin end)) as date_fin_5, 
max((case when num_cli = 6 then  code_client end)) as cli_6, 
max((case when num_cli = 6 then date_fin end)) as date_fin_6,
max((case when num_cli = 7 then  code_client end)) as cli_7, 
max((case when num_cli = 7 then date_fin end)) as date_fin_7,
max((case when num_cli = 8 then  code_client end)) as cli_8, 
max((case when num_cli = 8 then date_fin end)) as date_fin_8,
max((case when num_cli = 9 then  code_client end)) as cli_9, 
max((case when num_cli = 9 then date_fin end)) as date_fin_9,
max((case when num_cli = 10 then  code_client end)) as cli_10, 
max((case when num_cli = 10 then date_fin end)) as date_fin_10,
max((case when num_cli = 11 then  code_client end)) as cli_11,
max((case when num_cli = 11 then date_fin end)) as date_fin_11,
max((case when num_cli = 12 then  code_client end)) as cli_12, 
max((case when num_cli = 12 then date_fin end)) as date_fin_12,
max((case when num_cli = 13 then  code_client end)) as cli_13,
max((case when num_cli = 13 then date_fin end)) as date_fin_13,
max((case when num_cli = 14 then  code_client end)) as cli_14,
max((case when num_cli = 14 then date_fin end)) as date_fin_14, 
max((case when num_cli = 15 then  code_client end)) as cli_15,
max((case when num_cli = 15 then date_fin end)) as date_fin_15,
max((case when num_cli = 16 then  code_client end)) as cli_16,
max((case when num_cli = 16 then date_fin end)) as date_fin_16,
max((case when num_cli = 17 then  code_client end)) as cli_17,
max((case when num_cli = 17 then date_fin end)) as date_fin_17,
max((case when num_cli = 18 then  code_client end)) as cli_18,
max((case when num_cli = 18 then date_fin end)) as date_fin_18,
max((case when num_cli = 19 then  code_client end)) as cli_19, 
max((case when num_cli = 19 then date_fin end)) as date_fin_19,
max((case when num_cli = 20 then  code_client end)) as cli_20, 
max((case when num_cli = 20 then date_fin end)) as date_fin_20
from 
(select lancement,code_client,date_fin, 
row_number() over (partition by lancement order by lancement desc ) num_cli
from client_code_amo)
group by lancement) cli
where  r.lancement = l.id
and l.id = d.lancement
and d.date_debut  = (select max(d1.date_debut) from lancement_detail d1 where d.lancement = d1.lancement)
--and d.date_fin is null
and l.affaire = a.affaire
and l.fonction not in ('PPA','PPP')
and l.id = cli.lancement
and a.affaire like P_AFFAIRE || '%'
and nvl(a.otp,'NA') like P_OTP || '%'
and r.ref_piece like P_REF_PIECE || '%';


Wdata		  C_data%Rowtype;
WParam		  C_Param%Rowtype;
Wfile1 		  UTL_FILE.FILE_TYPE;
Wfile2 		  UTL_FILE.FILE_TYPE;
Wnbenr		  Number := 0;
Winstance	  Varchar2(30);
v_count         number:= 0;  
v_code_soc_tab   Varchar2(1000);
  

Begin
	 Open  C_instance;
	 Fetch C_instance into Winstance;
	 Close C_Instance;

	 Open  C_Param;
	 Fetch C_Param into WParam;
	 Close C_Param;

	 Wfile1 := BRB$FILE.Open_File(WParam.repertoire,'tps0201_' || P_Job || '.' || WParam.suffixe_dat);
	 Wfile2 := BRB$FILE.Open_File(WParam.repertoire,'tps0201_' || P_Job || '.' || WParam.suffixe_log);


     BRB$FILE.ADD_LINE(Wfile2,'***********************************************************');
	 BRB$FILE.ADD_LINE(Wfile2,'* Par AMO par référence client                            *');
	 BRB$FILE.ADD_LINE(Wfile2,'***********************************************************');

	 BRB$FILE.ADD_LINE(Wfile2,'Instance   : ' || Winstance);
	 BRB$FILE.ADD_LINE(Wfile2,'Commencé à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI'));

     BRB$FILE.ADD_DATA (Wfile1, 'Affaire'       	                ,0,';'                );
	 BRB$FILE.ADD_DATA (Wfile1, 'OTP'       	                    ,0,';'                );
	 BRB$FILE.ADD_DATA (Wfile1, 'Client'      	    	            ,0,';'            	  );
	 BRB$FILE.ADD_DATA (Wfile1, 'Ref. piece'      			        ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date debut ref'                    ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin ref'                      ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Lancement'                         ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Fonction'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Amo cache'                         ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Type gest.'                        ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date debut budget'                 ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin budget'                   ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Vente'                             ,0,';'                );    
	 BRB$FILE.ADD_DATA (Wfile1, 'Vente facturee'	                ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Vente amortie'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Quantite'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Part amo'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'SITE_EXP'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 1'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli1'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 2'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli2'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 3'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli3'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 4'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli4'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 5'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli5'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 6'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli6'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 7'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli7'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 8'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli8'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 9'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli9'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 10'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli10'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 11'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli11'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 12'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli12'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 13'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli13'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 14'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli14'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 15'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli15'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 16'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli16'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 17'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli17'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 18'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli18'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 19'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli19'                     ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Client 20'                          ,0,';'                );
     BRB$FILE.ADD_DATA (Wfile1, 'Date fin cli20'                     ,0,';','','N'         );

	 Open  C_data;		-- Traitement des données
	 LOOP
	 	Fetch C_data into Wdata;
	 	Exit when C_data%NotFound;
		BRB$FILE.ADD_DATA (Wfile1, Wdata.affaire 			 	 ,0,';'              );
		BRB$FILE.ADD_DATA (Wfile1, Wdata.otp        			 ,0,';'              );
		BRB$FILE.ADD_DATA (Wfile1, Wdata.client   				 ,0,';'            	 );
		BRB$FILE.ADD_DATA (Wfile1, Wdata.ref_piece  		     ,0,';'            	 );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_debut_ref          ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_ref            ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.lancement               ,0,';'              ); 
        BRB$FILE.ADD_DATA (Wfile1, Wdata.fonction                ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.amo_cache               ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.type_g                  ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_debut_lanc         ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_lanc           ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.bdg_vente               ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.bdg_vente_fact_out      ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.bdg_vente_amortie_out   ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.quantite                ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.part_amo                ,0,';'              );
       
            FOR element in c1_SITE(Wdata.lancement , Wdata.c_ref_piece)
             LOOP
                         if v_count = 0 then 
                             v_code_soc_tab := element.code_soc ;
                             v_count:= v_count +1 ;
                         else
                            v_code_soc_tab := v_code_soc_tab || '-' ||  element.code_soc  ;
                         END IF ;
             END LOOP;
             
            IF v_count = 0 THEN
                                FOR element in c2_SITE(Wdata.lancement)
                                 LOOP
                                             if v_count = 0 then 
                                                 v_code_soc_tab := 'Budget-'||element.code_soc ;
                                                 v_count:= v_count +1 ;
                                             else
                                                v_code_soc_tab := v_code_soc_tab || '-' ||  element.code_soc  ;
                                             END IF ;
                                 END LOOP;
             END IF ;
                               
        BRB$FILE.ADD_DATA (Wfile1,  v_code_soc_tab               ,0,';'              );      
         v_code_soc_tab:= ' ' ;     
         v_count := 0 ;            
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_1                   ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_1              ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_2                   ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_2              ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_3                   ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_3              ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_4                   ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_4              ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_5                   ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_5              ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_6                   ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_6              ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_7                   ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_7              ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_8                   ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_8              ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_9                   ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_9              ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_10                  ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_10             ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_11                  ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_11             ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_12                  ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_12             ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_13                  ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_13             ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_14                  ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_14             ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_15                  ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_15             ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_16                  ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_16             ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_17                  ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_17             ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_18                  ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_18             ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_19                  ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_19             ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.cli_20                  ,0,';'              );
        BRB$FILE.ADD_DATA (Wfile1, Wdata.date_fin_20             ,0,';','','N'       );  

	 END LOOP;
     Close C_data;

	 BRB$FILE.ADD_LINE(Wfile2,'Terminé  à : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI'));

	 BRB$FILE.ADD_LINE(Wfile2,'***********************************************************');
	 BRB$FILE.ADD_LINE(Wfile2,'* Fin Par AMO par référence client                        *');
	 BRB$FILE.ADD_LINE(Wfile2,'***********************************************************');


	 BRB$FILE.Close_File(Wfile1);
	 BRB$FILE.Close_File(Wfile2);



end;
/
